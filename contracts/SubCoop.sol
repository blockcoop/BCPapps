// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/ITokenURI.sol";

contract SubCoop is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address coopAddress;

    event SubCoopJoined(address member);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        coopAddress = msg.sender;
    }

    function MintNFT(address member, string memory tokenURI)
        public
        returns (uint256)
    {
        uint256 newItemId = _tokenIds.current();
        _mint(member, newItemId);
        _setTokenURI(newItemId, tokenURI);

        _tokenIds.increment();
        return newItemId;
    }

    function joinSubCoop() public {
        require(balanceOf(msg.sender) == 0, "already a member");
        MintNFT(msg.sender, "Member");
        emit SubCoopJoined(msg.sender);
    }
}