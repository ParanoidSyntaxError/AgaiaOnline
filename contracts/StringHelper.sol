// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";

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

    function hashToSvg(string memory str) internal pure returns (string memory svg) {
        for(uint256 i = 0; i < stringLength(str) / 8; i++) {
            svg = string(abi.encodePacked(
                    svg, 
                    "<rect fill='#000000' x='", subString(str, i * 8, (i * 8) + 2), 
                    "' y='", subString(str, (i * 8) + 2, (i * 8) + 4), 
                    "' width='", subString(str, (i * 8) + 4, (i * 8) + 6), 
                    "' height='", subString(str, (i * 8) + 6, (i * 8) + 8), 
                    "'/>"
            ));
        }
    }

    function encodeMetadata(string memory name, string memory description, string memory image, string memory attributes) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(string(
                abi.encodePacked(
                    '{"name": "', 
                    name,
                    '", "description": "',
                    description,
                    '", "image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(image)),
                    '", "attributes":',
                    attributes,
                    "}"
                )
            )))
        )); 
    }
}