// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library DataLibrary {
    struct Actor {
        uint256 health;
        uint256 maxHealth;
        uint256[6] stats;
        uint256[] qwerks;
    }

    struct Qwerk {
        string name;
        int256 maxHealth;
        int256[6] stats;
    }
}