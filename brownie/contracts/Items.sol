// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./token/ItemsERC1155.sol";
import "./SvgArt.sol";
import "./DataLibrary.sol";

contract Items is ItemsERC1155, SvgArt {


    // ID => Item
    mapping(uint256 => DataLibrary.Item) _items;
    mapping(uint256 => DataLibrary.TokenMetadata) _metadata;
    uint256 internal _totalItems;

    // ID => Supply
    mapping(uint256 => uint256) internal _totalSupplys;
    uint256 internal _totalSupply;

    address public game;

    constructor(address gameContract, address owner) ItemsERC1155("") {
        game = gameContract;
        _transferOwnership(owner);
    }

    modifier onlyGame {
        require(msg.sender == game);
        _;
    }

    function addItem(DataLibrary.Item memory item, DataLibrary.TokenMetadata memory metadata) external override {
        _items[_totalItems] = item;
        _metadata[_totalItems] = metadata;
        _totalItems++;
    }

    function mint(uint256 id, address to, uint256 amount) external override {
        require(id < _totalItems);
        _mint(to, id, amount, "");
    }

    function getItem(uint256 id) external view returns (DataLibrary.Item memory) {
        require(id < _totalItems);
        return _items[id];
    }

    function uri(uint256 id) public view virtual override returns (string memory) {       
        require(id < _totalItems);

        return StringHelper.encodeMetadata(
            _metadata[id].name,
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