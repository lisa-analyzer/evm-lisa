// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IHelixMessageEndpoint.sol";

interface IHelixSub2EthMessageEndpoint is IHelixMessageEndpoint {
    function fee() external view returns (uint256);
    function currentDeliveredMessageId() external view returns (uint256);
    function isMessageDelivered(uint256 messageId) external view returns (bool);
}
