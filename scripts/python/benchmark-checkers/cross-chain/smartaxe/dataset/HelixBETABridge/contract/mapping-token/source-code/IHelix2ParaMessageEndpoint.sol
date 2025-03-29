// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IHelix2ParaMessageEndpoint {
    function fee() external view returns (uint256);
    function currentDeliveredMessageNonce() external view returns(uint64);
    function lastDeliveredMessageNonce() external view returns (uint64);
    function isMessageDeliveredByNonce(uint64 nonce) external view returns(bool);
    function sendMessage(
        uint32  remoteSpecVersion,
        uint64 remoteWeight,
        bytes calldata encoded) external payable returns (uint64);
}
