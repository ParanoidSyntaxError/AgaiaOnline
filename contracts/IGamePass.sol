// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface IGamePass {
    function setAdmin(address account) external;

    function setMinter(address account) external;

    function setDeveloper(address account) external;

    function mint(address receiver, uint256 id) external;

    function addTokenUri(string calldata uri) external;
}