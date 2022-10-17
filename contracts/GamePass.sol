// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./IRandomManager.sol";
import "./IRandomRequestor.sol";
import "./StringHelper.sol";

contract GamePass is ERC1155, IRandomRequestor, Ownable {
    struct Attribute {
        string name;
        string value;
    }

    uint256 internal _supply;

    // Index => SVG rectangles hash
    mapping(uint256 => Attribute) internal _baseHashes;
    uint256 internal _totalBaseHashes;

    // Index => SVG effect
    mapping(uint256 => Attribute) internal _effectSvgs;
    uint256 internal _totalEffectSvgs;

    mapping(address => uint256) internal _mintRequestIds;

    LinkTokenInterface public immutable linkToken;
    IRandomManager public immutable randomManager;

    uint256 internal constant _mintFee = 10 ** 18;

    constructor(address rngManager, address link) ERC1155("") {
        linkToken = LinkTokenInterface(link);
        randomManager = IRandomManager(rngManager);

        // Initial bases
        _baseHashes[0] = Attribute("Magician", 
            "01011402140301200120130301030117121801021118010110030304110702031112020212140102101101011008010109060101020301010304010104030601050403010904010102050104030601030405010305050201060601010210011005180502031201070411010505100103061602020817010107150101");
        _baseHashes[1] = Attribute("Knight", 
            "010114031004030311070203100801010905010206060101010408010105060101060113011902010216020303150201041301020410020304060102111202021404011612140202131601011011010106160202071501010120140312180202111801010518050208170101");
        _baseHashes[2] = Attribute("Chaos", 
            "0101030101020120012203010302012014010122120101220522070105010701050201030405010104080101051901030418010104150101050901060702020110020103090301010603010111050101110801011009010611150101111801011019010309200101062001010721020106100104071102020910010406050404100601020704020105060102070902010615040405160102071402011016010207190201");
        _baseHashes[3] = Attribute("Death", 
            "0101140201211402010304010104020101050102110304011304020114050102011001021410010202120101011301081312010114130108031102030512010206120101111102030912020110130101071402020215020612150206041501011115010105160102061801011016010209180101071702010719020104200301092003011119010104190101");

        // Initial effects
        _effectSvgs[0] = Attribute(" (Common)", 
            "<rect fill='#ffffff' x='00' y='00' width='16' height='24'/>");
        _effectSvgs[1] = Attribute(" (Foil)", 
            "<defs><linearGradient id='foil' x1='50%' y1='0%' x2='50%' y2='100%'><stop offset='0%' stop-color='#01FF89'><animate attributeName='stop-color' values='#01FF89;#3EAFC4;#7A5FFF;01FF89;' dur='4s' repeatCount='indefinite'/></stop><stop offset='100%' stop-color='#7A5FFF'><animate attributeName='stop-color' values='#7A5FFF;#01FF89;#3EAFC4;7A5FFF;' dur='4s' repeatCount='indefinite'/></stop></linearGradient></defs><rect fill='url(#foil)' x='-16' y='-4' width='32' height='36' transform='rotate(325)'/>");
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        uint256 base = id % 100;
        require(base < _totalBaseHashes);
        uint256 effect = (id / 100) - 100;
        require(effect < _totalEffectSvgs);

        string memory svgHeader = "<svg xmlns='http://www.w3.org/2000/svg' id='block-hack' preserveAspectRatio='xMinYMin meet' viewBox='0 0 16 24'><style>#block-hack{shape-rendering: crispedges;}</style>";

        string memory svgRects = _effectSvgs[effect].value;
        
        for(uint256 i = 0; i < StringHelper.stringLength(_baseHashes[base].value) / 8; i++) {
            svgRects = string(abi.encodePacked(
                    svgRects, 
                    "<rect fill='#000000' x='", StringHelper.subString(_baseHashes[base].value, i * 8, (i * 8) + 2), 
                    "' y='", StringHelper.subString(_baseHashes[base].value, (i * 8) + 2, (i * 8) + 4), 
                    "' width='", StringHelper.subString(_baseHashes[base].value, (i * 8) + 4, (i * 8) + 6), 
                    "' height='", StringHelper.subString(_baseHashes[base].value, (i * 8) + 6, (i * 8) + 8), 
                    "'/>"
            ));
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(string(
                abi.encodePacked(
                    '{"name": "', 
                    _baseHashes[base].name, _effectSvgs[effect].name,
                    '", "description": "',
                    //Description 
                    '", "image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(string(abi.encodePacked(svgHeader, svgRects, "</svg>")))),
                    '", "attributes":',
                    //Attributes
                    "}"
                )
            )))
        )); 
    }

    function totalSupply() external view returns (uint256) {
        return _supply;
    }

    function mintFee() external pure returns (uint256) {
        return _mintFee;
    }

    function randomCount(uint256 /*dataType*/) external pure override returns (uint32) {
        return 2;
    }

    function onRequestRandom(address sender, uint256 requestId, uint256 /*dataType*/, bytes memory /*data*/) external override {
        require(_mintRequestIds[sender] == 0);

        linkToken.transferFrom(sender, address(this), _mintFee);

        _mintRequestIds[sender] = requestId;
    }

    function claimMint() external {
        require(_mintRequestIds[msg.sender] > 0);
        require(randomManager.requestResponded(_mintRequestIds[msg.sender]));

        uint256 baseRoll = randomManager.randomResponse(_mintRequestIds[msg.sender])[0] % _totalBaseHashes;
        uint256 effectRoll = randomManager.randomResponse(_mintRequestIds[msg.sender])[1] % _totalEffectSvgs;

        uint256 id = ((effectRoll * 100) + baseRoll) + 10000;

        _mint(msg.sender, id, 1, "");
        _supply++;
    }

    function withdrawTokens(address token, address receiver) external onlyOwner {
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(address(this)) > 0);
        erc20.transfer(receiver, erc20.balanceOf(address(this)));
    }
}