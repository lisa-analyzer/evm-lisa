// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IScrollMessenger {
  function sendMessage(address target, uint256 value, bytes calldata message, uint256 gasLimit, address refundAddress) external payable;
  function messageQueue() external view returns (address);
  function xDomainMessageSender() external view returns (address);
}

interface IL1MessageQueue {
    function estimateCrossDomainMessageFee(uint256 gasLimit) external view returns(uint256);
}
