// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import "@chainlink/contracts/src/v0.8/interfaces/ERC677ReceiverInterface.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./token/CardsERC1155.sol";
import "./interfaces/RandomManagerInterface.sol";
import "./interfaces/RandomRequestorInterface.sol";
import "./SvgArt.sol";

contract Cards is CardsERC1155, RandomRequestorInterface, SvgArt, ERC677ReceiverInterface {
    uint256 internal _totalSupply;

    mapping(address => uint256) internal _mintRequestIds;

    LinkTokenInterface public immutable link;
    RandomManagerInterface public immutable randomManager;

    uint256 internal constant _mintFee = 10 ** 18;

    mapping(address => uint256) internal _totalBalances;

    mapping(address => bool) internal _receivedMintFee;

    constructor(address randomManagerContract, address linkContract) CardsERC1155("") {
        randomManager = RandomManagerInterface(randomManagerContract);
        link = LinkTokenInterface(linkContract);
    }

    function totalBalanceOf(address account) external view override returns (uint256) {
        return _totalBalances[account];
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function mintFee() external pure override returns (uint256) {
        return _mintFee;
    }

    function randomCount(uint256 /*dataType*/) external pure override returns (uint32) {
        return 2;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return StringHelper.encodeMetadata(
            _name(id),
            "Description", 
            _svg(id, "<svg xmlns='http://www.w3.org/2000/svg' id='block-hack' preserveAspectRatio='xMinYMin meet' viewBox='0 0 16 24'><style>#block-hack{shape-rendering: crispedges;}</style>"), 
            "Attributes"
        );
    }

    function onTokenTransfer(address /*sender*/, uint256 amount, bytes calldata data) external override {
        require(msg.sender == address(link));
        require(amount >= _mintFee);

        address mintReceiver = abi.decode(data, (address));

        _receivedMintFee[mintReceiver] = true;
    }

    function onRequestRandom(address sender, uint256 requestId, uint256 /*dataType*/, bytes memory /*data*/) external override {
        require(msg.sender == address(randomManager));
        require(_mintRequestIds[sender] == 0);

        if(_receivedMintFee[sender]) {
            _receivedMintFee[sender] = false;
        } else {
            link.transferFrom(sender, address(this), _mintFee);
        }

        _mintRequestIds[sender] = requestId;
    }

    function claim() external override returns (uint256) {
        require(_mintRequestIds[msg.sender] > 0);
        require(randomManager.requestResponded(_mintRequestIds[msg.sender]));

        uint256 baseRoll = randomManager.randomResponse(_mintRequestIds[msg.sender])[0] % _totalBases;
        uint256 effectRoll = randomManager.randomResponse(_mintRequestIds[msg.sender])[1] % _totalEffects;

        uint256 id = ((effectRoll * 100) + baseRoll) + 10000;

        _mint(msg.sender, id, 1, "");
        _totalSupply++;

        _mintRequestIds[msg.sender] = 0;

        return _totalSupply - 1;
    }

    function withdrawTokens(address token, address receiver) external override onlyOwner returns (uint256) {
        IERC20 erc20 = IERC20(token);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance > 0);
        erc20.transfer(receiver, balance);
        return balance;
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