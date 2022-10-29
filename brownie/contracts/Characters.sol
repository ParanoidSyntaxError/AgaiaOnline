// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./token/CharactersERC721.sol";
import "./interfaces/RandomManagerInterface.sol";
import "./interfaces/RandomRequestorInterface.sol";
import "./interfaces/CardsInterface.sol";
import "./SvgArt.sol";

contract Characters is CharactersERC721, SvgArt, RandomRequestorInterface {
    struct Character {
        string name;
        uint256 tokenHash;
        uint256 health;
        uint256 maxHealth;
        uint256[6] stats;
        uint256[] qwerks;
    }

    struct Qwerk {
        string name;
        int256 maxHealth;
        int256[6] stats;
    }

    mapping(uint256 => Character) internal _characters;
    uint256 internal _totalCharacters;

    mapping(uint256 => Qwerk) internal _qwerks;
    uint256 internal _totalQwerks;

    uint256 internal constant HEALTH_MAX = 1000;
    uint256 internal constant STAT_MAX = 100;

    mapping(address => uint256) internal _requestIds;

    RandomManagerInterface public immutable randomManager;
  
    CardsInterface public immutable cards;
    
    address public game;

    constructor(address cardsContract, address randomManagerContract) CharactersERC721("name", "symbol") {
        cards = CardsInterface(cardsContract);
        randomManager = RandomManagerInterface(randomManagerContract);

        // Initial bases
        _bases[0] = Attribute("Apprentice", 
            "31000130300001292829020328000228253001022331010122290102212801012027010119260101172502011624010117220202192301022023010321220105222201062323010624260105133105011430030114280202132602021225020111240201102302010822020106210201002006010731010106290102052801010427010102260201000001160115060107140101021404010413010102160401061702010815040212170201081803011017010109190301112003011419010113210201152001011521020201000114020002130400021206110103060701020600010607000105080401010800010309000102120102011701020119010202100010010903020110020701150303011104040109050901180401011905010118060101200302012104010121000701230105012402040124030101260302022705010427100219070905030812030209140201120806011407030112090401121003011311020213130101171201011813040119140201241301012006020121070201220804012507010123090201241001012609011625130111241501082318010422180101202003012221010108080301070607010707010109070301");
        _bases[1] = Attribute("Knight", 
            "3129010330280103292701032824010527300202262902022722010626190108242102012418010221180102181801022513010522130105191301052712010527180103281701032900022231000123191003012207040426090102270002112600010126020103250101022300020223030101240401012305010224060101141003011511010416200203161401061722020519230703192702042127050326280101172802041629010313310101162501031521010214250207142401011323010512230103112301021023010100200601062102010822010112110101131201031213010111120101111401011215030709160307122201011015010108120203101301010715020308180101000002160204011203020102040401020505010206060102070703020808040209100202111001010306011104080106050901040610010207110101041603010517020107001601070108010702060108030301090403011502020114030201130403051606010317080101002302010224030105250201072602010927010110280102113001020025020702260306052702050728020409300102");
        _bases[2] = Attribute("Barbarian", 
            "0030030201290302022803020327030104250302052104050920010210190101102203011120010212180203131902031520020217190101181802012019030120170301211601012317030226180202272002012821010229230103282603022927030330300202232003012415010525210202252303032424030423270302222903022130030219310201192901021828010217260103162501031524010309230602122503010020010101190702031802010814010609120105101001031109010113090106140701021506010215090106160801021706010318050202200601022107010121050301220601012304010122030101210201012001010118001401160001011501010123070201240601012508010118090201201001012112010118130301171203011522020116220302172402011923040222210203192504012026030121270101051703010618020130010219280102180000011901160202021502020416010105150101041401010512010206090103070701020806010104210101261002072609010125100101251201032412010101000412011202020114010103120101050601030500020607000203070301010900030109010101260102072708010123010302250301032403010122010101");
        _bases[3] = Attribute("Aristocrat", 
            "00300402043102010024020400230101022502030426020306270203073001010019010201200102022101020322010204230102062201040520010304200101031901010218010100170201001501010114020203150201021602010514020107120102070701030808010409100102000003130013010103000111040001090504010305000103060002040800010309000201100401010704020108050201090602011007010111080103111301011212010113130101141101011307010414060301170502011904030122050101230601022407010125080102240901052310010117100401160903011811010124140203231501032215010120170201221801010416100207150501081403010912020205180601061902010919020110200201112102010720020209210101082203101124010812250107122201021324050115250101132602021328010215270401162901011929010120300102212801022230010223280102243001022727010529280204312901033000022731270101282201052720010426190103251901012418010122190204242001042522010326240103192603012225010123240101212001031621050313220302121804011417010113190401152003012610010226120202271401022616010125170201271701022813010729000122280001122700010826000105250001032400010223000101");

        _totalBases = 4;

        // Initial effects
        _effects[0] = Attribute("Common", 
            "<rect fill='#ffffff' x='00' y='00' width='32' height='32'/>");
        _effects[1] = Attribute("Foil", 
            "<defs><linearGradient id='foil' x1='50%' y1='0%' x2='50%' y2='100%'><stop offset='0%' stop-color='#01FF89'><animate attributeName='stop-color' values='#01FF89;#3EAFC4;#7A5FFF;01FF89;' dur='4s' repeatCount='indefinite'/></stop><stop offset='100%' stop-color='#7A5FFF'><animate attributeName='stop-color' values='#7A5FFF;#01FF89;#3EAFC4;7A5FFF;' dur='4s' repeatCount='indefinite'/></stop></linearGradient></defs><rect fill='url(#foil)' x='-20' y='-8' width='48' height='60' transform='rotate(325)'/>");
    
        _totalEffects = 2;

        // Initial qwerks
        _qwerks[0] = Qwerk("Coward", 0, [int256(0), 0, 0, 0, 0, 0]);
        _qwerks[1] = Qwerk("Brave", 0, [int256(0), 0, 0, 0, 0, 0]);
        _qwerks[2] = Qwerk("Clumsy", 0, [int256(0), 0, 0, 0, 0, 0]);

        _totalQwerks = 3;
    }

    modifier onlyGame {
        require(msg.sender == game);
        _;
    }

    function adminTransfer(address from, address to, uint256 id) external override onlyGame {
        _transfer(from, to, id);
    }

    function setGame(address gameContract) external override onlyOwner {
        require(game == address(0));
        game = gameContract;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalCharacters;
    }

    function totalQwerks() external view override returns (uint256) {
        return _totalQwerks;
    }

    function getCharacter(uint256 characterId) external view override returns (string memory, uint256, uint256, uint256[6] memory, uint256[] memory) {
        require(_exists(characterId));
        return (_characters[characterId].name, _characters[characterId].health, _characters[characterId].maxHealth, _characters[characterId].stats, _characters[characterId].qwerks);
    }

    function getQwerk(uint256 qwerkId) external view override returns (string memory, int256, int256[6] memory) {
        require(_isQwerkCreated(qwerkId));
        return (_qwerks[qwerkId].name, _qwerks[qwerkId].maxHealth, _qwerks[qwerkId].stats);
    }

    function randomCount(uint256 /*dataType*/) external pure override returns (uint32) {
        return 10;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {       
        return StringHelper.encodeMetadata(
            _name(id),
            "Description", 
            _svg(id, "<svg xmlns='http://www.w3.org/2000/svg' id='block-hack' preserveAspectRatio='xMinYMin meet' viewBox='0 0 32 32'><style>#block-hack{shape-rendering: crispedges;}</style>"), 
            "Attributes"
        );
    }

    function addQwerks(string[] memory names, int256[] memory maxHealths, int256[6][] memory stats) external override onlyOwner {
        require(names.length == maxHealths.length && names.length == stats.length);

        for(uint256 i = 0; i < names.length; i++) {
            _qwerks[_totalQwerks + i] = Qwerk(names[i], maxHealths[i], stats[i]);
        }

        _totalQwerks += names.length;
    }

    function onRequestRandom(address sender, uint256 requestId, uint256 /*dataType*/, bytes memory /*data*/) external override {
        require(msg.sender == address(randomManager));
        require(cards.totalBalanceOf(sender) > 0);
        require(_requestIds[sender] == 0);
        
        _requestIds[sender] = requestId;
    }

    function claim(string calldata name) external override {      
        require(bytes(name).length > 0);
        require(bytes(name).length <= 32);
        require(_requestIds[msg.sender] > 0);
        require(randomManager.requestResponded(_requestIds[msg.sender]));

        _requestIds[msg.sender] = 0;

        _newCharacter(msg.sender, name, randomManager.randomResponse(_requestIds[msg.sender]));
    }

    function _newCharacter(address receiver, string calldata name, uint256[] memory reponses) internal {
        uint256 characterId = _totalCharacters;

        // Mint token
        _safeMint(receiver, characterId);

        // Increment total supply
        _totalCharacters++;

        // Set name
        _characters[characterId].name = name;

        // Set token hash (SVG art)
        uint256 baseRoll = reponses[0] % _totalBases;
        uint256 effectRoll = reponses[1] % _totalEffects;
        _characters[characterId].tokenHash = ((effectRoll * 100) + baseRoll) + 10000;

        // Set health
        uint256 maxHealth = (reponses[2] % 26) + 50;
        _setMaxHealth(characterId, maxHealth);
        _setHealth(characterId, maxHealth);

        // Set stats
        uint256[6] memory stats;
        for(uint256 i = 0; i < stats.length; i++) {
            stats[i] = (reponses[i + 3] % 4) + 1;
        }
        _setStats(characterId, stats);
        
        // Add qwerk
        _addQwerk(characterId, reponses[9] % _totalQwerks);
    }

    function _isQwerkCreated(uint256 qwerkId) internal view returns (bool) {
        return qwerkId < _totalQwerks;
    }

    function _addQwerk(uint256 characterId, uint256 qwerkId) internal {
        require(_exists(characterId));
        require(_isQwerkCreated(qwerkId));

        _characters[characterId].qwerks.push(qwerkId);

        _addMaxHealth(characterId, _qwerks[qwerkId].maxHealth);
        _addStats(characterId, _qwerks[qwerkId].stats);
    }

    function _setStats(uint256 characterId, uint256[6] memory stats) internal {
        for(uint256 i = 0; i < stats.length; i++) {
            if(stats[i] >= STAT_MAX) {
                _characters[characterId].stats[i] = STAT_MAX;
            } else {
                if(stats[i] == 0) {
                    _characters[characterId].stats[i] = 1;
                } else {
                    _characters[characterId].stats[i] = stats[i];
                }
            }
        }
    }

    function _addStats(uint256 characterId, int256[6] memory amounts) internal {
        for(uint256 i = 0; i < amounts.length; i++) {
            if(amounts[i] != 0) {
                if(amounts[i] < 0) {
                    if(uint256(amounts[i] * -1) >= _characters[characterId].stats[i]) {
                        _characters[characterId].stats[i] = 1;
                    } else {
                        _characters[characterId].stats[i] -= uint256(amounts[i] * -1);
                    }
                }
                else {
                    if(uint256(amounts[i]) + _characters[characterId].stats[i] >= STAT_MAX) {
                        _characters[characterId].stats[i] = STAT_MAX;
                    } else {
                        _characters[characterId].stats[i] += uint256(amounts[i] * -1);
                    }
                }
            }
        }
    }

    function _setMaxHealth(uint256 characterId, uint256 maxHealth) internal {
        if(maxHealth >= HEALTH_MAX) {
            _characters[characterId].maxHealth = HEALTH_MAX;
        } else {
            if(maxHealth == 0) {
                _characters[characterId].maxHealth = 1;
            } else {
                _characters[characterId].maxHealth = maxHealth;
            }
        }
    }

    function _addMaxHealth(uint256 characterId, int256 amount) internal {
        if(amount != 0) {
            if(amount < 0) {
                if(uint256(amount * -1) >= _characters[characterId].maxHealth) {
                    _characters[characterId].maxHealth = 1;
                } else {
                    _characters[characterId].maxHealth -= uint256(amount * -1);
                }
            } else {
                if(uint256(amount * -1) + _characters[characterId].maxHealth >= HEALTH_MAX) {
                    _characters[characterId].maxHealth = HEALTH_MAX;
                } else {
                    _characters[characterId].maxHealth += uint256(amount);
                }
            }
        }
    }

    function _setHealth(uint256 characterId, uint256 health) internal {
        if(health >= _characters[characterId].maxHealth) {
            _characters[characterId].health = _characters[characterId].maxHealth;
        } else {
            _characters[characterId].health = health;
        }
    }

    function _addHealth(uint256 characterId, int256 amount) internal {
        if(amount != 0) {
            if(amount < 0) {
                if(uint256(amount * -1) >= _characters[characterId].health) {
                    _characters[characterId].health = 0;
                } else {
                    _characters[characterId].health -= uint256(amount * -1);
                }
            } else {
                if(uint256(amount * -1) + _characters[characterId].health >= _characters[characterId].maxHealth) {
                    _characters[characterId].health = _characters[characterId].maxHealth;
                } else {
                    _characters[characterId].health += uint256(amount * -1);
                }
            }
        }
    }
}