from brownie import Cards, Characters, Items, accounts

def main():
    cards = Cards.deploy(accounts[1], accounts[2], {"from": accounts[0]})
    characters = Characters.deploy(accounts[1], accounts[2], {"from": accounts[0]})
    items = Items.deploy({"from": accounts[0]})
    print(items.uri(10000))
