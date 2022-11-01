// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./token/ItemsERC1155.sol";
import "./SvgArt.sol";

contract Items is ItemsERC1155, SvgArt {
    struct Item {
        string name;
        uint256 tokenHash;
        uint256 equipType;
        uint256[] actionIds;
        bytes[] actionData;
    }

    // ID => Item
    mapping(uint256 => Item) _items;
    uint256 internal _totalItems;

    // ID => Supply
    mapping(uint256 => uint256) internal _totalSupplys;
    uint256 internal _totalSupply;

    address public game;

    constructor() ItemsERC1155("") {

    }

    modifier onlyGame {
        require(msg.sender == game);
        _;
    }

    function mint(uint256 id, address to, uint256 amount) external override onlyGame {
        require(id < _totalItems);
        _mint(to, id, amount, "");
    }

    function getItem(uint256 id) external view returns (string memory name, uint256 equipType) {
        require(id < _totalItems);
        return (_items[id].name, uint256(_items[id].equipType));
    }

    function uri(uint256 id) public view virtual override returns (string memory) {       
        require(id < _totalItems);

        return StringHelper.encodeMetadata(
            _items[id].name,
            "Description", 
            _svg(id, "<svg xmlns='http://www.w3.org/2000/svg' id='block-hack' preserveAspectRatio='xMinYMin meet' viewBox='0 0 24 24'><style>#block-hack{shape-rendering: crispedges;}</style>"), 
            "Attributes"
        );
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function itemSupply(uint256 id) external view override returns (uint256) {
        return _totalSupplys[id];
    }
}