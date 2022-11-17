const EchoType = {
	Text: 0,
	Warning: 1,
	Error: 2,
    Success: 3,
    
    Item: 4,
    Trap: 5,
    Enemy: 6,
    Invasion: 7,
    None: 8
}

const terminal = $('#terminalParent').terminal({
        chainlink: function () {
            this.echo('[[;cyan;]1k eoy]');
        },
        help: function () {
            help();
        },
        iam: function () {
            iam();
        },
        whoami: function () {
            iam();
        },
        item: function () {
            item();
        },
        contracts: function() {
            contracts();
        }
    }, 
    {
        greetings: '[[b;gold;] Agaia Online ]\n',
        height: 500,
        width: 750,
        background: '#222111'
    }
);

function help() {
    terminalEcho(
        'contracts  : Agaia Online contract addresses\n' +
        'iam        : Selected character\n' + 
        'item       : Selected item',
        EchoType.Text
    );
}

function iam() {
    if(selectedCharacter == undefined) {    
        terminalEcho('Select a character!', EchoType.Warning);
    } else {
        terminalEcho(selectedCharacter.name + " (ID: " + selectedCharacter.id + ")", EchoType.Text);
    }
}

function item() {
    if(selectedItem == undefined) {
        terminalEcho('Select an item!', EchoType.Warning);
    } else {
        terminalEcho(selectedItem.name + " (ID: " + selectedItem.id + ")", EchoType.Text);
    }
}

function contracts() {
    terminalEcho(
        'game       : 0x4DC9E9644CC8D86D61bcE519714F9F7195f098Bd\n' +
        'cards      : 0x1Ef7856FBddaB5127e36AfEA0C70577DCd2D7944\n' +
        'characters : 0x2fcA85c658CD2BBf4cdF3B8204D2a8a033502360\n' +
        'items      : 0x47123AD88c719d6673728edD13C09B39bc8c9366\n\n' +
        'random manager : 0xaF06d4db46887Cd476Cd14E037cA7c0747714E52',
        EchoType.Text
    );
}

function terminalEcho(text, type) {
    switch(type) {
        case EchoType.Text:
            terminal.echo('[[;gray;]' + text + ']');
            break;
        case EchoType.Warning:
            terminal.echo('[[;yellow;]' + text + ']');
            break;
        case EchoType.Error:
            terminal.echo('[[;red;]' + text + ']');
            break;
        case EchoType.Success:
            terminal.echo('[[;green;]' + text + ']');
            break;

        case EchoType.Item:
            terminal.echo('[[;cyan;]' + text + ']');
            break;
        case EchoType.Trap:
            terminal.echo('[[;yellow;]' + text + ']');
            break;
        case EchoType.Enemy:
            terminal.echo('[[;orange;]' + text + ']');
            break;
        case EchoType.Invasion:
            terminal.echo('[[;hotpink;]' + text + ']');
            break;
        case EchoType.None:
            terminal.echo('[[;white;]' + text + ']');
            break;
    }
}