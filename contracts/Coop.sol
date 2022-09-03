// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/ISubCoopFactory.sol";
import "./interfaces/ITokenURI.sol";

contract Coop is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address tokenURIAddress;
    address subCoopFactoryAddress;
    address public coopInitiator;
    uint public membershipFee;
    string public country;
    uint32 public quorum; // 1-100
    uint32 public supermajority;
    address[] public subCoops;

    event CoopJoined(address indexed member);

    constructor(string memory _name, string memory _symbol, address _tokenURIAddress, address _subCoopFactoryAddress, address _coopInitiator, uint _membershipFee, string memory _country, uint32 _quorum, uint32 _supermajority) ERC721(_name, _symbol) {
        tokenURIAddress = _tokenURIAddress;
        subCoopFactoryAddress = _subCoopFactoryAddress;
        coopInitiator = _coopInitiator;
        membershipFee = _membershipFee;
        country = _country;
        quorum = _quorum;
        supermajority = _supermajority;

        string memory tokenURI = ITokenURI(_tokenURIAddress).create(_name, "Creator");
        MintNFT(_coopInitiator, tokenURI);
    }

    function MintNFT(address member, string memory tokenURI)
        public
        returns (uint256)
    {
        uint256 newTokenId = _tokenIds.current();
        _mint(member, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        _tokenIds.increment();
        return newTokenId;
    }

    function joinCoop() public payable {
        require(balanceOf(msg.sender) == 0, "already a member");
        require(msg.value == membershipFee, "invalid membership fee");
        MintNFT(msg.sender, "Member");
        emit CoopJoined(msg.sender);
    }

    function createSubCoop(string memory _name) public {
        ISubCoopFactory(subCoopFactoryAddress).createSubCoop(_name);
    }
}