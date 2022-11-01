// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library StatsLibrary {
    uint256 internal constant HEALTH_MAX = 1000;
    uint256 internal constant STAT_MAX = 100;

    function setStats(uint256[6] memory stats) external pure returns (uint256[6] memory) {
        for(uint256 i = 0; i < stats.length; i++) {
            if(stats[i] > STAT_MAX) {
                stats[i] = STAT_MAX;
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
                        stats[i] = 1;
                    } else {
                        stats[i] -= uint256(amounts[i] * -1);
                    }
                }
                else {
                    if(uint256(amounts[i]) + stats[i] >= STAT_MAX) {
                        stats[i] = STAT_MAX;
                    } else {
                        stats[i] += uint256(amounts[i] * -1);
                    }
                }
            }
        }
        return stats;
    }

    function setMaxHealth(uint256 health, uint256 maxHealth) external pure returns (uint256, uint256) {
        if(maxHealth > HEALTH_MAX) {
            maxHealth = HEALTH_MAX;
        } else if(maxHealth == 0) {
            maxHealth = 1;  
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
                if(uint256(amount * -1) + maxHealth >= HEALTH_MAX) {
                    maxHealth = HEALTH_MAX;
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
}