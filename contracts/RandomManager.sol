// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/ERC677ReceiverInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./IRandomManager.sol";
import "./IRandomRequestor.sol";

contract RandomManager is IRandomManager, VRFConsumerBaseV2, ERC677ReceiverInterface {
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
        IRandomRequestor randomRequestor = IRandomRequestor(requestor);

        requestId = vrfCoordinator.requestRandomWords(
            0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f,
            _subscriptionIds[msg.sender],
            5,
            1000000,
            randomRequestor.randomCount(dataType)
        );

        randomRequestor.onRequestRandom(msg.sender, requestId, dataType, data);
    }

    function onTokenTransfer(address /*sender*/, uint256 amount, bytes calldata data) external override {
        address creditReceiver = abi.decode(data, (address));
        
        _addCredits(creditReceiver, amount);
    }

    function depositCredits(address linkSender, address creditReceiver, uint256 amount) external override {
        linkToken.transferFrom(linkSender, address(this), amount);
        
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