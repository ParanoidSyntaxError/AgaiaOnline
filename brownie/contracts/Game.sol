// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./RandomManagerInterface.sol";
import "./RandomRequestorInterface.sol";
import "./CharactersInterface.sol";

contract Game is RandomRequestorInterface {
    struct Character {
        string name;
        uint256 health;
        uint256 maxHealth;
        uint256[5] stats;
        uint256[] qwerks;
    }

    struct Qwerk {
        string name;
        int256 maxHealth;
        int256[5] stats;
    }

    mapping(uint256 => Character) internal _characters;

    mapping(uint256 => Qwerk) internal _qwerks;
    uint256 internal _totalQwerks;

    uint256 internal constant HEALTH_MAX = 1000;
    uint256 internal constant STAT_MAX = 100;

    mapping(uint256 => uint256) internal _requestIds;
    
    RandomManagerInterface public immutable randomManager;

    CharactersInterface public immutable characters;

    constructor(address chars, address rngManager) {
        randomManager = RandomManagerInterface(rngManager);

        characters = CharactersInterface(chars);

        // Initial qwerks
        _qwerks[0] = Qwerk("Coward", 0, [int256(0), 0, 0, 0, 0]);
        _qwerks[1] = Qwerk("Brave", 0, [int256(0), 0, 0, 0, 0]);
        _qwerks[2] = Qwerk("Clumsy", 0, [int256(0), 0, 0, 0, 0]);

        _totalQwerks = 3;
    }

    function randomCount(uint256 /*dataType*/) external pure override returns (uint32) {
        return 7;
    }

    function onRequestRandom(address /*sender*/, uint256 requestId, uint256 /*dataType*/, bytes memory data) external override {
        require(msg.sender == address(randomManager));

        uint256 characterId = abi.decode(data, (uint256));

        require(characterId < characters.totalSupply());
        require(_requestIds[characterId] == 0);
        
        _requestIds[characterId] = requestId;
    }

    function claim(uint256 characterId, string calldata name) external {
        require(bytes(name).length > 0);
        require(bytes(name).length <= 32);
        require(_requestIds[characterId] > 1);
        require(randomManager.requestResponded(_requestIds[characterId]));

        _requestIds[characterId] = 1;

        uint256[] memory reponses = randomManager.randomResponse(_requestIds[characterId]);

        uint256[5] memory stats;
        uint256[] memory qwerks;

        _characters[characterId] = Character(name, 0, 0, stats, qwerks);

        uint256 maxHealth = (reponses[0] % 26) + 50;
        _setMaxHealth(characterId, maxHealth);
        _setHealth(characterId, maxHealth);

        for(uint256 i = 0; i < stats.length; i++) {
            stats[i] = (reponses[i + 1] % 4) + 1;
        }
        _setStats(characterId, stats);
        
        _addQwerk(characterId, reponses[6] % _totalQwerks);
    }

    function _isCharacterCreated(uint256 characterId) internal view returns (bool) {
        return _requestIds[characterId] == 1;
    }

    function _addQwerk(uint256 characterId, uint256 qwerkId) internal {
        require(_isCharacterCreated(characterId));
        require(qwerkId < _totalQwerks);

        _characters[characterId].qwerks.push(qwerkId);

        _addMaxHealth(characterId, _qwerks[qwerkId].maxHealth);
        _addStats(characterId, _qwerks[qwerkId].stats);
    }

    function _setStats(uint256 characterId, uint256[5] memory stats) internal {
        for(uint256 i = 0; i < stats.length; i++) {
            if(stats[i] >= STAT_MAX) {
                _characters[characterId].stats[i] = STAT_MAX;
            } else {
                if(stats[i] == 0) {
                    _characters[characterId].stats[i] = 1;
                } else {
                    _characters[characterId].stats[i] = stats[i];
                }
            }
        }
    }

    function _addStats(uint256 characterId, int256[5] memory amounts) internal {
        for(uint256 i = 0; i < amounts.length; i++) {
            if(amounts[i] != 0) {
                if(amounts[i] < 0) {
                    if(uint256(amounts[i] * -1) >= _characters[characterId].stats[i]) {
                        _characters[characterId].stats[i] = 1;
                    } else {
                        _characters[characterId].stats[i] -= uint256(amounts[i] * -1);
                    }
                }
                else {
                    if(uint256(amounts[i]) + _characters[characterId].stats[i] >= STAT_MAX) {
                        _characters[characterId].stats[i] = STAT_MAX;
                    } else {
                        _characters[characterId].stats[i] += uint256(amounts[i] * -1);
                    }
                }
            }
        }
    }

    function _setMaxHealth(uint256 characterId, uint256 maxHealth) internal {
        if(maxHealth >= HEALTH_MAX) {
            _characters[characterId].maxHealth = HEALTH_MAX;
        } else {
            if(maxHealth == 0) {
                _characters[characterId].maxHealth = 1;
            } else {
                _characters[characterId].maxHealth = maxHealth;
            }
        }
    }

    function _addMaxHealth(uint256 characterId, int256 amount) internal {
        if(amount != 0) {
            if(amount < 0) {
                if(uint256(amount * -1) >= _characters[characterId].maxHealth) {
                    _characters[characterId].maxHealth = 1;
                } else {
                    _characters[characterId].maxHealth -= uint256(amount * -1);
                }
            } else {
                if(uint256(amount * -1) + _characters[characterId].maxHealth >= HEALTH_MAX) {
                    _characters[characterId].maxHealth = HEALTH_MAX;
                } else {
                    _characters[characterId].maxHealth += uint256(amount);
                }
            }
        }
    }

    function _setHealth(uint256 characterId, uint256 health) internal {
        if(health >= _characters[characterId].maxHealth) {
            _characters[characterId].health = _characters[characterId].maxHealth;
        } else {
            _characters[characterId].health = health;
        }
    }

    function _addHealth(uint256 characterId, int256 amount) internal {
        if(amount != 0) {
            if(amount < 0) {
                if(uint256(amount * -1) >= _characters[characterId].health) {
                    _characters[characterId].health = 0;
                } else {
                    _characters[characterId].health -= uint256(amount * -1);
                }
            } else {
                if(uint256(amount * -1) + _characters[characterId].health >= _characters[characterId].maxHealth) {
                    _characters[characterId].health = _characters[characterId].maxHealth;
                } else {
                    _characters[characterId].health += uint256(amount * -1);
                }
            }
        }
    }
}