// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ICoopFactory {
    function isValidCoop(address) external view returns (bool);
}