const connectButton = document.getElementById("btn-connect");
connectButton.onclick = requestAccounts;

const requestCardButton = document.getElementById("btn-requestcard");
requestCardButton.onclick = requestCard;
const claimCardButton = document.getElementById("btn-claimcard");
claimCardButton.onclick = claimCard;

const requestCharacterButton = document.getElementById("btn-requestcharacter");
requestCharacterButton.onclick = requestCharacter;
const inputName = document.getElementById("input-name");
const claimCharacterButton = document.getElementById("btn-claimcharacter");
claimCharacterButton.onclick = claimCharacter;

const requestRaidButton = document.getElementById("btn-requestraid");
requestRaidButton.onclick = requestRaid;
const claimRaidButton = document.getElementById("btn-claimraid");
claimRaidButton.onclick = claimRaid;

const charactersParent = document.getElementById("div-chars");
const itemsParent = document.getElementById("div-items");

const abi = ethers.utils.defaultAbiCoder;

var provider;
var accounts;
var signer;

var ownedItems;
var ownedCharacters;

var selectedCharacter;
var selectedItem;

const gameAddress = "0x4DC9E9644CC8D86D61bcE519714F9F7195f098Bd";
const rngAddress = "0xaF06d4db46887Cd476Cd14E037cA7c0747714E52";
const linkAddress = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";

