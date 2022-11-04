from brownie import Cards, Characters, Items, Game, RandomManager, LinkToken, RandomHelper, StatsLibrary, DataLibrary, ActionsV01, accounts
from eth_abi import encode, decode

def main():
    admin = accounts[0]
    RandomHelper.deploy({"from": admin})
    StatsLibrary.deploy({"from": admin})
    DataLibrary.deploy({"from": admin})

    # Deploy LINK token
    linkToken = LinkToken.deploy({"from": admin})

    # Deploy RandomManager.sol
    randomManager = RandomManager.deploy(linkToken, accounts[0], {"from": admin})

    # Deploy and setup Cards.sol
    cards = Cards.deploy(randomManager, linkToken, {"from": admin})
    cards.addBases(["Magician"], ["01011402140301200120130301030117121801021118010110030304110702031112020212140102101101011008010109060101020301010304010104030601050403010904010102050104030601030405010305050201060601010210011005180502031201070411010505100103061602020817010107150101"], {"from": admin})
    cards.addEffects(["Common"], ["<rect fill='#ffffff' x='00' y='00' width='16' height='24'/>"], {"from": admin})

    # Mint card to admin address
    linkToken.approve(cards, 1000 ** 18, {"from": admin})
    randomManager.requestRandom(cards, 0, "", {"from": admin})
    randomManager.debugFulfillRandomWords(1, [5523223443373498,2389898823823478234342], {"from": admin})
    cards.claim({"from": admin})

    # Deploy Game.sol
    game = Game.deploy(cards, randomManager, {"from": admin})

    # Deploy and setup ActionsV01.sol
    actionsV01 = ActionsV01.deploy({"from": admin})
    game.addActions(actionsV01, {"from": admin})

    # Setup traps
    game.addTrap(([0], [0], [encode(['int256'], [-1])], [False]), {"from": admin})

    # Setup enemies
    game.addEnemy((3, 5, [1,1,1,1,1,1], []), [100], ([0], [0], [encode(['int256'], [-1])], [False]), {"from": admin})

    # Setup Items.sol and mint item to admin
    items = Items.at(game.items())
    items.addBases(["Holy Shield"], ["000024060019240500060613180606130806030113060301061805011318050106170401141704010616030115160301061402021614020206110103171101031108020809100602"], {"from": admin})
    items.addEffects(["Common"], ["<rect fill='#ffffff' x='00' y='00' width='24' height='24'/>"], {"from": admin})
    items.addItem((2, ([0], [0], [encode(['int256'], [-1])], [False])), ("Silk's Tower", 10000), {"from": admin})
    items.mint(0, admin, 1, {"from": admin})

    # Setup Characters.sol and mint character to admin
    characters = Characters.at(game.characters())
    characters.addBases(["Reaper"], ["2900033030300201313101012530040225290301252602032422020424210101261901032517010227170104271401022813011527230103222202012121020122200101182406031823030118210202172002011619020118270505023014020329130103280501042703010526010109270702102505021124040112230401132203011221040113180203141605031917020320200101151503011614020117130101181202022113040222150201111118012800011026080201220705012306030121080201200902011910020127000106230004052000030316000402000016010001120100021001000309010004080109040201110501031405030115040109130604061207020914120103000510061006010500110501001203010013010109110101081202010713021409150110101601081120010311150202111701010016011601170113021601120315011204170109041501010514011106140112220401022005020219060202180702021708020217100101"], {"from": admin})
    characters.addEffects(["Common"], ["<rect fill='#ffffff' x='00' y='00' width='32' height='32'/>"], {"from": admin})
    randomManager.requestRandom(characters, 0, "", {"from": admin})
    randomManager.debugFulfillRandomWords(2, [23442,5323,23526,23525,774547,32423,5226,34645,75,22222], {"from": admin})
    characters.claim("John the Brave", {"from": admin})

    # Setup dungeons
    game.addDungeon([30,30,30,0,10], [[100],[100],[100],[100],[100]], [[0],[0],[0],[0],[0]], 5, {"from": admin})

    # Approve transferFrom
    items.setApprovalForAll(game, True, {"from": admin})
    characters.setApprovalForAll(game, True, {"from": admin})

    # Raid dungeon
    randomManager.requestRandom(game, 0, encode(['uint256', 'uint256[][7]', 'uint256[][7]'], [0, [[],[],[0],[],[],[],[]], [[],[],[1],[],[],[],[]]]), {"from": admin})
    randomManager.debugFulfillRandomWords(3, [15,45,90,777777777777,142871281243], {"from": admin})
    raid = game.claim(0, {"from": admin})

    print(raid.events)