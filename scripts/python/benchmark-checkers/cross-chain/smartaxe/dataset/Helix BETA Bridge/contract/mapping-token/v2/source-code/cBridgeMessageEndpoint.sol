// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "sgn-v2-contracts/contracts/message/interfaces/IMessageBus.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageReceiverApp.sol";
import "../AccessController.sol";
import "../../interfaces/IHelixMessageEndpoint.sol";

contract cBridgeMessageEndpoint is IHelixMessageEndpoint, AccessController {
    address public messageBus;
    uint64  public remoteChainId;
    address public remoteHelix;

    modifier onlyMessageBus() {
        require(msg.sender == messageBus, "cBridgeMessageEndpoint:caller is not message bus");
        _;
    }

    modifier onlyBridgeMessageEndpoint(address sender) {
        require(sender == remoteHelix, "cBridgeMessageEndpoint:invalid remote sender");
        _;
    }

    constructor() {
        _initialize(msg.sender);
    }

    function setMessageBus(address _messageBus) external onlyAdmin {
        messageBus = _messageBus;
    }

    function setBridgeInfo(uint64 _remoteChainId, address _remoteHelix) external onlyAdmin {
        remoteChainId = _remoteChainId;
        remoteHelix = _remoteHelix;
    }

    function sendMessage(address receiver, bytes calldata message) external onlyCaller payable returns (uint256) {
        bytes memory messageWithCaller = abi.encode(receiver, message);
        IMessageBus(messageBus).sendMessage{value: msg.value}(remoteHelix, remoteChainId, messageWithCaller);
        return 0;
    }

    // this will be called by messageBus
    function executeMessage(
        address sender,
        uint64 srcChainId,
        bytes memory message,
        address
    ) external payable onlyMessageBus onlyBridgeMessageEndpoint(sender) returns (IMessageReceiverApp.ExecutionStatus) {
        require(remoteChainId == srcChainId, "invalid srcChainId");
        (address receiver, bytes memory payload) = abi.decode(message, (address, bytes));
        require(hasRole(CALLER_ROLE, receiver), "cBridgeMessageEndpoint:receiver is not caller");
        (bool result,) = receiver.call{value: 0}(payload);
        if (result) {
            return IMessageReceiverApp.ExecutionStatus.Success;
        } else {
            return IMessageReceiverApp.ExecutionStatus.Fail;
        }
    }
}

