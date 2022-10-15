// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/ERC677ReceiverInterface.sol";

import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VRFManager is VRFConsumerBaseV2, ERC677ReceiverInterface {
    IERC20 public immutable link;
    
    mapping(address => uint256) internal _credits;

    uint256 internal constant _minimumCredits = 10 ** 18;

    // Request ID => Receipt ID
    mapping(uint256 => uint256) internal _receiptIds;
    // Receipt ID => Response
    mapping(uint256 => uint256[]) internal _responses;

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    address link_token_contract = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    uint64 public subscriptionId;

    constructor(address linkToken) VRFConsumerBaseV2(vrfCoordinator) {
        link = IERC20(linkToken);

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);

        subscriptionId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subscriptionId, address(this));
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _responses[_receiptIds[requestId]] = randomWords;
    }
    
    function onTokenTransfer(address /*sender*/, uint256 amount, bytes calldata data) external override {
        require(amount > 0);
        address creditReceiver = abi.decode(data, (address));
        _credits[creditReceiver] += amount;
    }

    function depositCredits(address linkSender, address creditReceiver, uint256 amount) external {
        require(amount > 0);
        link.transferFrom(linkSender, address(this), amount);
        _credits[creditReceiver] += amount;
    }

    function withdrawCredits(address linkReceiver, uint256 amount) external {
        require(amount > 0);
        require(_credits[msg.sender] - amount >= _minimumCredits);
        link.transfer(linkReceiver, amount);
        _credits[msg.sender] -= amount;
    }
}