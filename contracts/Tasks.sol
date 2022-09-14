// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVoting.sol";

contract Tasks {
    using Counters for Counters.Counter;
    Counters.Counter private _taskCount;

    address votingAddress;
    mapping (uint => Task) tasks;

    enum TaskStatus {
        Invalid, // default
        Proposed,
        NoParticipants,
        NotAccepted, // in voting
        Started,
        Failed,
        Completed
    }

    struct Task {
        address creator;
        address token;
        address rewardToken;
        uint rewardAmount;
        string details;
        TaskStatus status;
        uint32 votingDeadline;
        uint32 taskDeadline;
        uint32 quorum;
        uint32 supermajority;
        uint taskVoting;
        uint completionVoting;
        address[] participants;
    }

    event TaskCreated(uint256 taskId, address creator);
    event TaskVotingProcessed(uint256 taskId, TaskStatus status);
    event TaskCompletionVotingCreated(uint256 taskId, uint256 proposalId, address creator);
    event TaskCompletionProcessed(uint256 taskId, TaskStatus status);
    event ParticipatedInTask(uint256 taskId, address participant);
    event RewardDistributed(uint256 taskId, address participant, uint amount);

    constructor(address _votingAddress) {
        votingAddress = _votingAddress;
    }

    function getTask(uint taskId) public view returns (address creator, address token, address rewardToken, uint rewardAmount, string memory details, TaskStatus status, uint32 votingDeadline, uint32 taskDeadline, uint32 quorum, uint32 supermajority, address[] memory participants) {
        Task storage task = tasks[taskId];
        creator = task.creator;
        token = task.token;
        rewardToken = task.rewardToken;
        rewardAmount = task.rewardAmount;
        details = task.details;
        status = task.status;
        votingDeadline = task.votingDeadline;
        taskDeadline = task.taskDeadline;
        quorum = task.quorum;
        supermajority = task.supermajority;
        participants = task.participants;
    }

    function createTask(address _token, string memory _details, uint32 _votingDeadline, uint32 _taskDeadline, uint32 _quorum, uint32 _supermajority, address _rewardToken, uint _rewardAmount) public {
        require(IERC721Enumerable(_token).totalSupply() > 0, "invalid token");
        require(IERC721(_token).balanceOf(msg.sender) > 0, "not allowed");
        require(_votingDeadline > block.timestamp, "invalid voting deadline");
        require(_taskDeadline > _votingDeadline, "invalid task deadline");
        uint256 taskId = _taskCount.current();
        Task storage task = tasks[taskId];
        task.creator = msg.sender;
        task.token = _token;
        task.details = _details;
        task.votingDeadline = _votingDeadline;
        task.taskDeadline = _taskDeadline;
        task.quorum = _quorum;
        task.supermajority = _supermajority;
        task.rewardToken = _rewardToken;
        task.rewardAmount = _rewardAmount;
        task.status = TaskStatus.Proposed;
        uint proposalId = IVoting(votingAddress).createProposal(_token, _details, _votingDeadline, _quorum, _supermajority);
        task.taskVoting = proposalId;

        IERC20(_rewardToken).transferFrom(msg.sender, address(this), _rewardAmount);

        emit TaskCreated(taskId, msg.sender);
    }

    function participate(uint taskId) public {
        require(taskId < _taskCount.current(), "invalid task");
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Proposed, "cannot participate");
        require(task.votingDeadline > block.timestamp, "participation deadline passed");
        require(!isParticipant(taskId, msg.sender), "already participated");
        task.participants.push(msg.sender);

        emit ParticipatedInTask(taskId, msg.sender);
    }

    function isParticipant(uint taskId, address member) public view returns (bool) {
        Task storage task = tasks[taskId];
        for(uint i=0; i < task.participants.length; i ++) {
            if(task.participants[i] == member) {
                return true;
            }
        }
        return false;
    }

    function processTaskVoting(uint taskId) public {
        require(taskId < _taskCount.current(), "invalid task");
        Task storage task = tasks[taskId];
        require(task.creator == msg.sender, "not allowed");
        require(task.votingDeadline < block.timestamp, "voting deadline not passed");
        if(task.participants.length > 0) {
            uint votingResult = IVoting(votingAddress).calculateVoteResult(task.taskVoting);
            if(votingResult == 2) {
                task.status = TaskStatus.Started;
            } else {
                task.status = TaskStatus.NotAccepted;
                refundRewardAmount(task);
            }
        } else {
            task.status = TaskStatus.NoParticipants;
            refundRewardAmount(task);
        }

        emit TaskVotingProcessed(taskId, task.status);
    }

    function createTaskCompletionVoting(uint taskId) public {
        require(taskId < _taskCount.current(), "invalid task");
        Task storage task = tasks[taskId];
        require(task.creator == msg.sender, "not allowed");
        require(task.taskDeadline < block.timestamp, "task deadline not passed");
        string memory details = string(
            abi.encodePacked("Task completion voting for following details. ", task.details)
        );
        uint proposalId = IVoting(votingAddress).createProposal(task.token, details, task.taskDeadline + 604800, task.quorum, task.supermajority);
        task.completionVoting = proposalId;

        emit TaskCompletionVotingCreated(taskId, proposalId, msg.sender);
    }

    function processTaskCompletion(uint taskId) public {
        require(taskId < _taskCount.current(), "invalid task");
        Task storage task = tasks[taskId];
        require(task.creator == msg.sender, "not allowed");
        require((task.taskDeadline + 604800) < block.timestamp, "task completion voting deadline not passed");
        uint votingResult = IVoting(votingAddress).calculateVoteResult(task.completionVoting);
        if(votingResult == 2) {
            task.status = TaskStatus.Completed;
            ditributeRewards(taskId, task.participants, task.rewardToken, task.rewardAmount);
        } else {
            task.status = TaskStatus.Failed;
            refundRewardAmount(task);
        }

        emit TaskCompletionProcessed(taskId, task.status);
    }

    function ditributeRewards(uint taskId, address[] memory participants, address rewardToken, uint rewardAmount) private {
        if(participants.length > 0) {
            uint amount = rewardAmount / participants.length;
            for(uint i=0; i<participants.length; i++) {
                IERC20(rewardToken).transfer(participants[i], amount);
                emit RewardDistributed(taskId, participants[i], amount);
            }
        }
    }

    function refundRewardAmount(Task storage task) private {
        IERC20(task.rewardToken).transfer(task.creator, task.rewardAmount);
    }
}