// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/ERC677ReceiverInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./RandomManagerInterface.sol";
import "./RandomRequestorInterface.sol";

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

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _responses[requestId] = randomWords;
    }
    
    function requestRandom(address requestor, uint256 dataType, bytes calldata data) external returns (uint256 requestId) {
        return _requestRandom(msg.sender, requestor, dataType, data);
    }

    function _requestRandom(address sender, address requestor, uint256 dataType, bytes memory data) internal returns (uint256 requestId) {
        RandomRequestorInterface randomRequestor = RandomRequestorInterface(requestor);

        requestId = vrfCoordinator.requestRandomWords(
            0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f,
            _subscriptionIds[sender],
            5,
            1000000,
            randomRequestor.randomCount(dataType)
        );

        randomRequestor.onRequestRandom(sender, requestId, dataType, data);
    }

    function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external override {
        require(msg.sender == address(linkToken));
        
        (
            address creditReceiver, 
            uint256 transferAmount, 
            address transferReceiver, 
            bytes memory transferData,
            address requestor, 
            uint256 requestDataType, 
            bytes memory requestData
        ) = abi.decode(data, (address, uint256, address, bytes, address, uint256, bytes));

        _addCredits(creditReceiver, amount - transferAmount);

        if(transferAmount > 0) {
            linkToken.transferAndCall(transferReceiver, transferAmount, transferData);
        }

        if(requestor != address(0)) {
            _requestRandom(sender, requestor, requestDataType, requestData);
        }
    }

    function depositCredits(address creditReceiver, uint256 amount) external override {
        linkToken.transferFrom(msg.sender, address(this), amount);
        
        _addCredits(creditReceiver, amount);
    }

    function _addCredits(address receiver, uint256 amount) internal {
        require(amount > 0);

        if(_subscriptionIds[receiver] == 0) {
            _subscriptionIds[receiver] = vrfCoordinator.createSubscription();
            vrfCoordinator.addConsumer(_subscriptionIds[receiver], address(this));
        }

        linkToken.transferAndCall(address(vrfCoordinator), amount, abi.encode(_subscriptionIds[receiver]));
    }

    function withdrawCredits(address linkReceiver) external override {
        require(_subscriptionIds[msg.sender] > 0);

        (uint96 balance,,,) = vrfCoordinator.getSubscription(_subscriptionIds[msg.sender]);
        require(balance > 0);

        _subscriptionIds[msg.sender] = 0;

        vrfCoordinator.cancelSubscription(_subscriptionIds[msg.sender], linkReceiver);
    }
}