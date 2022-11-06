// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/CardsInterface.sol";
import "./interfaces/CharactersInterface.sol";
import "./interfaces/ItemsInterface.sol";
import "./interfaces/RandomManagerInterface.sol";
import "./interfaces/RandomRequestorInterface.sol";
import "./interfaces/ActionsInterface.sol";
import "./interfaces/GameInterface.sol";

import "./Cards.sol";
import "./Characters.sol";
import "./Items.sol";

import "./DataLibrary.sol";
import "./RandomHelper.sol";
import "./StatsLibrary.sol";

contract Game is GameInterface, RandomRequestorInterface, ERC1155Holder {   
    enum RequestType {
        CARD,
        CHARACTER,
        RAID
    }
    
    enum EncounterType {
        ITEM,
        TRAP,
        ENEMY,
        INVASION,
        NONE
    }

    enum EquipType {
        HEAD,
        CHEST,
        HAND,
        RING,
        NECKLACE,
        TRINKET,
        BAG
    }

    struct RaidRequest {
        uint256 requestId;
        uint256 chunkId;
        uint256 dungeonId;
        uint256[][7] itemIds;
        uint256[][7] itemAmounts;
        address owner;
    }

    struct ItemEncounter {
        uint256 itemId;
        uint256 characterId;
    }

    struct TrapEncounter {
        uint256 seed;
        DataLibrary.Action trap;
        DataLibrary.Actor character;
    }

    struct EnemyEncounter {
        uint256 seed;
        Enemy enemy;
        DataLibrary.Actor character;
        Item equippedItem;
    }

    event Raid(uint256 indexed characterId, address indexed owner, uint256[] eventLog);

    // Chunk ID => Dungeon ID => Character IDs
    mapping(uint256 => mapping(uint256 => uint256[])) internal _chunkCharacters;
    uint256 internal constant _chunkDuration = 15;
    uint256 internal constant _vrfConfirmations = 5;

    mapping(uint256 => RaidRequest) internal _raidRequests;

    mapping(address => uint256) internal _characterRequests;

    mapping(address => uint256) internal _cardRequests;

    CardsInterface public immutable cards;
    CharactersInterface public immutable characters;
    ItemsInterface public immutable items;

    uint256[7] internal _equipTypeMaxes;

    RandomManagerInterface public immutable randomManager;

    mapping(uint256 => ActionsInterface) internal _actions;
    uint256 internal _totalActions;

    mapping(uint256 => Dungeon) internal _dungeons;
    uint256 internal _totalDungeons;

    mapping(uint256 => DataLibrary.Action) internal _traps;
    uint256 internal _totalTraps;

    mapping(uint256 => Enemy) internal _enemies;
    uint256 internal _totalEnemies;

    uint256 internal constant _probabilitiesMax = 100;

    mapping(uint256 => Item) internal _items;

    mapping(uint256 => DataLibrary.Actor) internal _characters;
    mapping(uint256 => Qwerk) internal _qwerks;

    constructor(address randomManagerContract) {
        cards = CardsInterface(new Cards(address(this), msg.sender));
        characters = CharactersInterface(new Characters(address(this), msg.sender));
        items = ItemsInterface(new Items(address(this), msg.sender));

        randomManager = RandomManagerInterface(randomManagerContract);

        _equipTypeMaxes[uint256(EquipType.HEAD)] = 1;
        _equipTypeMaxes[uint256(EquipType.CHEST)] = 1;
        _equipTypeMaxes[uint256(EquipType.HAND)] = 1;
        _equipTypeMaxes[uint256(EquipType.RING)] = 2;
        _equipTypeMaxes[uint256(EquipType.NECKLACE)] = 1;
        _equipTypeMaxes[uint256(EquipType.TRINKET)] = 2; 
        _equipTypeMaxes[uint256(EquipType.BAG)] = 10;
    }

    function addQwerks(Qwerk[] memory qwerks) external{}
    function addItems(Item[] memory items) external{}

    function addActions(address actions) external override {
        _actions[_totalActions] = ActionsInterface(actions);
        _totalActions++;
    }

    function addDungeons(Dungeon[] memory dungeons) external override {
        for(uint256 i = 0; i < dungeons.length; i++) {
            _dungeons[_totalDungeons] = dungeons[i];
            _totalDungeons++;
        }
    }

    function addTraps(DataLibrary.Action[] memory actions) external override {
        for(uint256 i = 0; i < actions.length; i++) {
            _traps[_totalTraps] = actions[i];
            _totalTraps++;
        }
    }

    function addEnemies(Enemy[] memory enemies) external override {
        for(uint256 i = 0; i < enemies.length; i++) {
        _enemies[_totalEnemies] = enemies[i];
        _totalEnemies++;
        }
    }

    function randomCount(uint256 dataType) external view override returns (uint32) {
        if(dataType == uint256(RequestType.CARD)) {
            return 2;
        } else if (dataType == uint256(RequestType.CHARACTER)) {
            return 10;
        } else if (dataType == uint256(RequestType.RAID)) {
            return _dungeons[dataType].randomCount;
        }
        return 0;
    }

    function onRequestRandom(address sender, uint256 transferAmount, uint256 creditAmount, address transferReceiver, address creditReceiver, uint256 requestId, uint256 dataType, bytes memory data) external override {
        if(dataType == uint256(RequestType.CARD)) {
            _requestNewCard(sender, transferAmount, creditAmount, transferReceiver, creditReceiver, requestId);
        } else if (dataType == uint256(RequestType.CHARACTER)) {
            _requestNewCharacter(sender, requestId);
        } else if (dataType == uint256(RequestType.RAID)) {
            _requestRaid(sender, requestId, data);
        }
    }

    function _requestRaid(address sender, uint256 requestId, bytes memory data) internal {
        (uint256 dungeonId, uint256 characterId, uint256[][7] memory itemIds, uint256[][7] memory itemAmounts) = abi.decode(data, (uint256, uint256, uint256[][7], uint256[][7]));
        require(_raidRequests[characterId].owner == address(0));     

        require(characters.ownerOf(characterId) == sender);
        characters.transferFrom(sender, address(this), characterId);

        uint256 batchLength;
        uint256[7] memory equipLoad = _equipTypeMaxes;

        for(uint256 i = 0; i < itemIds.length; i++) {
            require(itemIds[i].length == itemAmounts[i].length);
            for(uint256 j = 0; i < itemIds[i].length; j++) {
                require(itemAmounts[i][j] > 0);
                if(i != itemIds.length - 1) {
                    require(i == _items[itemIds[i][j]].equipType);
                }
                equipLoad[i] -= itemAmounts[i][j];
                batchLength++;
            }
        }

        (uint256[] memory transferIds, uint256[] memory transferAmounts) = _batchItemIds(itemIds, itemAmounts, batchLength);

        items.safeBatchTransferFrom(sender, address(this), transferIds, transferAmounts, "");

        uint256 chunkId = _getChunkId(block.number);

        _chunkCharacters[chunkId][dungeonId].push(characterId);
        _raidRequests[characterId] = RaidRequest(requestId, chunkId, dungeonId, itemIds, itemAmounts, sender);
    }

    function _requestNewCharacter(address sender, uint256 requestId) internal {
        require(cards.totalBalanceOf(sender) > 0);
        require(_characterRequests[sender] == 0);

        _characterRequests[sender] = requestId;
    }

    function _requestNewCard(address sender, uint256 transferAmount, uint256 creditAmount, address transferReveiver, address creditReceiver, uint256 requestId) internal {
        require(_cardRequests[sender] == 0);
        require(transferAmount >= 10 ** 18);
        require(creditAmount >= 10 ** 18);
        require(transferReveiver == address(this));
        require(creditReceiver == sender);

        _cardRequests[sender] = requestId;
    }

    function claimCard() external {
        require(_cardRequests[msg.sender] > 0);
        require(randomManager.requestResponded(_cardRequests[msg.sender]));

        uint256[] memory responses = randomManager.randomResponse(_cardRequests[msg.sender]);

        cards.mint(msg.sender, [responses[0], responses[1]], 1);

        _cardRequests[msg.sender] = 0;
    }

    function claimCharacter(string memory name) external {
        require(bytes(name).length > 0);
        require(bytes(name).length <= 32);
        require(_characterRequests[msg.sender] > 0);
        require(randomManager.requestResponded(_characterRequests[msg.sender]));

        uint256[] memory responses = randomManager.randomResponse(_characterRequests[msg.sender]);

        uint256 characterId = characters.mint(msg.sender, [responses[0], responses[1]], name);

        uint256 maxHealth = (responses[2] % 26) + 50;
        (_characters[characterId].health, _characters[characterId].maxHealth) = StatsLibrary.setMaxHealth(maxHealth, maxHealth);

        // Set stats
        uint256[6] memory stats;
        for(uint256 i = 0; i < stats.length; i++) {
            stats[i] = (responses[i + 3] % 4) + 1;
        }
        _characters[characterId].stats = StatsLibrary.setStats(stats);
        
        // TODO: Add qwerk

        _characterRequests[msg.sender] = 0;
    }

    function claimRaid(uint256 characterId) external override {
        require(_raidRequests[characterId].owner != address(0));     
        require(randomManager.requestResponded(_raidRequests[characterId].requestId));

        uint256[] memory responses = randomManager.randomResponse(_raidRequests[characterId].requestId);

        DataLibrary.Actor memory character = _characters[characterId];

        uint256[] memory eventLog = new uint256[](responses.length);
        uint256 eventLogIndex;

        for(uint256 i = 0; i < responses.length; i++) {
            (uint256 encounter, uint256 id) = _rollEncounter(responses[i], _raidRequests[characterId].dungeonId);

            eventLog[eventLogIndex] = (encounter + 1) * (10 ** 16);
            if(encounter != uint256(EncounterType.NONE)) {
                eventLog[eventLogIndex] += id * (10 ** 12);      
            }
            eventLog[eventLogIndex] += character.health * (10 ** 8);

            if(encounter == uint256(EncounterType.ITEM)) {
                // ITEM
                _item(ItemEncounter(
                    id, 
                    characterId
                ));
            } else if (encounter == uint256(EncounterType.TRAP)) {
                // TRAP
                character = _trap(TrapEncounter(
                    RandomHelper.expand(responses[i], 3), 
                    _traps[id], 
                    character
                ));
            } else if (encounter == uint256(EncounterType.ENEMY)) {
                // ENEMY
                uint256 result; // Stupid fucking compiler
                (character, result) = _enemy(EnemyEncounter(
                    RandomHelper.expand(responses[i], 3), 
                    _enemies[id], 
                    character, 
                    _items[_raidRequests[characterId].itemIds[uint256(EquipType.HAND)][0]]
                ));
                eventLog[eventLogIndex] += result;
            } else if (encounter == uint256(EncounterType.INVASION)) {
                // INVASION
                // TODO: Use other raiding players
            } else {
                // NONE
                // TODO: Chance to progress the story
            }

            eventLog[eventLogIndex] += character.health * (10 ** 4);

            eventLogIndex++;

            if(character.health == 0) {
                // DEATH
                eventLog[eventLogIndex] = 777;
                break;
            }
        }

        if(character.health > 0) {
            uint256 batchLength = _itemBatchLength(_raidRequests[characterId].itemIds);
            (uint256[] memory transferIds, uint256[] memory transferAmounts) = _batchItemIds(_raidRequests[characterId].itemIds, _raidRequests[characterId].itemAmounts, batchLength);
            items.safeBatchTransferFrom(address(this), _raidRequests[characterId].owner, transferIds, transferAmounts, "");
            characters.transferFrom(address(this), _raidRequests[characterId].owner, characterId);
        }

        _raidRequests[characterId].owner = address(0);

        emit Raid(characterId, _raidRequests[characterId].owner, eventLog);
    }

    function _item(ItemEncounter memory params) internal {
        items.mint(params.itemId, address(this), 1);
        _raidRequests[params.characterId].itemIds[uint256(EquipType.BAG)].push(params.itemId);
        _raidRequests[params.characterId].itemAmounts[uint256(EquipType.BAG)].push(1);
    }

    function _trap(TrapEncounter memory params) internal view returns (DataLibrary.Actor memory) {
        for(uint256 i = 0; i < params.trap.parents.length; i++) {
            params.character = _actions[params.trap.parents[i]].perform(params.trap.ids[i], params.seed, params.character, params.trap.data[i]);
        }
        return params.character;
    }

    function _enemy(EnemyEncounter memory params) internal view returns (DataLibrary.Actor memory, uint256) {        
        uint256 randNonce = 1;

        for(uint256 i = 0; i < 10; i ++) {
            bool playerFirst;
            if(StatsLibrary.calculateInitiative(params.character.stats) == StatsLibrary.calculateInitiative(params.enemy.actor.stats)) {
                if(RandomHelper.expand(params.seed, randNonce) % 2 == 0) {
                    playerFirst = true;
                }
                randNonce++;
            } else if(StatsLibrary.calculateInitiative(params.character.stats) > StatsLibrary.calculateInitiative(params.enemy.actor.stats)) {
                playerFirst = true;
            }

            for(uint256 m = 0; m < 2; m++) {
                if(playerFirst) {
                    (params.character, params.enemy.actor) = _performAction(
                        RandomHelper.expand(params.seed, randNonce), 
                        params.character, 
                        params.enemy.actor, 
                        params.equippedItem.action
                    );
                } else {
                    (params.enemy.actor, params.character) = _performAction(
                        RandomHelper.expand(params.seed, randNonce), 
                        params.enemy.actor, 
                        params.character, 
                        params.enemy.action
                    );
                    randNonce++;
                }

                if(params.character.health == 0) {
                    // Death
                    return (params.character, 7);
                } else if (params.enemy.actor.health == 0) {
                    // Killed enemy
                    return (params.character, 1);
                }

                randNonce++;
                playerFirst = !playerFirst;
            }
        }

        // Flee
        return (params.character, 3);
    }

    function _rollEncounter(uint256 seed, uint256 dungeonId) internal view returns (uint256, uint256) {
        uint256 encounter = RandomHelper.expand(seed, 1) % _probabilitiesMax;
        uint256 probabilityIncrement;
        for(uint256 j = 0; j < _dungeons[dungeonId].encounterChances.length; j++) {
            probabilityIncrement += _dungeons[dungeonId].encounterChances[j];
            if(encounter < probabilityIncrement) {
                encounter = j;
                break;
            }
        }
        uint256 id = RandomHelper.expand(seed, 2) % _probabilitiesMax;
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

    function _performAction(uint256 seed, DataLibrary.Actor memory self, DataLibrary.Actor memory other, DataLibrary.Action memory action) internal view returns (DataLibrary.Actor memory, DataLibrary.Actor memory) {
        for(uint256 i = 0; i < action.parents.length; i++) {
            if(action.self[i]) {
                self = _actions[action.parents[i]].perform(action.ids[i], seed, self, action.data[i]);
            } else {
                other = _actions[action.parents[i]].perform(action.ids[i], seed, other, action.data[i]);
            }
        }
        return (self, other);
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

    function _getChunkId(uint256 blockNumber) internal pure returns (uint256) {
        return blockNumber / _chunkDuration;
    }

    function _getBlockNumber(uint256 chunkId) internal pure returns (uint256) {
        return chunkId * _chunkDuration;
    }
}