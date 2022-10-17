// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRandomRequestor {
    function randomCount(uint256 dataType) external returns (uint32 randomCount);
    function onRequestRandom(address sender, uint256 requestId, uint256 dataType, bytes memory data) external;
}