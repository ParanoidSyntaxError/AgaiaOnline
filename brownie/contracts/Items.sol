// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ItemsInterface.sol";
import "./StringHelper.sol";

contract Items is ItemsInterface, ERC1155, Ownable {
    struct Attribute {
        string name;
        string value;
    }

    struct Item {
        string name;
        uint256 svgHash;
    }

    // Index => SVG rectangles hash
    mapping(uint256 => Attribute) internal _bases;
    uint256 internal _totalBases;

    // Index => SVG effect
    mapping(uint256 => Attribute) internal _effects;
    uint256 internal _totalEffects;

    // ID => Item
    mapping(uint256 => Item) _items;
    uint256 internal _totalItems;

    // ID => Supply
    mapping(uint256 => uint256) internal _totalSupplys;
    uint256 internal _totalSupply;

    constructor() ERC1155("") {
        // Initial bases
        _bases[0] = Attribute("Potion", 
            "0018240609160601071702010716010115170201161601010813010315130103091206021011040111080203000024070007071117070711090801031408010315070105160701060707010608070105");
        _bases[1] = Attribute("Amulet", 
            "0000240518050601190605012007041719090115171002141707020214060402130701021409031512100202131201011213010211150101091602010815010107130102081201010911020111120101131501091216010811170107091802060817010707160108061501090005061906050801060607010607060206090501061003010611020106120101");
        _bases[2] = Attribute("Watch", 
            "00002404002024040004061618040616060405011304050106050402140504021105020206070501130705010608040114080401060902011609020106100102171001021009040108100201081101011410020115110101111101041214030116120104151601021417010110180401081702010816010107120104141904010619040106180201061601021618020117160102");
        _bases[3] = Attribute("Cracked Orb", 
            "000024060018240600060612180606121417040106170401060604011406040106070103061401031707010317140103071601011616010116070101070701010907010110080102081401010913030111140101121201011311010114090102150801011511010116120102");
        _bases[4] = Attribute("Odd Skull", 
            "0000240600172407000607111706071107060301070701021406030116070102071401030916010111160101131404031513020109130102081101021210010411110302");
        _bases[5] = Attribute("Holy Shield", 
            "000024060019240500060613180606130806030113060301061805011318050106170401141704010616030115160301061402021614020206110103171101031108020809100602");
        _bases[6] = Attribute("Crystal Ball", 
            "000024060018240600060612180606120606040114060401061704011417040117140103170701030607010306140103071601011616010116070101070701011016040114150201081502010814010115140101161001040710010408080204140802040912060110130401100704021209020210110401");
        _bases[7] = Attribute("Candle", 
            "000024040019240500040815170407151618010115170101160401131504011208040214100401021204010211060101100701021207010211080101130402131317010110160301");

        _totalBases = 8;

        // Initial effects
        _effects[0] = Attribute("Common", 
            "<rect fill='#ffffff' x='00' y='00' width='24' height='24'/>");

        _totalEffects = 1;
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

    function uri(uint256 id) public view virtual override returns (string memory) {
        uint256 base = _items[id].svgHash % 100;
        require(base < _totalBases);
        uint256 effect = (_items[id].svgHash / 100) - 100;
        require(effect < _totalEffects);

        string memory svgHeader = "<svg xmlns='http://www.w3.org/2000/svg' id='block-hack' preserveAspectRatio='xMinYMin meet' viewBox='0 0 24 24'><style>#block-hack{shape-rendering: crispedges;}</style>";

        return StringHelper.encodeMetadata(
            _items[id].name,
            "Description", 
            string(abi.encodePacked(svgHeader, _effects[effect].value, StringHelper.hashToSvg(_bases[base].value), "</svg>")), 
            "Attributes"
        );
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function itemSupply(uint256 id) external view returns (uint256) {
        return _totalSupplys[id];
    }
}