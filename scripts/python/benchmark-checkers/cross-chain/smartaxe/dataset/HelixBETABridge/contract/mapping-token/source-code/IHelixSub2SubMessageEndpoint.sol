// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IHelixMessageEndpoint.sol";

interface IHelixSub2SubMessageEndpoint is IHelixMessageEndpoint {
    function fee() external view returns (uint256);
    function lastDeliveredMessageId() external view returns (uint256);
    function isMessageDelivered(uint256 messageId) external view returns(bool);
    function sendMessage(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        address receiver,
        bytes calldata encoded) external payable returns (uint256);
}
