// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface PortraitsInterface {   
    function totalSupply() external view returns (uint256);
    function claimMint() external returns (uint256);
}