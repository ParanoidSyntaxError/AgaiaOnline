from brownie import Cards, Characters, accounts

def main():
    cards = Cards.deploy(accounts[1], accounts[2], {"from": accounts[0]})
    print(cards.uri(10103))

    characters = Characters.deploy(accounts[1], accounts[2], {"from": accounts[0]})
