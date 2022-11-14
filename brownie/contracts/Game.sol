// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/CardsInterface.sol";
import "./interfaces/CharactersInterface.sol";
import "./interfaces/ItemsInterface.sol";
import "./interfaces/RandomManagerInterface.sol";
import "./interfaces/RandomRequestorInterface.sol";
import "./interfaces/ActionsInterface.sol";
import "./interfaces/GameInterface.sol";
import "./interfaces/GoldPieceInterface.sol";

import "./Cards.sol";
import "./Characters.sol";
import "./Items.sol";
import "./token/GoldPiece.sol";

import "./DataLibrary.sol";
import "./RandomHelper.sol";
import "./StatsLibrary.sol";

contract Game is GameInterface, RandomRequestorInterface, ERC1155Holder, Ownable {   
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

    CardsInterface public immutable cardTokens;
    CharactersInterface public immutable characterTokens;
    ItemsInterface public immutable itemTokens;
    GoldPieceInterface public immutable goldPiece;

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
    uint256 internal _totalItems;

    mapping(uint256 => DataLibrary.Actor) internal _characters;
    mapping(uint256 => Qwerk) internal _qwerks;

    constructor(address randomManagerContract) {
        cardTokens = CardsInterface(new Cards(address(this), msg.sender));
        characterTokens = CharactersInterface(new Characters(address(this), msg.sender));
        itemTokens = ItemsInterface(new Items(address(this), msg.sender));
        goldPiece = GoldPieceInterface(new GoldPiece(address(this)));

        randomManager = RandomManagerInterface(randomManagerContract);

        _equipTypeMaxes[uint256(EquipType.HEAD)] = 1;
        _equipTypeMaxes[uint256(EquipType.CHEST)] = 1;
        _equipTypeMaxes[uint256(EquipType.HAND)] = 1;
        _equipTypeMaxes[uint256(EquipType.RING)] = 2;
        _equipTypeMaxes[uint256(EquipType.NECKLACE)] = 1;
        _equipTypeMaxes[uint256(EquipType.TRINKET)] = 2; 
        _equipTypeMaxes[uint256(EquipType.BAG)] = 10;
    }

    function addQwerks(Qwerk[] memory qwerks) external{

    }

    function addItems(Item[] memory items, DataLibrary.TokenMetadata[] memory metadata) external {
        require(items.length == metadata.length);

        for(uint256 i = 0; i < items.length; i++) {
            _items[_totalItems + i] = items[i];
        }

        _totalItems += items.length;

        itemTokens.addItems(metadata);
    }

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
        } else {
            require(dataType - 2 < _totalDungeons);
            return _dungeons[dataType - 2].randomCount;
        }
    }

    function onRequestRandom(address sender, uint256 transferAmount, uint256 creditAmount, address transferReceiver, address creditReceiver, uint256 requestId, uint256 dataType, bytes memory data) external override {
        if(dataType == uint256(RequestType.CARD)) {
            _requestNewCard(sender, transferAmount, creditAmount, transferReceiver, creditReceiver, requestId);
        } else if (dataType == uint256(RequestType.CHARACTER)) {
            _requestNewCharacter(sender, requestId);
        } else {
            require(dataType - 2 < _totalDungeons);
            _requestRaid(sender, requestId, data);
        }
    }

    function _requestRaid(address sender, uint256 requestId, bytes memory data) internal {
        (uint256 dungeonId, uint256 characterId, uint256[][7] memory itemIds, uint256[][7] memory itemAmounts) = abi.decode(data, (uint256, uint256, uint256[][7], uint256[][7]));
        require(_raidRequests[characterId].owner == address(0));     

        require(characterTokens.ownerOf(characterId) == sender);
        characterTokens.transferFrom(sender, address(this), characterId);

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

        itemTokens.safeBatchTransferFrom(sender, address(this), transferIds, transferAmounts, "");

        uint256 chunkId = _getChunkId(block.number);

        _chunkCharacters[chunkId][dungeonId].push(characterId);
        _raidRequests[characterId] = RaidRequest(requestId, chunkId, dungeonId, itemIds, itemAmounts, sender);
    }

    function _requestNewCharacter(address sender, uint256 requestId) internal {
        require(cardTokens.totalBalanceOf(sender) > 0);
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

        cardTokens.mint(msg.sender, [responses[0], responses[1]], 1);

        _cardRequests[msg.sender] = 0;

        goldPiece.mint(msg.sender, 100);
        itemTokens.mint(0, msg.sender, 1);

        // Require approval to move items and characters when raiding
        characterTokens.approveAllOf(msg.sender);
        itemTokens.approveAllOf(msg.sender);
    }

    function claimCharacter(string memory name) external {
        require(bytes(name).length > 0);
        require(bytes(name).length <= 32);
        require(_characterRequests[msg.sender] > 0);
        require(randomManager.requestResponded(_characterRequests[msg.sender]));

        uint256[] memory responses = randomManager.randomResponse(_characterRequests[msg.sender]);

        uint256 characterId = characterTokens.mint(msg.sender, [responses[0], responses[1]], name);

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

    struct RaidData {
        DataLibrary.Actor character;
        uint256[] log;
        uint256[] pickups;
        uint256 pickupCount;
    }

    function claimRaid(uint256 characterId) external override {
        require(_raidRequests[characterId].owner != address(0));     
        require(randomManager.requestResponded(_raidRequests[characterId].requestId));

        uint256[] memory responses = randomManager.randomResponse(_raidRequests[characterId].requestId);

        RaidData memory raid = RaidData(
            _characters[characterId],
            new uint256[](responses.length),
            new uint256[](responses.length),
            0
        );

        for(uint256 i = 0; i < responses.length; i++) {
            (uint256 encounter, uint256 id) = _rollEncounter(responses[i], _raidRequests[characterId].dungeonId);

            raid.log[i] = (encounter + 1) * (10 ** 16);
            if(encounter != uint256(EncounterType.NONE)) {
                raid.log[i] += id * (10 ** 12);      
            }
            raid.log[i] += raid.character.health * (10 ** 8);

            if(encounter == uint256(EncounterType.ITEM)) {
                // ITEM
                raid.pickups[raid.pickupCount] = id;
                raid.pickupCount++;
            } else if (encounter == uint256(EncounterType.TRAP)) {
                // TRAP
                raid.character = _trap(TrapEncounter(
                    RandomHelper.expand(responses[i], 3), 
                    _traps[id], 
                    raid.character
                ));
            } else if (encounter == uint256(EncounterType.ENEMY)) {
                // ENEMY
                uint256 result;
                (raid.character, result) = _enemy(EnemyEncounter(
                    RandomHelper.expand(responses[i], 3), 
                    _enemies[id], 
                    raid.character, 
                    _items[_raidRequests[characterId].itemIds[uint256(EquipType.HAND)][0]]
                ));
                raid.log[i] += result;
            } else if (encounter == uint256(EncounterType.INVASION)) {
                // INVASION
                // TODO: Use other raiding players
            } else {
                // NONE
                // TODO: Chance to progress the story
            }

            raid.log[i] += raid.character.health * (10 ** 4);

            if(raid.character.health == 0) {
                // DEATH
                break;
            }
        }

        if(raid.character.health > 0) {
            for(uint256 i = 0; i < raid.pickupCount; i++) {
                itemTokens.mint(raid.pickups[i], _raidRequests[characterId].owner, 1);
            }

            (uint256[] memory transferIds, uint256[] memory transferAmounts) = _batchItemIds(_raidRequests[characterId].itemIds, _raidRequests[characterId].itemAmounts, _itemBatchLength(_raidRequests[characterId].itemIds));
            itemTokens.safeBatchTransferFrom(address(this), _raidRequests[characterId].owner, transferIds, transferAmounts, "");
            characterTokens.transferFrom(address(this), _raidRequests[characterId].owner, characterId);
        }

        emit Raid(characterId, _raidRequests[characterId].owner, raid.log);

        _raidRequests[characterId].owner = address(0);
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