// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library StringHelper {
    function stringLength(string memory str) internal pure returns(uint256) {
        return bytes(str).length;
    }

    function subString(string memory str, uint startIndex, uint endIndex) internal pure returns (bytes memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return result;
    }
}