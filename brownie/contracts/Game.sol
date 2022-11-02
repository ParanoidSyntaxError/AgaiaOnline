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
import "./RandomHelper.sol";

contract Game is RandomRequestorInterface, ERC1155Holder {   
    enum EncounterType {
        ITEM,
        TRAP,
        ENEMY,
        INVASION,
        NONE
    }

    struct Dungeon {
        uint256[5] encounterChances;
        uint256[][5] chances;
        uint256[][5] ids;
        uint32 randomCount;
    }

    struct Request {
        uint256 requestId;
        uint256 chunkId;
        uint256 dungeonId;
        uint256[][7] itemIds;
        uint256[][7] itemAmounts;
        address owner;
    }

    struct Enemy {
        DataLibrary.Actor actor;
        uint256[] chances;
        DataLibrary.Move[] moves;
    }

    event Raid(uint256 indexed characterId, address indexed owner, uint256[] eventLog);

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

    mapping(uint256 => DataLibrary.Move) internal _traps;

    mapping(uint256 => Enemy) internal _enemies;

    uint256 internal constant _probabilitiesMax = 100000;

    constructor(address randomManagerContract) {
        characters = CharactersInterface(new Characters(address(this), address(0), randomManagerContract));
        items = ItemsInterface(new Items());

        randomManager = RandomManagerInterface(randomManagerContract);

        _equipTypeMaxes[uint256(DataLibrary.EquipType.HEAD)] = 1;
        _equipTypeMaxes[uint256(DataLibrary.EquipType.CHEST)] = 1;
        _equipTypeMaxes[uint256(DataLibrary.EquipType.HAND)] = 1;
        _equipTypeMaxes[uint256(DataLibrary.EquipType.RING)] = 2;
        _equipTypeMaxes[uint256(DataLibrary.EquipType.NECKLACE)] = 1;
        _equipTypeMaxes[uint256(DataLibrary.EquipType.TRINKET)] = 2; 
        _equipTypeMaxes[uint256(DataLibrary.EquipType.BAG)] = 10;
    }

    function randomCount(uint256 dataType) external view override returns (uint32) {
        return _dungeons[dataType].randomCount;
    }

    function onRequestRandom(address sender, uint256 requestId, uint256 dataType, bytes memory data) external override {
        (uint256 characterId, uint256[][7] memory itemIds, uint256[][7] memory itemAmounts) = abi.decode(data, (uint256, uint256[][7], uint256[][7]));
        require(_requestLocked[characterId] == false);     

        require(characters.ownerOf(characterId) == sender);
        characters.transferFrom(sender, address(this), characterId);

        uint256 batchLength;
        uint256[7] memory equipLoad = _equipTypeMaxes;

        for(uint256 i = 0; i < itemIds.length; i++) {
            require(itemIds[i].length == itemAmounts[i].length);
            for(uint256 j = 0; i < itemIds[i].length; j++) {
                require(itemAmounts[i][j] > 0);
                if(i != itemIds.length - 1) {
                    require(i == items.getItem(itemIds[i][j]).equipType);
                }
                equipLoad[i] -= itemAmounts[i][j];
                batchLength++;
            }
        }

        (uint256[] memory transferIds, uint256[] memory transferAmounts) = _batchItemIds(itemIds, itemAmounts, batchLength);

        items.safeBatchTransferFrom(sender, address(this), transferIds, transferAmounts, "");

        uint256 chunkId = _getChunkId(block.number);

        _chunkCharacters[chunkId][dataType].push(characterId);
        _requests[characterId] = Request(requestId, chunkId, dataType, itemIds, itemAmounts, sender);
        _requestLocked[characterId] = true;
    }

    function claim(uint256 characterId) external {
        require(_requestLocked[characterId] == true);     
        require(randomManager.requestResponded(_requests[characterId].requestId));

        uint256[] memory responses = randomManager.randomResponse(_requests[characterId].requestId);

        DataLibrary.Actor memory character = characters.getCharacter(characterId);

        uint256[] memory eventLog = new uint256[](responses.length);
        uint256 eventLogIndex;

        for(uint256 i = 0; i < responses.length; i++) {
            (uint256 encounter, uint256 id) = _rollEncounter(responses[i], _requests[characterId].dungeonId);
            
            eventLog[eventLogIndex] = (encounter + 1) * (10 ** 16);
            if(encounter != uint256(EncounterType.NONE)) {
                eventLog[eventLogIndex] += id + (10 ** 12);      
            }
            eventLog[eventLogIndex] += character.health + (10 ** 8);

            if(encounter == uint256(EncounterType.ITEM)) {
                // ITEM
                items.mint(id, address(this), 1);
                _requests[characterId].itemIds[uint256(DataLibrary.EquipType.BAG)].push(id);
                _requests[characterId].itemAmounts[uint256(DataLibrary.EquipType.BAG)].push(1);
            } else if (encounter == uint256(EncounterType.TRAP)) {
                // TRAP
                character = _trap(RandomHelper.expand(responses[i], 3), id, character);
            } else if (encounter == uint256(EncounterType.ENEMY)) {
                // ENEMY
                uint256 result; // Stupid fucking compiler
                (character, result) = _enemy(EnemyData(RandomHelper.expand(responses[i], 3), id, characterId, _requests[characterId].itemIds[uint256(DataLibrary.EquipType.HAND)][0]));
                eventLog[eventLogIndex] += result;
            } else if (encounter == uint256(EncounterType.INVASION)) {
                // INVASION
                // TODO
            } else {
                // NONE
            }

            eventLog[eventLogIndex] += character.health + (10 ** 4);

            eventLogIndex++;

            if(character.health == 0) {
                // DEATH
                eventLog[eventLogIndex] = 777;
                break;
            }
        }

        if(character.health > 0) {
            uint256 batchLength = _itemBatchLength(_requests[characterId].itemIds);
            (uint256[] memory transferIds, uint256[] memory transferAmounts) = _batchItemIds(_requests[characterId].itemIds, _requests[characterId].itemAmounts, batchLength);
            items.safeBatchTransferFrom(address(this), _requests[characterId].owner, transferIds, transferAmounts, "");
            characters.transferFrom(address(this), _requests[characterId].owner, characterId);
        }

        _requestLocked[characterId] = false;

        emit Raid(characterId, _requests[characterId].owner, eventLog);
    }

    function _rollEncounter(uint256 seed, uint256 dungeonId) internal view returns (uint256, uint256) {
        uint256 encounter = seed % _probabilitiesMax;
        uint256 probabilityIncrement;
        for(uint256 j = 0; j < _dungeons[dungeonId].encounterChances.length; j++) {
            probabilityIncrement += _dungeons[dungeonId].encounterChances[j];
            if(encounter < probabilityIncrement) {
                encounter = j;
                break;
            }
        }
        uint256 id = RandomHelper.expand(seed, 1) % _probabilitiesMax;
        probabilityIncrement = 0;
        for(uint256 j = 0; j < _dungeons[dungeonId].chances[encounter].length; j++) {
            probabilityIncrement += _dungeons[dungeonId].chances[encounter][j];
            if(id < probabilityIncrement) {
                id = _dungeons[dungeonId].ids[encounter][j];
                break;
            }
        }

        return (encounter, id);
    }

    struct EnemyData {
        uint256 seed;
        uint256 enemyId;
        uint256 characterId;
        uint256 equippedItemId;
    }

    function _enemy(EnemyData memory data) internal view returns (DataLibrary.Actor memory, uint256) {        
        uint256 randNonce = 1;

        DataLibrary.Actor memory character = characters.getCharacter(data.characterId);
        Enemy memory enemy = _enemies[data.enemyId];

        for(uint256 i = 0; i < 10; i ++) {
            bool playerFirst;
            if(StatsLibrary.calculateInitiative(character.stats) == StatsLibrary.calculateInitiative(enemy.actor.stats)) {
                if(data.seed % 2 == 0) {
                    playerFirst = true;
                }
                randNonce++;
            } else if(StatsLibrary.calculateInitiative(character.stats) > StatsLibrary.calculateInitiative(enemy.actor.stats)) {
                playerFirst = true;
            }

            for(uint256 m = 0; m < 2; m++) {
                if(playerFirst) {
                    (character, enemy.actor) = _performMove(data.seed, character, enemy.actor, items.getItem(data.equippedItemId).move);
                } else {
                    (enemy.actor, character) = _performMove(data.seed, enemy.actor, character, enemy.moves[data.seed % enemy.moves.length]);
                }

                if(character.health == 0) {
                    // Death
                    return (character, 7);
                } else if (enemy.actor.health == 0) {
                    // Killed enemy
                    return (character, 1);
                }

                playerFirst = !playerFirst;
            }
        }

        // Flee
        return (character, 3);
    }

    function _performMove(uint256 seed, DataLibrary.Actor memory self, DataLibrary.Actor memory other, DataLibrary.Move memory move) internal view returns (DataLibrary.Actor memory, DataLibrary.Actor memory) {
        for(uint256 j = 0; j < move.actions.length; j++) {
            if(move.self[j]) {
                self = _performAction(move.actions[j], RandomHelper.expand(seed, j + 1), self);
            } else {
                other = _performAction(move.actions[j], RandomHelper.expand(seed, j + 1), other);
            }
        }

        return (self, other);
    }

    function _trap(uint256 seed, uint256 trapId, DataLibrary.Actor memory character) internal view returns (DataLibrary.Actor memory) {
        for(uint256 i = 0; i < _traps[trapId].actions.length; i++) {
            character = _performAction(_traps[trapId].actions[i], seed, character);
        }
        return character;
    }

    function _itemBatchLength(uint256[][7] memory itemIds) internal pure returns (uint256 batchLength) {
        for(uint256 i = 0; i < itemIds.length; i++) {
            for(uint256 j = 0; i < itemIds[i].length; j++) {
                batchLength++;
            }
        }
    }

    function _batchItemIds(uint256[][7] memory itemIds, uint256[][7] memory itemAmounts, uint256 batchLength) internal pure returns (uint256[] memory transferIds, uint256[] memory transferAmounts) {
        transferIds = new uint256[](batchLength);
        transferAmounts = new uint256[](batchLength);
        uint256 batchIndex;
        for(uint256 i = 0; i < itemIds.length; i++) {
            for(uint256 j = 0; i < itemIds[i].length; j++) {
                transferIds[batchIndex] = itemIds[i][j];
                transferAmounts[batchIndex] = itemAmounts[i][j];
                batchIndex++;
            }
        }
    }

    function _performAction(DataLibrary.Action memory action, uint256 seed, DataLibrary.Actor memory character) internal view returns (DataLibrary.Actor memory) {
        return _actions[action.parent].perform(action.id, seed, character, action.data);
    }

    function _getChunkId(uint256 blockNumber) internal pure returns (uint256) {
        return blockNumber / _chunkDuration;
    }

    function _getBlockNumber(uint256 chunkId) internal pure returns (uint256) {
        return chunkId * _chunkDuration;
    }
}