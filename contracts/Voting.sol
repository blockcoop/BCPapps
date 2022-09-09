// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Voting {
    using Counters for Counters.Counter;
    Counters.Counter private _proposalCount;

    mapping (uint => Proposal) proposals;

    event ProposalCreated(uint256 proposalId, address creator, address token);
    event Voted(uint256 proposalId, address member);
    event VoteResultCalculated(uint256 proposalId);

    enum Vote {
        Null,
        Yes,
        No
    }

    enum ProposalStatus {
        Invalid,
        Proposed,
        Passed,
        Failed,
        Cancelled
    }

    struct Proposal {
        address creator;
        address token;
        string details;
        uint32 votingDeadline;
        uint32 quorum; // 1-100
        uint32 supermajority;
        uint yesVotes;
        uint noVotes;
        mapping (address => Vote) votes;
        ProposalStatus status;
    }

    function getProposal(uint proposalId) public view returns (address creator, address token, string memory details, uint32 votingDeadline, uint32 quorum, uint32 supermajority, uint yesVotes, uint NoVotes, ProposalStatus status) {
        Proposal storage proposal = proposals[proposalId];
        creator = proposal.creator;
        token = proposal.token;
        details = proposal.details;
        votingDeadline = proposal.votingDeadline;
        quorum = proposal.quorum;
        supermajority = proposal.supermajority;
        yesVotes = proposal.yesVotes;
        NoVotes = proposal.noVotes;
        status = proposal.status;
    }

    function calculateVoteResult(uint proposalId) private returns (ProposalStatus) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.votingDeadline < block.timestamp, "voting deadline not passed");
        uint memberCount = IERC721Enumerable(proposal.token).totalSupply();
        uint minVotes = memberCount * proposal.quorum;

        if((proposal.yesVotes + proposal.noVotes) * 100 > minVotes) {
            uint minYesVotes = (proposal.yesVotes + proposal.noVotes) * proposal.supermajority / 100;
            if(proposal.yesVotes >= minYesVotes) {
                proposal.status = ProposalStatus.Passed;
            } else {
                proposal.status = ProposalStatus.Failed;
            }
        } else {
            proposal.status = ProposalStatus.Cancelled;
        }

        emit VoteResultCalculated(proposalId);
        return proposal.status;
    }

    function createProposal(address _token, string memory _details, uint32 _votingDeadline, uint32 _quorum, uint32 _supermajority) public returns (uint256) {
        require(IERC721(_token).balanceOf(msg.sender) > 0, "not allowed");
        require(_votingDeadline > block.timestamp, "invalid voting deadline");
        uint256 proposalId = _proposalCount.current();
        Proposal storage proposal = proposals[proposalId];
        proposal.creator = msg.sender;
        proposal.token = _token;
        proposal.details = _details;
        proposal.votingDeadline = _votingDeadline;
        proposal.quorum = _quorum;
        proposal.supermajority = _supermajority;
        proposal.status = ProposalStatus.Proposed;
        emit ProposalCreated(proposalId, msg.sender, _token);
        return proposalId;
    }

    function vote(uint _proposalId, bool _vote) public {
        Proposal storage proposal = proposals[_proposalId];
        require(IERC721(proposal.token).balanceOf(msg.sender) > 0, "not allowed");
        require(proposal.status == ProposalStatus.Proposed, "invalid proposal status");
        require(proposal.votes[msg.sender] == Vote.Null, "already voted");
        require(proposal.votingDeadline >= block.timestamp, "voting closed");

        if(_vote) {
            proposal.votes[msg.sender] = Vote.Yes;
            proposal.yesVotes = proposal.yesVotes + 1;
        } else {
            proposal.votes[msg.sender] = Vote.No;
            proposal.noVotes = proposal.noVotes + 1;
        }
        emit Voted(_proposalId, msg.sender);
    }
}