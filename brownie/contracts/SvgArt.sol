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

    function addBases(Attribute[] memory attributes) external onlyOwner {
        for(uint256 i = 0; i < attributes.length; i++) {
            _bases[_totalBases + i] = attributes[i];
        }

        _totalBases += attributes.length;
    }

    function addEffects(Attribute[] memory attributes) external onlyOwner {
        for(uint256 i = 0; i < attributes.length; i++) {
            _effects[_totalEffects + i] = attributes[i];
        }

        _totalEffects += attributes.length;
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