from brownie import Game, accounts

def main():
    game = Game.deploy(accounts[1], accounts[2], {"from": accounts[0]})
