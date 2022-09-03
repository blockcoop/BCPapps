// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Coop.sol";

contract CoopFactory {
    address tokenURIAddress;
    address subCoopFactoryAddress;
    Coop private coop;
    mapping(string => bool) existingSymbols;
    address[] public coops;
    mapping (address => address[]) intiatorCoops;

    event CoopCreated(address indexed initiator, address coopAddress);

    constructor(address _tokenURIAddress, address _subCoopFactoryAddress) {
        tokenURIAddress = _tokenURIAddress;
        subCoopFactoryAddress = _subCoopFactoryAddress;
    }

    function createCoop(string memory _name, string memory _symbol, uint _membershipFee, string memory _country, uint32 _quorum, uint32 _supermajority) public {
        require(existingSymbols[_symbol] == false, "duplicate symbol");
        existingSymbols[_symbol] = true;
        coop = new Coop(_name, _symbol, tokenURIAddress, subCoopFactoryAddress, msg.sender, _membershipFee, _country, _quorum, _supermajority);
        coops.push(address(coop));
        intiatorCoops[msg.sender].push(address(coop));
        emit CoopCreated(msg.sender, address(coop));
    }

    function isValidCoop(address coopAddress) public view returns (bool) {
        for (uint i = 0; i < coops.length; i++) {
            if (coops[i] == coopAddress) {
                return true;
            }
        }
        return false;
    }
}