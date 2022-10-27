// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import "@chainlink/contracts/src/v0.8/interfaces/ERC677ReceiverInterface.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/CardsInterface.sol";
import "./interfaces/RandomManagerInterface.sol";
import "./interfaces/RandomRequestorInterface.sol";
import "./StringHelper.sol";

contract Cards is CardsInterface, RandomRequestorInterface, ERC1155, ERC677ReceiverInterface, Ownable {
    struct Attribute {
        string name;
        string value;
    }

    uint256 internal _totalSupply;

    // Index => SVG rectangles hash
    mapping(uint256 => Attribute) internal _bases;
    uint256 internal _totalBases;

    // Index => SVG effect
    mapping(uint256 => Attribute) internal _effects;
    uint256 internal _totalEffects;

    mapping(address => uint256) internal _mintRequestIds;

    LinkTokenInterface public immutable linkToken;
    RandomManagerInterface public immutable randomManager;

    uint256 internal constant _mintFee = 10 ** 18;

    mapping(address => uint256) internal _totalBalances;

    mapping(address => bool) internal _receivedMintFee;

    constructor(address rngManager, address link) ERC1155("") {
        linkToken = LinkTokenInterface(link);
        randomManager = RandomManagerInterface(rngManager);

        // Initial bases
        _bases[0] = Attribute("Magician", 
            "01011402140301200120130301030117121801021118010110030304110702031112020212140102101101011008010109060101020301010304010104030601050403010904010102050104030601030405010305050201060601010210011005180502031201070411010505100103061602020817010107150101");
        _bases[1] = Attribute("Knight", 
            "010114031004030311070203100801010905010206060101010408010105060101060113011902010216020303150201041301020410020304060102111202021404011612140202131601011011010106160202071501010120140312180202111801010518050208170101");
        _bases[2] = Attribute("Chaos", 
            "0101030101020120012203010302012014010122120101220522070105010701050201030405010104080101051901030418010104150101050901060702020110020103090301010603010111050101110801011009010611150101111801011019010309200101062001010721020106100104071102020910010406050404100601020704020105060102070902010615040405160102071402011016010207190201");
        _bases[3] = Attribute("Death", 
            "0101140201211402010304010104020101050102110304011304020114050102011001021410010202120101011301081312010114130108031102030512010206120101111102030912020110130101071402020215020612150206041501011115010105160102061801011016010209180101071702010719020104200301092003011119010104190101");

        _totalBases = 4;

        // Initial effects
        _effects[0] = Attribute("Common", 
            "<rect fill='#ffffff' x='00' y='00' width='16' height='24'/>");
        _effects[1] = Attribute("Foil", 
            "<defs><linearGradient id='foil' x1='50%' y1='0%' x2='50%' y2='100%'><stop offset='0%' stop-color='#01FF89'><animate attributeName='stop-color' values='#01FF89;#3EAFC4;#7A5FFF;01FF89;' dur='4s' repeatCount='indefinite'/></stop><stop offset='100%' stop-color='#7A5FFF'><animate attributeName='stop-color' values='#7A5FFF;#01FF89;#3EAFC4;7A5FFF;' dur='4s' repeatCount='indefinite'/></stop></linearGradient></defs><rect fill='url(#foil)' x='-16' y='-4' width='32' height='36' transform='rotate(325)'/>");
    
        _totalEffects = 2;
    }

    function addBases(string[] memory names, string[] memory values) external onlyOwner {
        require(names.length == values.length);

        for(uint256 i = 0; i < names.length; i++) {
            _bases[_totalBases + i] = Attribute(names[i], values[i]);
        }

        _totalBases += names.length;
    }

    function addEffects(string[] memory names, string[] memory values) external onlyOwner {
        require(names.length == values.length);

        for(uint256 i = 0; i < names.length; i++) {
            _effects[_totalEffects + i] = Attribute(names[i], values[i]);
        }

        _totalEffects += names.length;
    }

    function _afterTokenTransfer(address /*operator*/, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory /*data*/) internal override {
        for(uint256 i = 0; i < ids.length; i++) {
            _totalBalances[from] -= amounts[i];
            _totalBalances[to] += amounts[i];
        }
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        uint256 base = id % 100;
        require(base < _totalBases);
        uint256 effect = (id / 100) - 100;
        require(effect < _totalEffects);

        string memory svgHeader = "<svg xmlns='http://www.w3.org/2000/svg' id='block-hack' preserveAspectRatio='xMinYMin meet' viewBox='0 0 16 24'><style>#block-hack{shape-rendering: crispedges;}</style>";

        return StringHelper.encodeMetadata(
            string(abi.encodePacked(_bases[base].name, " (", _effects[effect].name, ")")),
            "Description", 
            string(abi.encodePacked(svgHeader, _effects[effect].value, StringHelper.hashToSvg(_bases[base].value), "</svg>")), 
            "Attributes"
        );
    }

    function totalBalance(address account) external view returns (uint256) {
        return _totalBalances[account];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function mintFee() external pure returns (uint256) {
        return _mintFee;
    }

    function randomCount(uint256 /*dataType*/) external pure override returns (uint32) {
        return 2;
    }

    function onTokenTransfer(address /*sender*/, uint256 amount, bytes calldata data) external override {
        require(msg.sender == address(linkToken));
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
            linkToken.transferFrom(sender, address(this), _mintFee);
        }

        _mintRequestIds[sender] = requestId;
    }

    function claim() external {
        require(_mintRequestIds[msg.sender] > 0);
        require(randomManager.requestResponded(_mintRequestIds[msg.sender]));

        uint256 baseRoll = randomManager.randomResponse(_mintRequestIds[msg.sender])[0] % _totalBases;
        uint256 effectRoll = randomManager.randomResponse(_mintRequestIds[msg.sender])[1] % _totalEffects;

        uint256 id = ((effectRoll * 100) + baseRoll) + 10000;

        _mint(msg.sender, id, 1, "");
        _totalSupply++;

        _mintRequestIds[msg.sender] = 0;
    }

    function withdrawTokens(address token, address receiver) external onlyOwner {
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(address(this)) > 0);
        erc20.transfer(receiver, erc20.balanceOf(address(this)));
    }
}