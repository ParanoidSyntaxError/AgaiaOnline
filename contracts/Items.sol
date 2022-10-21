// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ItemsInterface.sol";
import "./StringHelper.sol";

contract Items is ItemsInterface, ERC1155, Ownable {
    constructor() ERC1155("") {

    }

    function uri(uint256 /*id*/) public view virtual override returns (string memory) {
        return "";
    }
}