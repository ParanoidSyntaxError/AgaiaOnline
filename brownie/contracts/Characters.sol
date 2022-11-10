// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./interfaces/CharactersInterface.sol";

import "./SvgArt.sol";

contract Characters is CharactersInterface, ERC721, SvgArt {
   

    mapping(uint256 => DataLibrary.TokenMetadata) internal _metadata;
    uint256 internal _totalSupply;

    address public immutable game;


    constructor(address gameContract, address owner) ERC721("", "") {
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

    function mint(address receiver, uint256[2] memory seeds, string memory characterName) external override onlyGame returns (uint256) {
        _mint(receiver, _totalSupply);
        _metadata[_totalSupply] = DataLibrary.TokenMetadata(characterName, _randomId(seeds));
        _totalSupply++;

        return _totalSupply - 1;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {       
        _requireMinted(id);

        return StringHelper.encodeMetadata(
            _name(id),
            "Description", 
            _svg(id, "<svg xmlns='http://www.w3.org/2000/svg' id='block-hack' preserveAspectRatio='xMinYMin meet' viewBox='0 0 32 32'><style>#block-hack{shape-rendering: crispedges;}</style>"), 
            "Attributes"
        );
    }
}
