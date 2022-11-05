// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library DataLibrary {
    enum EquipType {
        HEAD,
        CHEST,
        HAND,
        RING,
        NECKLACE,
        TRINKET,
        BAG
    }

    struct TokenMetadata {
        string name;
        uint256 tokenHash;
    }

    struct Item {
        uint256 equipType;
        DataLibrary.Action action;
    }

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

    struct Action {
        uint256[] parents;
        uint256[] ids;
        bytes[] data;
        bool[] self;
    }
}