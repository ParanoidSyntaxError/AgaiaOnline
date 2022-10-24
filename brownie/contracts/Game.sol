// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./RandomManagerInterface.sol";
import "./RandomRequestorInterface.sol";

contract Game is RandomRequestorInterface {
    RandomManagerInterface public immutable randomManager;

    constructor(address randomManagerContract) {
        randomManager = RandomManagerInterface(randomManagerContract);
    }

    function randomCount(uint256 /*dataType*/) external pure override returns (uint32) {
        return 0;
    }

    function onRequestRandom(address /*sender*/, uint256 requestId, uint256 /*dataType*/, bytes memory data) external override {
        
    }
}