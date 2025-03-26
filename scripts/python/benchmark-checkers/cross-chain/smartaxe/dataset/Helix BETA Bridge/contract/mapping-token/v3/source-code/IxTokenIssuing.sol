// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IxTokenIssuing {
    function handleIssuingForUnlockFailureFromRemote(
        uint256 originalChainId,
        address originalToken,
        address originalSender,
        address recipient,
        uint256 amount,
        uint256 nonce
    ) external;

    function issuexToken(
        uint256 remoteChainId,
        address originalToken,
        address originalSender,
        address recipient,
        uint256 amount,
        uint256 nonce
    ) external;
}
