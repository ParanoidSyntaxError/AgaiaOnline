// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./token/CharactersERC721.sol";

import "./interfaces/RandomManagerInterface.sol";
import "./interfaces/RandomRequestorInterface.sol";
import "./interfaces/CardsInterface.sol";

import "./SvgArt.sol";

import "./StatsLibrary.sol";

contract Characters is CharactersERC721, SvgArt, RandomRequestorInterface {
    mapping(uint256 => DataLibrary.Actor) internal _characters;
    mapping(uint256 => DataLibrary.TokenMetadata) internal _metadata;
    uint256 internal _totalCharacters;

    mapping(uint256 => DataLibrary.Qwerk) internal _qwerks;
    uint256 internal _totalQwerks;

    uint256 internal constant HEALTH_MAX = 1000;
    uint256 internal constant STAT_MAX = 100;

    mapping(address => uint256) internal _requestIds;

    RandomManagerInterface public immutable randomManager;
  
    CardsInterface public immutable cards;
    
    address public immutable game;

    constructor(address gameContract, address cardsContract, address randomManagerContract) CharactersERC721("name", "symbol") {
        game = gameContract;
        cards = CardsInterface(cardsContract);
        randomManager = RandomManagerInterface(randomManagerContract);
    }

    modifier onlyGame {
        require(msg.sender == game);
        _;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalCharacters;
    }

    function totalQwerks() external view override returns (uint256) {
        return _totalQwerks;
    }

    function getCharacter(uint256 characterId) external view override returns (DataLibrary.Actor memory) {
        require(_exists(characterId));
        return _characters[characterId];
    }

    function getQwerk(uint256 qwerkId) external view override returns (DataLibrary.Qwerk memory) {
        require(qwerkId < _totalQwerks);
        return _qwerks[qwerkId];
    }

    function randomCount(uint256 /*dataType*/) external pure override returns (uint32) {
        return 10;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {       
        return StringHelper.encodeMetadata(
            _name(id),
            "Description", 
            _svg(id, "<svg xmlns='http://www.w3.org/2000/svg' id='block-hack' preserveAspectRatio='xMinYMin meet' viewBox='0 0 32 32'><style>#block-hack{shape-rendering: crispedges;}</style>"), 
            "Attributes"
        );
    }

    function newQwerks(DataLibrary.Qwerk[] memory qwerks) external override onlyOwner {
        for(uint256 i = 0; i < qwerks.length; i++) {
            _qwerks[_totalQwerks + i] = qwerks[i];
        }

        _totalQwerks += qwerks.length;
    }

    function onRequestRandom(address sender, uint256 requestId, uint256 /*dataType*/, bytes memory /*data*/) external override {
        require(msg.sender == address(randomManager));
        require(cards.totalBalanceOf(sender) > 0);
        require(_requestIds[sender] == 0);
        
        _requestIds[sender] = requestId;
    }

    function claim(string calldata name) external override {      
        require(bytes(name).length > 0);
        require(bytes(name).length <= 32);
        require(_requestIds[msg.sender] > 0);
        require(randomManager.requestResponded(_requestIds[msg.sender]));

        _requestIds[msg.sender] = 0;

        _newCharacter(msg.sender, name, randomManager.randomResponse(_requestIds[msg.sender]));
    }

    function _newCharacter(address receiver, string calldata name, uint256[] memory reponses) internal {
        uint256 characterId = _totalCharacters;

        // Mint token
        _safeMint(receiver, characterId);

        // Increment total supply
        _totalCharacters++;

        // Set name
        _metadata[characterId].name = name;

        // Set token hash (SVG art)
        uint256 baseRoll = reponses[0] % _totalBases;
        uint256 effectRoll = reponses[1] % _totalEffects;
        _metadata[characterId].tokenHash = ((effectRoll * 100) + baseRoll) + 10000;

        // Set health
        uint256 maxHealth = (reponses[2] % 26) + 50;
        (_characters[characterId].health, _characters[characterId].maxHealth) = StatsLibrary.setMaxHealth(maxHealth, maxHealth);

        // Set stats
        uint256[6] memory stats;
        for(uint256 i = 0; i < stats.length; i++) {
            stats[i] = (reponses[i + 3] % 4) + 1;
        }
        _characters[characterId].stats = StatsLibrary.setStats(stats);
        
        // Add qwerk
        addQwerk(characterId, reponses[9] % _totalQwerks);
    }

    function addQwerk(uint256 characterId, uint256 qwerkId) public override onlyGame {
        require(_exists(characterId));
        require(qwerkId < _totalQwerks);

        _characters[characterId].qwerks.push(qwerkId);

        (,_characters[characterId].maxHealth) = StatsLibrary.addMaxHealth(_characters[characterId].health, _characters[characterId].maxHealth, _qwerks[qwerkId].maxHealth);
        _characters[characterId].stats = StatsLibrary.addStats(_characters[characterId].stats, _qwerks[qwerkId].stats);
    }

    function setStats(uint256 characterId, uint256[6] memory stats) public override onlyGame {
         _characters[characterId].stats = stats;
    }

    function setMaxHealth(uint256 characterId, uint256 maxHealth) public override onlyGame {
        _characters[characterId].maxHealth = maxHealth;
    }

    function setHealth(uint256 characterId, uint256 health) public override onlyGame {
        _characters[characterId].health = health;
    }
}