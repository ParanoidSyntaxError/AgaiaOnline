// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/ERC677ReceiverInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./interfaces/RandomManagerInterface.sol";
import "./interfaces/RandomRequestorInterface.sol";

contract RandomManager is RandomManagerInterface, VRFConsumerBaseV2, ERC677ReceiverInterface {
    // Receipt ID => Response
    mapping(uint256 => uint256[]) internal _responses;

    LinkTokenInterface public immutable linkToken;
    VRFCoordinatorV2Interface public immutable vrfCoordinator;

    mapping(address => uint64) internal _subscriptionIds;

    constructor(address link, address coordinator) VRFConsumerBaseV2(coordinator) {
        linkToken = LinkTokenInterface(link);
        vrfCoordinator = VRFCoordinatorV2Interface(coordinator);
    }

    function requestResponded(uint256 requestId) external view override returns (bool) {
        return _responses[requestId].length > 0;
    }

    function randomResponse(uint256 requestId) external view override returns (uint256[] memory) {
        require(_responses[requestId].length > 0);
        return _responses[requestId];   
    }

    // DEBUG
    function debugFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        _responses[requestId] = randomWords;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _responses[requestId] = randomWords;
    }
    
    function requestRandom(uint256 transferAmount, uint256 creditAmount, address transferReceiver, address creditReceiver, address consumer, uint256 dataType, bytes calldata data) external returns (uint256 requestId) {
        if(transferAmount > 0 || creditAmount > 0) {
            linkToken.transferFrom(msg.sender, address(this), transferAmount + creditAmount);

            if(transferAmount > 0) {
                linkToken.transfer(transferReceiver, transferAmount);
            }
            if(creditAmount > 0) {
                _addCredits(creditReceiver, creditAmount);
            }
        }

        return _requestRandom(msg.sender, transferAmount, creditAmount, transferReceiver, creditReceiver, consumer, dataType, data);
    }

    //DEBUG
    uint256 requestNonce = 1;

    function _requestRandom(address sender, uint256 transferAmount, uint256 creditAmount, address transferReceiver, address creditReceiver, address consumer, uint256 dataType, bytes memory data) internal returns (uint256 requestId) {
        RandomRequestorInterface randomRequestor = RandomRequestorInterface(consumer);

        /*
        requestId = vrfCoordinator.requestRandomWords(
            0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f,
            _subscriptionIds[sender],
            3,
            1000000,
            randomRequestor.randomCount(dataType)
        );
        */

        // DEBUG
        requestId = requestNonce;

        randomRequestor.onRequestRandom(sender, transferAmount, creditAmount, transferReceiver, creditReceiver, requestId, dataType, data);

        requestNonce++;
    }

    function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external override {
        require(msg.sender == address(linkToken));
        
        (
            uint256 transferAmount,
            address transferReceiver, 
            address creditReceiver,  
            address consumer, 
            uint256 requestDataType, 
            bytes memory requestData
        ) = abi.decode(data, (uint256, address, address, address, uint256, bytes));

        _addCredits(creditReceiver, amount - transferAmount);

        if(transferAmount > 0) {
            linkToken.transfer(transferReceiver, transferAmount);
        }

        if(consumer != address(0)) {
            _requestRandom(sender, transferAmount, amount - transferAmount, transferReceiver, creditReceiver, consumer, requestDataType, requestData);
        }
    }

    function depositCredits(address creditReceiver, uint256 amount) external override {
        linkToken.transferFrom(msg.sender, address(this), amount);
        
        _addCredits(creditReceiver, amount);
    }

    function _addCredits(address receiver, uint256 amount) internal {
        require(amount > 0);

        if(_subscriptionIds[receiver] == 0) {
            //_subscriptionIds[receiver] = vrfCoordinator.createSubscription();
            //vrfCoordinator.addConsumer(_subscriptionIds[receiver], address(this));
        }

        //linkToken.transferAndCall(address(vrfCoordinator), amount, abi.encode(_subscriptionIds[receiver]));
    }

    function withdrawCredits(address linkReceiver) external override {
        require(_subscriptionIds[msg.sender] > 0);

        (uint96 balance,,,) = vrfCoordinator.getSubscription(_subscriptionIds[msg.sender]);
        require(balance > 0);

        _subscriptionIds[msg.sender] = 0;

        vrfCoordinator.cancelSubscription(_subscriptionIds[msg.sender], linkReceiver);
    }
}