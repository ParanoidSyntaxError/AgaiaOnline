// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/CharactersInterface.sol";
import "./interfaces/ItemsInterface.sol";
import "./interfaces/RandomManagerInterface.sol";
import "./interfaces/RandomRequestorInterface.sol";
import "./interfaces/ActionsInterface.sol";

import "./Cards.sol";
import "./Characters.sol";
import "./Items.sol";

import "./DataLibrary.sol";

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
        uint256[5] encounterChances;
        uint256[5][] chances;
        uint256[5][] ids;
        uint32 randomCount;
    }

    struct Request {
        uint256 requestId;
        uint256 chunkId;
        uint256 dungeonId;
        uint256[] itemIds;
        uint256[] itemAmounts;
    }

    struct Enemy {
        DataLibrary.Actor actor;
        uint256[] chances;
        Action[] actions;
    }

    struct Action {
        uint256[] contractIds;
        uint256[] actionIds;
        bytes[] actionData;
        bool[] self;
    }

    // Chunk ID => Dungeon ID => Character IDs
    mapping(uint256 => mapping(uint256 => uint256[])) internal _chunkCharacters;
    uint256 internal constant _chunkDuration = 15;
    uint256 internal constant _vrfConfirmations = 5;

    mapping(uint256 => bool) internal _requestLocked;
    mapping(uint256 => Request) internal _requests;

    CharactersInterface public immutable characters;
    ItemsInterface public immutable items;

    uint256[7] internal _equipTypeMaxes;

    RandomManagerInterface public immutable randomManager;

    mapping(uint256 => ActionsInterface) internal _actions;
    uint256 internal _totalActions;

    mapping(uint256 => Dungeon) internal _dungeons;

    mapping(uint256 => Action) internal _traps;

    mapping(uint256 => Enemy) internal _enemies;

    uint256 internal constant _probabilitiesMax = 100000;

    constructor(address randomManagerContract) {
        characters = CharactersInterface(new Characters(address(this), address(0), randomManagerContract));
        items = ItemsInterface(new Items());

        randomManager = RandomManagerInterface(randomManagerContract);

        _equipTypeMaxes[uint256(EquipType.HEAD)] = 1;
        _equipTypeMaxes[uint256(EquipType.CHEST)] = 1;
        _equipTypeMaxes[uint256(EquipType.HAND)] = 2;
        _equipTypeMaxes[uint256(EquipType.RING)] = 2;
        _equipTypeMaxes[uint256(EquipType.NECKLACE)] = 1;
        _equipTypeMaxes[uint256(EquipType.TRINKET)] = 2; 
        _equipTypeMaxes[uint256(EquipType.BAG)] = 10;
    }

    function randomCount(uint256 dataType) external view override returns (uint32) {
        return _dungeons[dataType].randomCount;
    }

    function onRequestRandom(address sender, uint256 requestId, uint256 dataType, bytes memory data) external override {
        (uint256 characterId, uint256[] memory itemIds, uint256[] memory itemAmounts) = abi.decode(data, (uint256, uint256[], uint256[]));
        require(_requestLocked[characterId] == false);     

        require(characters.ownerOf(characterId) == sender);
        characters.transferFrom(sender, address(this), characterId);

        require(itemIds.length == itemAmounts.length);

        uint256[7] memory equipLoad = _equipTypeMaxes;

        for(uint256 i = 0; i < itemIds.length; i++) {
            require(items.balanceOf(sender, itemIds[i]) >= itemAmounts[i]);
           
            // If equip type exceeds max, reverts
            (,uint256 equipType) = items.getItem(itemIds[i]);
            equipLoad[equipType] -= itemAmounts[i];
        }

        items.safeBatchTransferFrom(sender, address(this), itemIds, itemAmounts, "");

        uint256 chunkId = _getChunkId(block.number);

        _chunkCharacters[chunkId][dataType].push(characterId);
        _requests[characterId] = Request(requestId, chunkId, dataType, itemIds, itemAmounts);
        _requestLocked[characterId] = true;
    }

    function claim(uint256 characterId) external {
        require(_requestLocked[characterId] == true);     
        require(randomManager.requestResponded(_requests[characterId].requestId));

        uint256 dungeonId = _requests[characterId].dungeonId;

        uint256[] memory responses = randomManager.randomResponse(_requests[characterId].requestId);

        DataLibrary.Actor memory character = characters.getCharacter(characterId);

        for(uint256 i = 0; i < responses.length; i++) {
            // TODO: USE ITEMS

            uint256 encounter = responses[i] % _probabilitiesMax;
            uint256 probabilityIncrement;
            for(uint256 j = 0; j < _dungeons[dungeonId].encounterChances.length; j++) {
                probabilityIncrement += _dungeons[dungeonId].encounterChances[j];
                if(encounter < probabilityIncrement) {
                    encounter = j;
                    break;
                }
            }

            uint256 id = _expandRandom(responses[i], 0, 1)[0] % _probabilitiesMax;
            probabilityIncrement = 0;
            for(uint256 j = 0; j < _dungeons[dungeonId].chances[encounter].length; j++) {
                probabilityIncrement += _dungeons[dungeonId].chances[encounter][j];
                if(id < probabilityIncrement) {
                    id = _dungeons[dungeonId].ids[encounter][j];
                    break;
                }
            }
            
            if(encounter == 0) {
                // ITEM
                items.mint(id, address(this), 1);
                _requests[characterId].itemIds.push(id);
                _requests[characterId].itemAmounts.push(1);
            } else if (encounter == 1) {
                // TRAP
                character = _trap(id, character);
            } else if (encounter == 2) {
                // ENEMY
            } else if (encounter == 3) {
                // INVASION
            } else if (encounter == 4) {
                // NONE
            }

            if(character.health == 0) {
                // TODO: DEATH
                break;
            }
        }

        _requestLocked[characterId] = false;
    }

    function _enemy(uint256 enemyId, DataLibrary.Actor memory character) internal view returns (DataLibrary.Actor memory) {
        Enemy memory enemy = _enemies[enemyId];
        
        for(uint256 i = 0; i < 10; i ++) {
            // TODO: Check initiative values

            // Player


            // Enemy
            for(uint256 j = 0; j < enemy.actions[0].contractIds.length; j++) {
                if(enemy.actions[0].self[j]) {
                    enemy.actor = _performAction(enemy.actions[0].contractIds[j], enemy.actions[0].actionIds[j], enemy.actor, enemy.actions[0].actionData[j]);
                } else {
                    character = _performAction(enemy.actions[0].contractIds[j], enemy.actions[0].actionIds[j], character, enemy.actions[0].actionData[j]);
                }
            }
        }

        return character;
    }

    function _trap(uint256 trapId, DataLibrary.Actor memory character) internal view returns (DataLibrary.Actor memory) {
        for(uint256 i = 0; i < _traps[trapId].contractIds.length; i++) {
            character = _performAction(_traps[trapId].contractIds[i], _traps[trapId].actionIds[i], character, _traps[trapId].actionData[i]);
        }
        return character;
    }

    function _performAction(uint256 contractId, uint256 actionId, DataLibrary.Actor memory character, bytes memory data) internal view returns (DataLibrary.Actor memory) {
        return _actions[contractId].perform(actionId, character, data);
    }

    function _expandRandom(uint256 seed, uint256 offset, uint256 n) public pure returns (uint256[] memory) {
        uint256[] memory randoms = new uint256[](n);

        for (uint256 i = 0; i < n; i++) {
            randoms[i] = uint256(keccak256(abi.encode(seed, i + offset)));
        }

        return randoms;
    }

    function _getChunkId(uint256 blockNumber) internal pure returns (uint256) {
        return blockNumber / _chunkDuration;
    }

    function _getBlockNumber(uint256 chunkId) internal pure returns (uint256) {
        return chunkId * _chunkDuration;
    }
}