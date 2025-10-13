// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GetKey {
    function getProviderKey(uint256 remoteChainId, address provider, address sourceToken, address targetToken) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            remoteChainId,
            provider,
            sourceToken,
            targetToken
        ));
    }

    function getTokenKey(uint256 remoteChainId, address sourceToken, address targetToken) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            remoteChainId,
            sourceToken,
            targetToken
        ));
    }
}
