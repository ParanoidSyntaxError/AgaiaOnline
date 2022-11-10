// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "./interfaces/ItemsInterface.sol";

import "./SvgArt.sol";

contract Items is ItemsInterface, ERC1155, SvgArt {

    // ID => Item
    mapping(uint256 => DataLibrary.TokenMetadata) _metadata;
    uint256 internal _totalItems;

    // ID => Supply
    mapping(uint256 => uint256) internal _totalSupplys;
    uint256 internal _totalSupply;

    address public immutable game;


    constructor(address gameContract, address owner) ERC1155("") {
        game = gameContract;
        _transferOwnership(owner);
    }

    modifier onlyGame {
        require(msg.sender == game);
        _;
    }

    function approveAllOf(address account) external override onlyGame {
        _setApprovalForAll(account, game, true);
    }

    function addItems(DataLibrary.TokenMetadata[] memory metadata) external override onlyGame {
        for(uint256 i = 0; i < metadata.length; i++) {
            _metadata[_totalItems + i] = metadata[i];
        }

        _totalItems += metadata.length;
    }

    function mint(uint256 id, address to, uint256 amount) external override onlyGame {
        require(id < _totalItems);
        _mint(to, id, amount, "");
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
