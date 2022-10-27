// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/CharactersInterface.sol";
import "./interfaces/RandomManagerInterface.sol";
import "./interfaces/RandomRequestorInterface.sol";

contract Game is RandomRequestorInterface {
    struct Dungeon {
        uint256[5] probabilities;
        uint256[] items;
        uint256[] enemies;
        uint256[] traps;
    }

    // Chunk ID => Character IDs
    mapping(uint256 => uint256[]) internal _chunkCharacters;
    uint256 internal constant _chunkDuration = 15;
    uint256 internal constant _vrfConfirmations = 5;

    // Character ID => Item IDs
    mapping(uint256 => uint256[]) internal _inventories;
    // Character ID => Request ID
    mapping(uint256 => uint256) internal _requestIds;

    CharactersInterface public immutable characters;

    RandomManagerInterface public immutable randomManager;

    constructor(address charactersContract, address randomManagerContract) {
        characters = CharactersInterface(charactersContract);
        randomManager = RandomManagerInterface(randomManagerContract);
    }

    function randomCount(uint256 /*dataType*/) external pure override returns (uint32) {
        return 0;
    }

    function onRequestRandom(address sender, uint256 requestId, uint256 /*dataType*/, bytes memory data) external override {
        (uint256 characterId, uint256[] memory itemIds) = abi.decode(data, (uint256, uint256[]));
        require(_requestIds[characterId] == 0);     

        // Check character is owned
        // Check character is not paused
        // Check items are owned
        // Check items are not paused

        uint256 chunkId = _getChunkId(block.number);

        _chunkCharacters[chunkId].push(characterId);
        _inventories[characterId] = itemIds;
        _requestIds[characterId] = requestId;
    }

    function claim() external {
        
    }

    function _getChunkId(uint256 blockNumber) internal pure returns (uint256) {
        return blockNumber / _chunkDuration;
    }

    function _getBlockNumber(uint256 chunkId) internal pure returns (uint256) {
        return chunkId * _chunkDuration;
    }
}