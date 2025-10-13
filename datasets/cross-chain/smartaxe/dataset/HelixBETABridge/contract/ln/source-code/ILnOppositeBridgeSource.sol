// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface ILnOppositeBridgeSource {
    function slash(
        bytes32 lastRefundTransferId,
        bytes32 transferId,
        uint256 remoteChainId,
        uint256 timestamp,
        address sourceToken,
        address targetToken,
        address provider,
        address slasher
    ) external;

    function withdrawMargin(
        bytes32 lastRefundTransferId,
        bytes32 lastTransferId,
        uint256 remoteChainId,
        address provider,
        address sourceToken,
        address targetToken,
        uint112 amount
    ) external;
}
