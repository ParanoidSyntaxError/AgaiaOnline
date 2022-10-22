// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface CardsInterface {
    function totalBalance(address account) external view returns (uint256);
}