// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@vittominacori/contracts/token/ERC1363/ERC1363.sol";
import "../interfaces/GoldPieceInterface.sol";

contract GoldPiece is GoldPieceInterface, ERC1363 {
    using Address for address;

    address public immutable game;

    constructor(address gameContract) ERC20("Gold Piece", "GP") {
        game = gameContract;
    }

    modifier onlyGame {
        require(msg.sender == game);
        _;
    }

    function mint(address account, uint256 amount) external onlyGame {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyGame {
        _burn(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
