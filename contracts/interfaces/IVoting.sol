// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IVoting {
    function createProposal(address _token, string memory _details, uint32 _votingDeadline, uint32 _quorum, uint32 _supermajority) external returns (uint256);
    function calculateVoteResult(uint proposalId) external returns (uint);
}