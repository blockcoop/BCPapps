// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./SubCoop.sol";

contract SubCoopFactory {
    mapping(address => address[]) subCoops;

    event SubCoopCreated(address indexed subCoopAddress);

    function createSubCoop(string memory _name) public {
        string memory coopSymbol = IERC721Metadata(msg.sender).symbol();
        string memory symbol = string(
            abi.encodePacked(coopSymbol, subCoops[msg.sender].length + 1)
        );
        SubCoop subCoop = new SubCoop(_name, symbol);
        subCoops[msg.sender].push(address(subCoop));
    }

    function getSubCoops(address coop) public view returns(address[] memory) {
        return subCoops[coop];
    }
}