// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract GamePass is ERC1155 {
    uint256 internal _supply;

    // ID => SVG rectangles hash
    mapping(uint256 => string) internal _tokenURIs;
    uint256 internal _totalTokenURIs;

    address internal _admin;
    address internal _minter;
    address internal _developer;

    mapping(uint256 => uint256) internal _mintReceipts;

    constructor() ERC1155("") {
        _admin = msg.sender;
        _minter = msg.sender;
        _developer = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin);
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == _minter);
        _;
    }

    modifier onlyDeveloper() {
        require(msg.sender == _developer);
        _;
    }

    function setAdmin(address account) external onlyAdmin {
        _admin = account;
    }

    function setMinter(address account) external onlyAdmin {
        _minter = account;
    }

    function setDeveloper(address account) external onlyAdmin {
        _developer = account;
    }

    function mint(address receiver, uint256 id) external onlyMinter {
        require(id < _totalTokenURIs);
        _mint(receiver, id, 1, "");
        _supply++;
    }

    function addTokenUri(string calldata uri) external onlyDeveloper {
        _tokenURIs[_totalTokenURIs] = uri;
        _totalTokenURIs++;
    }

    function requestMint() external {
        
    }

    function claimMint() external {
        
    }
}