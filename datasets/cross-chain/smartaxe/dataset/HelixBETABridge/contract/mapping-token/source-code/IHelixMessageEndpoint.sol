// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHelixMessageEndpoint {
    function sendMessage(address receiver, bytes calldata encoded) external payable returns (uint256);
}
