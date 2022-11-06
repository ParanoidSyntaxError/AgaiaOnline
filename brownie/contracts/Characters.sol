// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./token/CharactersERC721.sol";
import "./SvgArt.sol";

contract Characters is CharactersERC721, SvgArt {
    mapping(uint256 => DataLibrary.TokenMetadata) internal _metadata;
    uint256 internal _totalSupply;

    address public immutable game;

    constructor(address gameContract, address owner) CharactersERC721("name", "symbol") {
        game = gameContract;
        _transferOwnership(owner);
    }

    modifier onlyGame {
        require(msg.sender == game);
        _;
    }

    function mint(address receiver, uint256[2] memory seeds, string memory name) external override onlyGame returns (uint256) {
        _mint(receiver, _totalSupply);
        _metadata[_totalSupply] = DataLibrary.TokenMetadata(name, _randomId(seeds));
        _totalSupply++;

        return _totalSupply - 1;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {       
        return StringHelper.encodeMetadata(
            _name(id),
            "Description", 
            _svg(id, "<svg xmlns='http://www.w3.org/2000/svg' id='block-hack' preserveAspectRatio='xMinYMin meet' viewBox='0 0 32 32'><style>#block-hack{shape-rendering: crispedges;}</style>"), 
            "Attributes"
        );
    }
}