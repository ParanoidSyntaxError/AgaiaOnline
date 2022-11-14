from brownie import Cards, Characters, Items, Game, RandomManager, LinkToken, RandomHelper, StatsLibrary, DataLibrary, ActionsV01, accounts
from eth_abi import encode
import random

class deploy:
    def linkToken(deployer):
        return LinkToken.deploy({"from": deployer})
        
    def randomManager(deployer, linkToken):
        return RandomManager.deploy(linkToken, accounts[0], {"from": deployer})

    def fufillRandomRequest(randomManager, id, count):
        responses = [random.randint(0, 10**24) for _ in range(count)]
        return randomManager.debugFulfillRandomWords(id, responses, {"from": accounts[9]})

    def game(deployer, randomManager):
        # Deploy libraries
        RandomHelper.deploy({"from": deployer})
        DataLibrary.deploy({"from": deployer})
        StatsLibrary.deploy({"from": deployer})

        game = Game.deploy(randomManager, {"from": deployer})

        # Setup ActionsV01
        actionsV01 = ActionsV01.deploy({"from": deployer})
        game.addActions(actionsV01, {"from": deployer})

        # Setup traps
        game = deploy.setupTraps(deployer, game)

        # Setup enemies
        game = deploy.setupEnemies(deployer, game)

        # Setup cards
        cards = Cards.at(game.cardTokens())
        cards = deploy.setupCards(deployer, cards)

        # Setup characters
        characters = Characters.at(game.characterTokens())
        characters = deploy.setupCharacters(deployer, characters)

        # Setup items
        items = Items.at(game.itemTokens())
        (game, items) = deploy.setupItems(deployer, game, items)

        # Setup dungeons
        game = deploy.setupDungeons(deployer, game)

        return (game, cards, characters, items)

    def setupCards(admin, cards):
        cards.addBases(
            [
                (
                    "Magician",
                    "01011402140301200120130301030117121801021118010110030304110702031112020212140102101101011008010109060101020301010304010104030601050403010904010102050104030601030405010305050201060601010210011005180502031201070411010505100103061602020817010107150101"
                ),
                (
                    "Knight",
                    "010114031004030311070203100801010905010206060101010408010105060101060113011902010216020303150201041301020410020304060102111202021404011612140202131601011011010106160202071501010120140312180202111801010518050208170101"
                ),
                (
                    "Chaos",
                    "0101030101020120012203010302012014010122120101220522070105010701050201030405010104080101051901030418010104150101050901060702020110020103090301010603010111050101110801011009010611150101111801011019010309200101062001010721020106100104071102020910010406050404100601020704020105060102070902010615040405160102071402011016010207190201"
                ),
                (
                    "Death",
                    "0101140201211402010304010104020101050102110304011304020114050102011001021410010202120101011301081312010114130108031102030512010206120101111102030912020110130101071402020215020612150206041501011115010105160102061801011016010209180101071702010719020104200301092003011119010104190101"
                )
            ],
            {"from": admin}
        )
        cards.addEffects(
            [
                (   
                    "Common", 
                    "<rect fill='#ffffff' x='00' y='00' width='16' height='24'/>"
                ),
                (
                    "Enchanted", 
                    "<defs><linearGradient id='foil' x1='50%' y1='0%' x2='50%' y2='100%'><stop offset='0%' stop-color='#01FF89'><animate attributeName='stop-color' values='#01FF89;#3EAFC4;#7A5FFF;01FF89;' dur='4s' repeatCount='indefinite'/></stop><stop offset='100%' stop-color='#7A5FFF'><animate attributeName='stop-color' values='#7A5FFF;#01FF89;#3EAFC4;7A5FFF;' dur='4s' repeatCount='indefinite'/></stop></linearGradient></defs><rect fill='url(#foil)' x='-16' y='-4' width='32' height='36' transform='rotate(325)'/>"
                )
            ], 
            {"from": admin}
        )
        return cards

    def setupCharacters(admin, characters):
        characters.addBases(
            [
                (
                    "Reaper", 
                    "2900033030300201313101012530040225290301252602032422020424210101261901032517010227170104271401022813011527230103222202012121020122200101182406031823030118210202172002011619020118270505023014020329130103280501042703010526010109270702102505021124040112230401132203011221040113180203141605031917020320200101151503011614020117130101181202022113040222150201111118012800011026080201220705012306030121080201200902011910020127000106230004052000030316000402000016010001120100021001000309010004080109040201110501031405030115040109130604061207020914120103000510061006010500110501001203010013010109110101081202010713021409150110101601081120010311150202111701010016011601170113021601120315011204170109041501010514011106140112220401022005020219060202180702021708020217100101"
                ),
                (
                    "Aristocrat",
                    "00300402043102010024020400230101022502030426020306270203073001010019010201200102022101020322010204230102062201040520010304200101031901010218010100170201001501010114020203150201021602010514020107120102070701030808010409100102000003130013010103000111040001090504010305000103060002040800010309000201100401010704020108050201090602011007010111080103111301011212010113130101141101011307010414060301170502011904030122050101230601022407010125080102240901052310010117100401160903011811010124140203231501032215010120170201221801010416100207150501081403010912020205180601061902010919020110200201112102010720020209210101082203101124010812250107122201021324050115250101132602021328010215270401162901011929010120300102212801022230010223280102243001022727010529280204312901033000022731270101282201052720010426190103251901012418010122190204242001042522010326240103192603012225010123240101212001031621050313220302121804011417010113190401152003012610010226120202271401022616010125170201271701022813010729000122280001122700010826000105250001032400010223000101"
                ),
                (
                    "Knight",
                    "3129010330280103292701032824010527300202262902022722010626190108242102012418010221180102181801022513010522130105191301052712010527180103281701032900022231000123191003012207040426090102270002112600010126020103250101022300020223030101240401012305010224060101141003011511010416200203161401061722020519230703192702042127050326280101172802041629010313310101162501031521010214250207142401011323010512230103112301021023010100200601062102010822010112110101131201031213010111120101111401011215030709160307122201011015010108120203101301010715020308180101000002160204011203020102040401020505010206060102070703020808040209100202111001010306011104080106050901040610010207110101041603010517020107001601070108010702060108030301090403011502020114030201130403051606010317080101002302010224030105250201072602010927010110280102113001020025020702260306052702050728020409300102"
                ),
                (
                    "Apprentice",
                    "31000130300001292829020328000228253001022331010122290102212801012027010119260101172502011624010117220202192301022023010321220105222201062323010624260105133105011430030114280202132602021225020111240201102302010822020106210201002006010731010106290102052801010427010102260201000001160115060107140101021404010413010102160401061702010815040212170201081803011017010109190301112003011419010113210201152001011521020201000114020002130400021206110103060701020600010607000105080401010800010309000102120102011701020119010202100010010903020110020701150303011104040109050901180401011905010118060101200302012104010121000701230105012402040124030101260302022705010427100219070905030812030209140201120806011407030112090401121003011311020213130101171201011813040119140201241301012006020121070201220804012507010123090201241001012609011625130111241501082318010422180101202003012221010108080301070607010707010109070301"
                )
            ], 
            {"from": admin}
        )
        characters.addEffects(
            [
                (
                    "Common", 
                    "<rect fill='#ffffff' x='00' y='00' width='32' height='32'/>"
                ),
                (
                    "Enchanted",
                    "<defs><linearGradient id='foil' x1='50%' y1='0%' x2='50%' y2='100%'><stop offset='0%' stop-color='#01FF89'><animate attributeName='stop-color' values='#01FF89;#3EAFC4;#7A5FFF;01FF89;' dur='4s' repeatCount='indefinite'/></stop><stop offset='100%' stop-color='#7A5FFF'><animate attributeName='stop-color' values='#7A5FFF;#01FF89;#3EAFC4;7A5FFF;' dur='4s' repeatCount='indefinite'/></stop></linearGradient></defs><rect fill='url(#foil)' x='-20' y='-8' width='48' height='60' transform='rotate(325)'/>"
                )
            ], 
            {"from": admin}
        )
        return characters

    def setupItems(admin, game, items):
        items.addBases(
            [
                (
                    "Sword",
                    "00002405170507191609011500051602000715020009140200111301001212021014010109150101101601011115010100140903001708010018070607190905081808010917070112140403131303011412020115110101"
                ),
                (
                    "Scythe",
                    "000006240620180419000520071912010818110109171001101609011115080112140701131306011412050115110401161003011709010118000109170001081500020710000506080002070600020806080111070901090808010909080108100701081107010712070106130801041408010315090101"
                ),
                (
                    "Cracked Orb",
                    "000024060018240600060612180606121417040106170401060604011406040106070103061401031707010317140103071601011616010116070101070701010907010110080102081401010913030111140101121201011311010114090102150801011511010116120102"
                )
            ], 
            {"from": admin})
        items.addEffects(
            [
                (
                    "Common", 
                    "<rect fill='#ffffff' x='00' y='00' width='24' height='24'/>"
                )
            ], 
            {"from": admin}
        )

        game.addItems(
            [
                (2, ([0],[0],[encode(['int256'], [-3])],[False])),
                (2, ([0],[0],[encode(['int256'], [-7])],[False])),
                (5, ([0],[0],[encode(['int256'], [5])],[True]))
            ], 
            [
                ("Sword", 10000),
                ("Scythe", 10001),
                ("Cracked Orb", 10002)
            ], 
            {"from": admin}
        )

        return game, items

    def setupTraps(admin, game):
        game.addTraps(
            [
                ([0], [0], [encode(['int256'], [-1])], [False])
            ], 
            {"from": admin}
        )
        return game

    def setupEnemies(admin, game):
        game.addEnemies(
            [
                (
                    (3, 5, [1,1,1,1,1,1], []), 
                    [100], 
                    ([0], [0], [encode(['int256'], [-5])], [False])
                )
            ], 
            {"from": admin}
        )
        return game

    def setupDungeons(admin, game):
        game.addDungeons(
            [
                (
                    [30, 30, 30, 0, 10],
                    [[40,20,40],[100],[100],[100],[100]],
                    [[0,1,2],[0],[0],[0],[0]],
                    5
                )
            ],
            {"from": admin}
        )
        return game

