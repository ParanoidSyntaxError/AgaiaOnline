// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./token/CardsERC1155.sol";
import "./SvgArt.sol";

contract Cards is CardsERC1155, SvgArt {
    uint256 internal _totalSupply;

    mapping(address => uint256) internal _totalBalances;

    address public immutable game;

    constructor(address gameContract, address owner) CardsERC1155("") {
        game = gameContract;
        _transferOwnership(owner);
    }

    modifier onlyGame {
        require(msg.sender == game);
        _;
    }

    function mint(address receiver, uint256[2] memory seeds, uint256 amount) external override onlyGame {
        _mint(receiver, _randomId(seeds), amount, "");
        _totalSupply += amount;
    }

    function totalBalanceOf(address account) external view override returns (uint256) {
        return _totalBalances[account];
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return StringHelper.encodeMetadata(
            _name(id),
            "Description", 
            _svg(id, "<svg xmlns='http://www.w3.org/2000/svg' id='block-hack' preserveAspectRatio='xMinYMin meet' viewBox='0 0 16 24'><style>#block-hack{shape-rendering: crispedges;}</style>"), 
            "Attributes"
        );
    }

    function _afterTokenTransfer(address /*operator*/, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory /*data*/) internal override {
        for(uint256 i = 0; i < ids.length; i++) {
            if(from != address(0)) {
                _totalBalances[from] -= amounts[i];
            }
            _totalBalances[to] += amounts[i];
        }
    }
}