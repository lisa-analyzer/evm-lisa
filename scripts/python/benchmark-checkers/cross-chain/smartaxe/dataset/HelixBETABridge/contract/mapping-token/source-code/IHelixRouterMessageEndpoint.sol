// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IHelixRouterMessageEndpoint {
    function fee() external view returns (uint256);
    function sendMessage(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        address receiver,
        bytes calldata encoded) external payable returns (uint256);
}
