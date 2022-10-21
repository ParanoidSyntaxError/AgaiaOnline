// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ItemsInterface.sol";
import "./StringHelper.sol";

contract Items is ItemsInterface, ERC1155, Ownable {
    struct Attribute {
        string name;
        string value;
    }

    // Address => ID => Balance
    mapping(address => mapping(uint256 => uint256)) internal _totalBalances;

    // ID => Supply
    mapping(uint256 => uint256) internal _totalSupplys;
    uint256 internal _supply;

    // Index => SVG rectangles hash
    mapping(uint256 => Attribute) internal _bases;
    uint256 internal _totalBases;

    // Index => SVG effect
    mapping(uint256 => Attribute) internal _effects;
    uint256 internal _totalEffects;

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

        _totalBases = 4;


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

    function _afterTokenTransfer(address /*operator*/, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory /*data*/) internal override {
        for(uint256 i = 0; i < ids.length; i++) {
            _totalBalances[from][ids[i]] -= amounts[i];
            _totalBalances[to][ids[i]] += amounts[i];
        }
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        uint256 base = id % 100;
        require(base < _totalBases);
        uint256 effect = (id / 100) - 100;
        require(effect < _totalEffects);

        string memory svgHeader = "<svg xmlns='http://www.w3.org/2000/svg' id='block-hack' preserveAspectRatio='xMinYMin meet' viewBox='0 0 24 24'><style>#block-hack{shape-rendering: crispedges;}</style>";

        return StringHelper.encodeMetadata(
            string(abi.encodePacked(_bases[base].name, " (", _effects[effect].name, ")")),
            "Description", 
            string(abi.encodePacked(svgHeader, _effects[effect].value, StringHelper.hashToSvg(_bases[base].value), "</svg>")), 
            "Attributes"
        );
    }
}