// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRandomManager {
    function depositCredits(address linkSender, address creditReceiver, uint256 amount) external;
    function withdrawCredits(address linkReceiver) external;

    function requestRandom(address requestor, uint256 dataType, bytes calldata data) external returns (uint256 requestId);
    
    function randomResponse(uint256 requestId) external view returns (uint256[] memory response);
    function requestResponded(uint256 requestId) external view returns (bool);
}