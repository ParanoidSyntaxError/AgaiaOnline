// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/CharactersInterface.sol";
import "./interfaces/ItemsInterface.sol";
import "./interfaces/RandomManagerInterface.sol";
import "./interfaces/RandomRequestorInterface.sol";

contract Game is RandomRequestorInterface, ERC1155Holder {
    enum EquipType {
        HEAD,
        CHEST,
        HAND,
        RING,
        NECKLACE,
        TRINKET,
        BAG
    }
    
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

    ItemsInterface public immutable items;

    uint256[7] internal _equipTypeMaxes;

    RandomManagerInterface public immutable randomManager;

    constructor(address charactersContract, address itemsContract, address randomManagerContract) {
        characters = CharactersInterface(charactersContract);

        items = ItemsInterface(itemsContract);

        randomManager = RandomManagerInterface(randomManagerContract);

        _equipTypeMaxes[uint256(EquipType.HEAD)] = 1;
        _equipTypeMaxes[uint256(EquipType.CHEST)] = 1;
        _equipTypeMaxes[uint256(EquipType.HAND)] = 2;
        _equipTypeMaxes[uint256(EquipType.RING)] = 2;
        _equipTypeMaxes[uint256(EquipType.NECKLACE)] = 1;
        _equipTypeMaxes[uint256(EquipType.TRINKET)] = 2; 
        _equipTypeMaxes[uint256(EquipType.BAG)] = 10;
    }

    function randomCount(uint256 /*dataType*/) external pure override returns (uint32) {
        return 0;
    }

    function onRequestRandom(address sender, uint256 requestId, uint256 /*dataType*/, bytes memory data) external override {
        (uint256 characterId, uint256[] memory itemIds, uint256[] memory itemAmounts) = abi.decode(data, (uint256, uint256[], uint256[]));
        require(_requestIds[characterId] == 0);     

        require(characters.ownerOf(characterId) == sender);
        characters.adminTransfer(sender, address(this), characterId);

        require(itemIds.length == itemAmounts.length);

        uint256[7] memory equipLoad = _equipTypeMaxes;

        for(uint256 i = 0; i < itemIds.length; i++) {
            require(items.balanceOf(sender, itemIds[i]) >= itemAmounts[i]);

            items.adminTransfer(sender, address(this), itemIds[i], itemAmounts[i]);
            
            (,uint256 equipType) = items.getItem(itemIds[i]);
            // If equip load type exceeds max, reverts
            equipLoad[equipType] -= itemAmounts[i];
        }

        uint256 chunkId = _getChunkId(block.number);

        _chunkCharacters[chunkId].push(characterId);
        _inventories[characterId] = itemIds;
        _requestIds[characterId] = requestId;
    }

    function claim() external {
        // Use VRF response
    }

    function _getChunkId(uint256 blockNumber) internal pure returns (uint256) {
        return blockNumber / _chunkDuration;
    }

    function _getBlockNumber(uint256 chunkId) internal pure returns (uint256) {
        return chunkId * _chunkDuration;
    }
}