const gameAbi = [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "randomManagerContract",
				"type": "address"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "previousOwner",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "newOwner",
				"type": "address"
			}
		],
		"name": "OwnershipTransferred",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "characterId",
				"type": "uint256"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "owner",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256[]",
				"name": "eventLog",
				"type": "uint256[]"
			}
		],
		"name": "Raid",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "actions",
				"type": "address"
			}
		],
		"name": "addActions",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "uint256[5]",
						"name": "encounterChances",
						"type": "uint256[5]"
					},
					{
						"internalType": "uint256[][5]",
						"name": "chances",
						"type": "uint256[][5]"
					},
					{
						"internalType": "uint256[][5]",
						"name": "ids",
						"type": "uint256[][5]"
					},
					{
						"internalType": "uint32",
						"name": "randomCount",
						"type": "uint32"
					}
				],
				"internalType": "struct GameInterface.Dungeon[]",
				"name": "dungeons",
				"type": "tuple[]"
			}
		],
		"name": "addDungeons",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"components": [
							{
								"internalType": "uint256",
								"name": "health",
								"type": "uint256"
							},
							{
								"internalType": "uint256",
								"name": "maxHealth",
								"type": "uint256"
							},
							{
								"internalType": "uint256[6]",
								"name": "stats",
								"type": "uint256[6]"
							},
							{
								"internalType": "uint256[]",
								"name": "qwerks",
								"type": "uint256[]"
							}
						],
						"internalType": "struct DataLibrary.Actor",
						"name": "actor",
						"type": "tuple"
					},
					{
						"internalType": "uint256[]",
						"name": "chances",
						"type": "uint256[]"
					},
					{
						"components": [
							{
								"internalType": "uint256[]",
								"name": "parents",
								"type": "uint256[]"
							},
							{
								"internalType": "uint256[]",
								"name": "ids",
								"type": "uint256[]"
							},
							{
								"internalType": "bytes[]",
								"name": "data",
								"type": "bytes[]"
							},
							{
								"internalType": "bool[]",
								"name": "self",
								"type": "bool[]"
							}
						],
						"internalType": "struct DataLibrary.Action",
						"name": "action",
						"type": "tuple"
					}
				],
				"internalType": "struct GameInterface.Enemy[]",
				"name": "enemies",
				"type": "tuple[]"
			}
		],
		"name": "addEnemies",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "equipType",
						"type": "uint256"
					},
					{
						"components": [
							{
								"internalType": "uint256[]",
								"name": "parents",
								"type": "uint256[]"
							},
							{
								"internalType": "uint256[]",
								"name": "ids",
								"type": "uint256[]"
							},
							{
								"internalType": "bytes[]",
								"name": "data",
								"type": "bytes[]"
							},
							{
								"internalType": "bool[]",
								"name": "self",
								"type": "bool[]"
							}
						],
						"internalType": "struct DataLibrary.Action",
						"name": "action",
						"type": "tuple"
					}
				],
				"internalType": "struct GameInterface.Item[]",
				"name": "items",
				"type": "tuple[]"
			},
			{
				"components": [
					{
						"internalType": "string",
						"name": "name",
						"type": "string"
					},
					{
						"internalType": "uint256",
						"name": "tokenHash",
						"type": "uint256"
					}
				],
				"internalType": "struct DataLibrary.TokenMetadata[]",
				"name": "metadata",
				"type": "tuple[]"
			}
		],
		"name": "addItems",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "string",
						"name": "name",
						"type": "string"
					},
					{
						"internalType": "int256",
						"name": "maxHealth",
						"type": "int256"
					},
					{
						"internalType": "int256[6]",
						"name": "stats",
						"type": "int256[6]"
					}
				],
				"internalType": "struct GameInterface.Qwerk[]",
				"name": "qwerks",
				"type": "tuple[]"
			}
		],
		"name": "addQwerks",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "uint256[]",
						"name": "parents",
						"type": "uint256[]"
					},
					{
						"internalType": "uint256[]",
						"name": "ids",
						"type": "uint256[]"
					},
					{
						"internalType": "bytes[]",
						"name": "data",
						"type": "bytes[]"
					},
					{
						"internalType": "bool[]",
						"name": "self",
						"type": "bool[]"
					}
				],
				"internalType": "struct DataLibrary.Action[]",
				"name": "actions",
				"type": "tuple[]"
			}
		],
		"name": "addTraps",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "cardTokens",
		"outputs": [
			{
				"internalType": "contract CardsInterface",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "characterTokens",
		"outputs": [
			{
				"internalType": "contract CharactersInterface",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "claimCard",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "string",
				"name": "name",
				"type": "string"
			}
		],
		"name": "claimCharacter",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "characterId",
				"type": "uint256"
			}
		],
		"name": "claimRaid",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "goldPiece",
		"outputs": [
			{
				"internalType": "contract GoldPieceInterface",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "itemTokens",
		"outputs": [
			{
				"internalType": "contract ItemsInterface",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			},
			{
				"internalType": "uint256[]",
				"name": "",
				"type": "uint256[]"
			},
			{
				"internalType": "uint256[]",
				"name": "",
				"type": "uint256[]"
			},
			{
				"internalType": "bytes",
				"name": "",
				"type": "bytes"
			}
		],
		"name": "onERC1155BatchReceived",
		"outputs": [
			{
				"internalType": "bytes4",
				"name": "",
				"type": "bytes4"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			},
			{
				"internalType": "bytes",
				"name": "",
				"type": "bytes"
			}
		],
		"name": "onERC1155Received",
		"outputs": [
			{
				"internalType": "bytes4",
				"name": "",
				"type": "bytes4"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "sender",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "transferAmount",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "creditAmount",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "transferReceiver",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "creditReceiver",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "requestId",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "dataType",
				"type": "uint256"
			},
			{
				"internalType": "bytes",
				"name": "data",
				"type": "bytes"
			}
		],
		"name": "onRequestRandom",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "owner",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "dataType",
				"type": "uint256"
			}
		],
		"name": "randomCount",
		"outputs": [
			{
				"internalType": "uint32",
				"name": "",
				"type": "uint32"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "randomManager",
		"outputs": [
			{
				"internalType": "contract RandomManagerInterface",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "renounceOwnership",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "bytes4",
				"name": "interfaceId",
				"type": "bytes4"
			}
		],
		"name": "supportsInterface",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "newOwner",
				"type": "address"
			}
		],
		"name": "transferOwnership",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
];
const rngAbi = [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "link",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "coordinator",
				"type": "address"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "have",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "want",
				"type": "address"
			}
		],
		"name": "OnlyCoordinatorCanFulfill",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "creditReceiver",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "depositCredits",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "linkToken",
		"outputs": [
			{
				"internalType": "contract LinkTokenInterface",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "sender",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			},
			{
				"internalType": "bytes",
				"name": "data",
				"type": "bytes"
			}
		],
		"name": "onTokenTransfer",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "requestId",
				"type": "uint256"
			}
		],
		"name": "randomResponse",
		"outputs": [
			{
				"internalType": "uint256[]",
				"name": "",
				"type": "uint256[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "requestId",
				"type": "uint256"
			},
			{
				"internalType": "uint256[]",
				"name": "randomWords",
				"type": "uint256[]"
			}
		],
		"name": "rawFulfillRandomWords",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "transferAmount",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "creditAmount",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "transferReceiver",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "creditReceiver",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "consumer",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "dataType",
				"type": "uint256"
			},
			{
				"internalType": "bytes",
				"name": "data",
				"type": "bytes"
			}
		],
		"name": "requestRandom",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "requestId",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "requestId",
				"type": "uint256"
			}
		],
		"name": "requestResponded",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "vrfCoordinator",
		"outputs": [
			{
				"internalType": "contract VRFCoordinatorV2Interface",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "linkReceiver",
				"type": "address"
			}
		],
		"name": "withdrawCredits",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
];
const linkAbi = [
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "owner",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        }
      ],
      "name": "allowance",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "remaining",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "value",
          "type": "uint256"
        }
      ],
      "name": "approve",
      "outputs": [
        {
          "internalType": "bool",
          "name": "success",
          "type": "bool"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "owner",
          "type": "address"
        }
      ],
      "name": "balanceOf",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "balance",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "decimals",
      "outputs": [
        {
          "internalType": "uint8",
          "name": "decimalPlaces",
          "type": "uint8"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "addedValue",
          "type": "uint256"
        }
      ],
      "name": "decreaseApproval",
      "outputs": [
        {
          "internalType": "bool",
          "name": "success",
          "type": "bool"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "subtractedValue",
          "type": "uint256"
        }
      ],
      "name": "increaseApproval",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "name",
      "outputs": [
        {
          "internalType": "string",
          "name": "tokenName",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "symbol",
      "outputs": [
        {
          "internalType": "string",
          "name": "tokenSymbol",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "totalSupply",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "totalTokensIssued",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "to",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "value",
          "type": "uint256"
        }
      ],
      "name": "transfer",
      "outputs": [
        {
          "internalType": "bool",
          "name": "success",
          "type": "bool"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "to",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "value",
          "type": "uint256"
        },
        {
          "internalType": "bytes",
          "name": "data",
          "type": "bytes"
        }
      ],
      "name": "transferAndCall",
      "outputs": [
        {
          "internalType": "bool",
          "name": "success",
          "type": "bool"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "from",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "to",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "value",
          "type": "uint256"
        }
      ],
      "name": "transferFrom",
      "outputs": [
        {
          "internalType": "bool",
          "name": "success",
          "type": "bool"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "function"
    }
];

var gameContract;
var rngContract;
var linkContract;

window.ethereum.on('accountsChanged', async () => {
	selectedCharacter == undefined;
	selectedItem == undefined;
	requestAccounts();
});

async function checkConnected() {
	const acts = await ethereum.request({ method: 'eth_accounts' });

    if(acts && acts.length > 0) {
		connectButton.innerHTML = accounts[0].toString().slice(0, 5) + "..." + accounts[0].toString().slice(38, 42) + " Connected";
		connectButton.style = "background-color:darkblue;";
		connectButton.disabled = true;

		terminalEcho('Connected: ' + signer._address, EchoType.Text);

		await getCharacters();
		await getItems();
	} else {
		connectButton.innerHTML = "Connect";
		connectButton.style = "background-color:blue;";
		connectButton.disabled = false;
	}
}

async function requestAccounts() {
	provider = new ethers.providers.Web3Provider(window.ethereum);
    accounts = await provider.send("eth_requestAccounts",);
    signer = provider.getSigner(accounts[0]);
	checkConnected();

	gameContract = new ethers.Contract(gameAddress, gameAbi, signer);
	rngContract = new ethers.Contract(rngAddress, rngAbi, signer);
	linkContract = new ethers.Contract(linkAddress, linkAbi, signer);

	let maticBalance = await provider.getBalance(signer._address);
	document.getElementById("balance-matic").innerHTML = "MATIC : " + ethers.utils.formatEther(maticBalance).slice(0, 10).padEnd(10, '0');

	let linkBalance = await linkContract.balanceOf(signer._address);
	document.getElementById("balance-link").innerHTML = "LINK : " + ethers.utils.formatEther(linkBalance).slice(0, 10).padEnd(10, '0');
}

async function requestCard() {
	let cardData = abi.encode(
		['uint256', 'address', 'address', 'address', 'uint256', 'bytes'],
		[BigInt('1000000000000000000'), gameAddress, signer._address, gameAddress, 0, "0x"]
	);

	let txn = await linkContract.transferAndCall(rngAddress, BigInt('2000000000000000000'), cardData);

	terminalEcho("Requesting card...", EchoType.Text);

	txn = await txn.wait();
	console.log(txn);
	//terminalEcho("Requested card: " +  txn['transactionHash'], EchoType.Text);
	terminal.echo("[[b;black;green;]Requested card] " + txn['transactionHash']);
}

async function claimCard() {
	let txn = await gameContract.claimCard();

	terminalEcho("Claiming card...", EchoType.Text);

	txn = await txn.wait();
	console.log(txn);
	//terminalEcho("Claimed card: " +  txn['transactionHash'], EchoType.Text);
	terminal.echo("[[b;black;green;]Claimed card] " + txn['transactionHash']);
}

async function requestCharacter() {
	let txn = await rngContract.requestRandom(0, 0, "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", gameAddress, 1, "0x");

	terminalEcho("Requesting character...", EchoType.Text);

	txn = await txn.wait();
	console.log(txn);
	//terminalEcho("Requested character: " +  txn['transactionHash'], EchoType.Text);
	terminal.echo("[[b;black;green;]Requested character] " + txn['transactionHash']);
}

async function claimCharacter() {
	let txn = await gameContract.claimCharacter(inputName.value);

	terminalEcho("Claiming character...", EchoType.Text);

	txn = await txn.wait();
	console.log(txn);
	//terminalEcho("Claimed character: " +  txn['transactionHash'], EchoType.Text);
	terminal.echo("[[b;black;green;]Claimed character] " + txn['transactionHash']);
}

async function requestRaid() {
	if(selectedCharacter == undefined || selectedItem == undefined) {
		terminalEcho('Invalid raid parameters!', EchoType.Error);
		return;
	}

	let raidItems = [
		[],
		[],
		[selectedItem.id],
		[],
		[],
		[],
		[]
	];

	let raidAmounts = [
		[],
		[],
		[1],
		[],
		[],
		[],
		[]
	];

	let raidData = abi.encode(
		['uint256', 'uint256', 'uint256[][7]', 'uint256[][7]'],
		[1, selectedCharacter.id, raidItems, raidAmounts]
	);

	let txn = await rngContract.requestRandom(0, 0, "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", gameAddress, 2, raidData);

	terminalEcho("Requesting raid...", EchoType.Text);

	txn = await txn.wait();
	console.log(txn);
	//terminalEcho("Requested raid: " +  txn['transactionHash'], EchoType.Text);
	terminal.echo("[[b;black;green;]Requested raid] " + txn['transactionHash']);
}

async function claimRaid() {
	if(selectedCharacter == undefined) {
		terminalEcho('Invalid raid parameters!', EchoType.Error);
		return;
	}

	let txn = await gameContract.claimRaid(selectedCharacter.id);

	terminalEcho("Claiming raid...", EchoType.Text);

	txn = await txn.wait();
	console.log(txn);
	//terminalEcho("Claimed raid: " +  txn['transactionHash'], EchoType.Text);
	terminal.echo("[[b;black;green;]Claimed raid] " + txn['transactionHash']);

	echoRaid(txn);
}

function echoRaid(txn) {
	terminal.echo("[[b;black;gray;] RAID START ]");

	terminalEcho("", EchoType.Text);

	for(let i = 0; i < txn['events'].length; i++) {
		if(txn['events'][i].event == "Raid") {
			for(let e = 0; e < 5; e++) {
				let log = BigInt(txn['events'][i].args[2][e]._hex.toString()).toString();

				let id = parseInt(log.slice(1, 5), 16);
				let startHp = parseInt(log.slice(5, 9));
				let endHp = parseInt(log.slice(9, 13));
				let result = parseInt(log.slice(13, 17));
				let damage = (startHp - endHp).toString();

				switch(parseInt(log[0])) {
					case 1:
						// ITEM
						let itemName;

						if(id == 0) {
							itemName = "Sword"
						} else if (id == 1) {
							itemName = "Scythe" 
						} else if (id == 2) {
							itemName = "Cracked Orb"
						} else if (id == 3) {
							itemName = "Health Potion"
						} else if (id == 4) {
							itemName = "Amulet of Atu Loss"
						} else if (id == 5) {
							itemName = "Candle"
						}

						terminalEcho(selectedCharacter.name + " found a " + itemName, EchoType.Item);
						break;
					case 2:
						// TRAP
						if(id == 0) {
							terminalEcho(
								"Walking down a narrow passage, " + 
								selectedCharacter.name + 
								" feels something pull at his ankle as he steps. The click of some mechanism in the wall is heard, and " + 
								selectedCharacter.name + " is suddenly struck with an arrow taking " + damage + " damage!", 
								EchoType.Trap
							);	
						} else if (id == 1) {
							terminalEcho(
								"The pattern of " + 
								selectedCharacter.name + 
								"'s foot steps are broken by a loud click from below a depressed cobblestone tile. A log then swings down from the ceiling, battering " +
								selectedCharacter.name +
								" in the back and taking " + damage + " damage!", 
								EchoType.Trap
							);
						} else if (id == 2) {
							terminalEcho(
								selectedCharacter.name + 
								" spots the glimmer of some gold object from under some torn rags, upon grabbing the thing, " + 
								selectedCharacter.name + 
								" can feel something pulling the object back down. Then a flash of orange and white as " + 
								selectedCharacter.name + 
								" is engulfed by flames. Jumping back, " + selectedCharacter.name + " watches as the fire dissipates, having taken " + damage + " damage!", 
								EchoType.Trap
							);
						}
						break;
					case 3:
						// ENEMY
						damage = Math.floor(Math.random() * 7) + 1;

						if (id == 1) {
							switch(result) {
								case 1:
									terminalEcho(
										"A wild looking man-ape appears from out behind a pretruding rock in " + selectedCharacter.name + 
										"'s path, the two lock eyes and begin striking at each other. " + 
										selectedCharacter.name + 
										" is able to land a fatal blow against the man-ape, having sustained " + damage + " damage!",
										EchoType.Enemy
									);
									break;
								case 7:
									terminalEcho(
										"A wild looking man-ape appears from out behind a pretruding rock in " + selectedCharacter.name + 
										"'s path, the two lock eyes and begin striking at each other with their weapons. " + 
										"The man-ape is able to land a fatal blow, killing " + selectedCharacter.name,
										EchoType.Enemy
									);
									break;
							}						
						} else if (id == 2) {
							switch(result) {
								case 1:
									terminalEcho(
										selectedCharacter.name + 
										" is stopped by the groan of something ahead, the silhouette of an algoid begins to emerge from the darkness as it charges toward " + 
										selectedCharacter.name +
										". The hulking blue creature just misses " + 
										selectedCharacter.name + 
										", who starts to strike the algoid as it recovers from crashing into the wall behind " + 
										selectedCharacter.name + 
										" The alogid now turned to face " + 
										selectedCharacter.name + 
										" begins raining its giant fists down. " + 
										selectedCharacter.name + 
										" is able to bring the algoid to its knees in pain, and land a fatal blow to its head, having sustained " + damage + " damage!", 
										EchoType.Enemy
									);
									break;
								case 7:
									terminalEcho(
										selectedCharacter.name + 
										" is stopped by the groan of something ahead, the silhouette of an algoid begins to emerge from the darkness as it charges toward " + 
										selectedCharacter.name +
										". The hulking blue creature crashes into " + 
										selectedCharacter.name + 
										", killing " + 
										selectedCharacter.name + 
										" instantly!", 
										EchoType.Enemy
									);									
									break;
							}								
						}
						break;
					case 5:
						// NONE
						let rand = Math.floor(Math.random() * 4);
						switch(rand) {
							case 0:
								terminalEcho(
									"Standing still for a moment in the silence of the dungeon, " + 
									selectedCharacter.name + 
									" is able to hear a faint sound. As if the stone below were being ground together by some giant beast.", 
									EchoType.None
								);
								break;
							case 1:
								terminalEcho(
									"In the darkness " + 
									selectedCharacter.name + 
									" can make out the distant flicker of a torch, upon moving closer to the torches glow, the flame is extinguished.", 
									EchoType.None
								);
								break;
							case 2:
								terminalEcho(
									"Hunched over a rotting wooden table lays a humanoid skeleton, hundreds of keys, all seemingly identical, are scattered across the table top and floor.", 
									EchoType.None
								);
								break;
							case 3:
								terminalEcho(
									selectedCharacter.name + 
									" approaches a metal door. It doesn't appear to have any sort of handle, or locking mechanism, the only feature betraying the metal slab as a door, is the slither of light coming from the paper-thin gap down its centre.",
									EchoType.None
								);
								break;
						}
						break;
				}

				terminalEcho("", EchoType.Text);

				if(endHp == 0) {
					terminalEcho(
						selectedCharacter.name + " DIED",
						EchoType.Error
					);
					break;
				}
			}

			break;
		}
	}

	terminal.echo("[[b;black;gray;] RAID END ]");
}

async function getCharacters() {
	const options = {
		method: 'GET',
		url: 'https://deep-index.moralis.io/api/v2/' + signer._address + '/nft',
		params: {
		  chain: 'mumbai',
		  format: 'decimal',
		  limit: '100',
		  token_addresses: '0x2fcA85c658CD2BBf4cdF3B8204D2a8a033502360',
		  normalizeMetadata: 'true'
		},
		headers: {accept: 'application/json', 'X-API-Key': 'ROKUV6i0vGPdkXiXZ5HkcB7oGPm8ziN9saxdy378DE4avWpO2Nk57VYVGNWWraU6'}
	};

	await axios
		.request(options)
		.then(function (response) {
			ownedCharacters = response.data;
		})
		.catch(function (error) {
			console.error(error);
	});

	// Update characters UI

	charactersParent.innerHTML = "";

	for (let i = 0; i < ownedCharacters.result.length; i++) {
		var charImage = document.createElement("input");
		charImage.type = "image";
		charImage.src = ownedCharacters.result[i].normalized_metadata['image'];
		charImage.className = "img-character";
		charImage.addEventListener('click', function(){
			selectCharacter(
				ownedCharacters.result[i].token_id,
				ownedCharacters.result[i].normalized_metadata['name']
			);
		});		
		charactersParent.appendChild(charImage);
	}
}

function selectCharacter(id, name) {
	selectedCharacter = {id: id, name: name};
	terminalEcho("Selected character: " + name + " (ID: " + id + ")", EchoType.Text);
}

async function getItems() {
	const options = {
		method: 'GET',
		url: 'https://deep-index.moralis.io/api/v2/' + signer._address + '/nft',
		params: {
		  chain: 'mumbai',
		  format: 'decimal',
		  limit: '100',
		  token_addresses: '0x47123AD88c719d6673728edD13C09B39bc8c9366',
		  normalizeMetadata: 'true'
		},
		headers: {accept: 'application/json', 'X-API-Key': 'ROKUV6i0vGPdkXiXZ5HkcB7oGPm8ziN9saxdy378DE4avWpO2Nk57VYVGNWWraU6'}
	};

	await axios
		.request(options)
		.then(function (response) {
			ownedItems = response.data;
		})
		.catch(function (error) {
			console.error(error);
	});

	// Update items UI

	itemsParent.innerHTML = "";

	for (let i = 0; i < ownedItems.result.length; i++) {
		var itemImage = document.createElement("input");
		itemImage.type = "image";
		itemImage.src = ownedItems.result[i].normalized_metadata['image'];
		itemImage.className = "img-item";
		itemImage.addEventListener('click', function(){
			selectItem(
				ownedItems.result[i].token_id, 
				ownedItems.result[i].normalized_metadata['name']
			);
		});	
		itemsParent.appendChild(itemImage);
	}
}

function selectItem(id, name) {
	selectedItem = {id: id, name: name};
	terminalEcho("Selected item: " + name + " (ID: " + id + ")", EchoType.Text);
}