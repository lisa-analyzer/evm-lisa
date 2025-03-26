// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IxTokenBacking {
    function unlockFromRemote(
        uint256 remoteChainId,
        address originalToken,
        address originalSender,
        address recipient,
        uint256 amount,
        uint256 nonce
    ) external;

    function handleUnlockForIssuingFailureFromRemote(
        uint256 remoteChainId,
        address originalToken,
        address originalSender,
        address recipient,
        uint256 amount,
        uint256 nonce
    ) external;
}
