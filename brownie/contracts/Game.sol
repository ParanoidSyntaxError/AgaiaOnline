// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./interfaces/CharactersInterface.sol";
import "./interfaces/ItemsInterface.sol";
import "./interfaces/RandomManagerInterface.sol";
import "./interfaces/RandomRequestorInterface.sol";

// TODO: Add ERC1155 receiver inheritance

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
    IERC721 internal immutable _charactersErc721;

    ItemsInterface public immutable items;
    IERC1155 internal immutable _itemsErc1155;

    RandomManagerInterface public immutable randomManager;

    constructor(address charactersContract, address itemsContract, address randomManagerContract) {
        characters = CharactersInterface(charactersContract);
        _charactersErc721 = IERC721(charactersContract);

        items = ItemsInterface(itemsContract);
        _itemsErc1155 = IERC1155(itemsContract);

        randomManager = RandomManagerInterface(randomManagerContract);
    }

    function randomCount(uint256 /*dataType*/) external pure override returns (uint32) {
        return 0;
    }

    function onRequestRandom(address sender, uint256 requestId, uint256 /*dataType*/, bytes memory data) external override {
        (uint256 characterId, uint256[] memory itemIds, uint256[] memory itemAmounts) = abi.decode(data, (uint256, uint256[], uint256[]));
        require(_requestIds[characterId] == 0);     

        require(_charactersErc721.ownerOf(characterId) == sender);
        characters.adminTransfer(sender, address(this), characterId);

        // TODO: Check item can be stacked
        require(itemIds.length == itemAmounts.length);
        for(uint256 i = 0; i < itemIds.length; i++) {
            require(_itemsErc1155.balanceOf(sender, itemIds[i]) >= itemAmounts[i]);
            items.adminTransfer(sender, address(this), itemIds[i], itemAmounts[i]);
        }

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