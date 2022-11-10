// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library DataLibrary {
    struct TokenMetadata {
        string name;
        uint256 tokenHash;
    }

    struct Actor {
        uint256 health;
        uint256 maxHealth;
        uint256[6] stats;
        uint256[] qwerks;
    }

    struct Action {
        uint256[] parents;
        uint256[] ids;
        bytes[] data;
        bool[] self;
    }
}