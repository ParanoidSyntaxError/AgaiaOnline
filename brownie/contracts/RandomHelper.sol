// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library RandomHelper {
    function expand(uint256 seed, uint256 offset) external pure returns (uint256) {
        return uint256(keccak256(abi.encode(seed, offset)));
    }

    function expandArray(uint256 seed, uint256 offset, uint256 n) external pure returns (uint256[] memory) {
        uint256[] memory randoms = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            randoms[i] = uint256(keccak256(abi.encode(seed, i + offset)));
        }
        return randoms;
    }
}