def main():
    deployer = accounts[0]

    # Deploy LINK token
    linkToken = deploy.linkToken(deployer)
    randomManager = deploy.randomManager(deployer, linkToken)

    (game, cards, characters, items) = deploy.game(deployer, randomManager)

    # Mint card
    cardMintData = "0x" + encode(['uint256', 'address', 'address', 'address', 'uint256', 'bytes'], [10**18, game.address, deployer.address, game.address, 0, b'']).hex()
    linkToken.transferAndCall(randomManager, 2 * (10 ** 18), cardMintData, {"from": deployer})
    deploy.fufillRandomRequest(randomManager, 1, game.randomCount(0))
    game.claimCard({"from": deployer})

    # Mint character
    randomManager.requestRandom(0, 0, accounts[9], accounts[9], game, 1, "", {"from": deployer})
    deploy.fufillRandomRequest(randomManager, 2, game.randomCount(1))
    game.claimCharacter("John the Brave", {"from": deployer})

    # Raid
    randomManager.requestRandom(0, 0, accounts[9], accounts[9], game, 2, encode(['uint256', 'uint256', 'uint256[][7]', 'uint256[][7]'], [0, 0, [[],[],[0],[],[],[],[]], [[],[],[1],[],[],[],[]]]), {"from": deployer})
    deploy.fufillRandomRequest(randomManager, 3, game.randomCount(2))
    raid = game.claimRaid(0, {"from": deployer})
    
    print(raid.events)


