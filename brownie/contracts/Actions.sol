// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ActionsInterface.sol";
import "./StatsLibrary.sol";

contract Actions is ActionsInterface {
    constructor() {

    }

    function perform(uint256 id, DataLibrary.Actor memory actor, bytes memory data) external pure returns (DataLibrary.Actor memory) {
        if(id == 0) {
            actor.health = StatsLibrary.addHealth(actor.health, actor.maxHealth, abi.decode(data, (int256)));
        } else if (id == 1) {
            (,actor.maxHealth) = StatsLibrary.addMaxHealth(actor.health, actor.maxHealth, abi.decode(data, (int256)));
        } else if (id == 2) {
            actor.stats = StatsLibrary.addStats(actor.stats, abi.decode(data, (int256[6])));
        }
        return actor;
    }
}