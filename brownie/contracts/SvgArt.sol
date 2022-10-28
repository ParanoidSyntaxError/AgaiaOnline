// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./StringHelper.sol";

contract SvgArt is Ownable {
    struct Attribute {
        string name;
        string value;
    }

    // Index => SVG rectangles hash
    mapping(uint256 => Attribute) internal _bases;
    uint256 internal _totalBases;

    // Index => SVG effect
    mapping(uint256 => Attribute) internal _effects;
    uint256 internal _totalEffects;

    constructor() {

    }

    function addBases(string[] memory names, string[] memory values) external onlyOwner {
        require(names.length == values.length);

        for(uint256 i = 0; i < names.length; i++) {
            _bases[_totalBases + i] = Attribute(names[i], values[i]);
        }

        _totalBases += names.length;
    }

    function addEffects(string[] memory names, string[] memory values) external onlyOwner {
        require(names.length == values.length);

        for(uint256 i = 0; i < names.length; i++) {
            _effects[_totalEffects + i] = Attribute(names[i], values[i]);
        }

        _totalEffects += names.length;
    }

    function _svg(uint256 id, string memory header) internal view returns (string memory) {
        uint256 base = id % 100;
        require(base < _totalBases);
        uint256 effect = (id / 100) - 100;
        require(effect < _totalEffects);

        return string(abi.encodePacked(header, _effects[effect].value, StringHelper.hashToSvg(_bases[base].value), "</svg>"));
    }

    function _name(uint256 id) internal view returns (string memory) {
        uint256 base = id % 100;
        require(base < _totalBases);
        uint256 effect = (id / 100) - 100;
        require(effect < _totalEffects);

        return string(abi.encodePacked(_bases[base].name, " (", _effects[effect].name, ")"));
    }
}