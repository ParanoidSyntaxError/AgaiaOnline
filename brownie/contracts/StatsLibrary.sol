// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library StatsLibrary {
    enum StatType {
        CONSTITUTION,
        DEXTERITY,
        PERCEPTION,
        INTELLIGENCE,
        STRENGTH,
        FAITH
    }

    enum SkillType {
        DODGE,
        ACCURACY,
        INITIATIVE,
        TRAP_DETECTION,
        ITEM_DETECTION,
        FORTITUDE,
        MIGHT
    }

    uint256 internal constant BASE_MAX_HEALTH = 1;
    uint256 internal constant MAX_MAX_HEALTH = 1000;

    uint256 internal constant BASE_STAT = 1;
    uint256 internal constant MAX_STAT = 100;

    uint256 internal constant BASE_DODGE = 1;
    uint256 internal constant BASE_ACCURACY = 1;
    uint256 internal constant BASE_INITIATIVE = 1;
    uint256 internal constant BASE_TRAP_DETECTION = 1;
    uint256 internal constant BASE_ITEM_DETECTION = 1;
    uint256 internal constant BASE_FORTITUDE = 1;
    uint256 internal constant BASE_MIGHT = 1;
    uint256 internal constant MAX_SKILL = 100;
    
    function setStats(uint256[6] memory stats) external pure returns (uint256[6] memory) {
        for(uint256 i = 0; i < stats.length; i++) {
            if(stats[i] > MAX_STAT) {
                stats[i] = MAX_STAT;
            } else if(stats[i] == 0) {
                stats[i] = 1;
            }
        }
        return stats;
    }

    function addStats(uint256[6] memory stats, int256[6] memory amounts) external pure returns (uint256[6] memory) {
        require(stats.length == amounts.length);
        for(uint256 i = 0; i < amounts.length; i++) {
            if(amounts[i] != 0) {
                if(amounts[i] < 0) {
                    if(uint256(amounts[i] * -1) >= stats[i]) {
                        stats[i] = BASE_STAT;
                    } else {
                        stats[i] -= uint256(amounts[i] * -1);
                    }
                }
                else {
                    if(uint256(amounts[i]) + stats[i] >= MAX_STAT) {
                        stats[i] = MAX_STAT;
                    } else {
                        stats[i] += uint256(amounts[i] * -1);
                    }
                }
            }
        }
        return stats;
    }

    function setMaxHealth(uint256 health, uint256 maxHealth) external pure returns (uint256, uint256) {
        if(maxHealth > MAX_MAX_HEALTH) {
            maxHealth = MAX_MAX_HEALTH;
        } else if(maxHealth == 0) {
            maxHealth = BASE_MAX_HEALTH;  
        }

        if(health > maxHealth) {
            health = maxHealth;
        }
        return (health, maxHealth);
    }

    function addMaxHealth(uint256 health, uint256 maxHealth, int256 amount) external pure returns (uint256, uint256) {
        if(amount != 0) {
            if(amount < 0) {
                if(uint256(amount * -1) >= maxHealth) {
                    maxHealth = 1;
                } else {
                    maxHealth -= uint256(amount * -1);
                }

                if(health > maxHealth) {
                    health = maxHealth;
                }
            } else {
                if(uint256(amount * -1) + maxHealth >= MAX_MAX_HEALTH) {
                    maxHealth = MAX_MAX_HEALTH;
                } else {
                    maxHealth += uint256(amount);
                }
            }
        }
        return (health, maxHealth);
    }

    function setHealth(uint256 health, uint256 maxHealth) external pure returns (uint256) {
        if(health >= maxHealth) {
            health = maxHealth;
        }
        return health;
    }

    function addHealth(uint256 health, uint256 maxHealth, int256 amount) external pure returns (uint256) {
        if(amount != 0) {
            if(amount < 0) {
                if(uint256(amount * -1) >= health) {
                    health = 0;
                } else {
                    health -= uint256(amount * -1);
                }
            } else {
                if(uint256(amount * -1) + health >= maxHealth) {
                    health = maxHealth;
                } else {
                    health += uint256(amount * -1);
                }
            }
        }
        return health;
    }

    function calculateDodge(uint256[6] memory stats) external pure returns (uint256) {
        return BASE_DODGE + stats[uint256(StatType.DEXTERITY)];
    }

    function calculateAccuracy(uint256[6] memory stats) external pure returns (uint256) {
        return BASE_ACCURACY + stats[uint256(StatType.DEXTERITY)];
    }

    function calculateInitiative(uint256[6] memory stats) external pure returns (uint256) {
        return BASE_INITIATIVE + stats[uint256(StatType.INTELLIGENCE)];
    }

    function calculateTrapDetection(uint256[6] memory stats) external pure returns (uint256) {
        return BASE_TRAP_DETECTION + stats[uint256(StatType.INTELLIGENCE)] + stats[uint256(StatType.PERCEPTION)];
    }

    function calculateItemDetection(uint256[6] memory stats) external pure returns (uint256) {
        return BASE_ITEM_DETECTION + stats[uint256(StatType.FAITH)] + stats[uint256(StatType.PERCEPTION)];
    }

    function calculateFortitude(uint256[6] memory stats) external pure returns (uint256) {
        return BASE_FORTITUDE + stats[uint256(StatType.CONSTITUTION)];
    }

    function calculateMight(uint256[6] memory stats) external pure returns (uint256) {
        return BASE_MIGHT + stats[uint256(StatType.STRENGTH)];
    }
}