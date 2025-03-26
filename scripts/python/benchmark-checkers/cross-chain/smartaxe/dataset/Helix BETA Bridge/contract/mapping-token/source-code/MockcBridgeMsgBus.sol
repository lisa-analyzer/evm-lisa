// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "sgn-v2-contracts/contracts/message/interfaces/IMessageReceiverApp.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageBus.sol";

interface IMsgBus is IMessageBus {
    function executeMessage(
        address sender,
        uint64 srcChainId,
        bytes memory message,
        address executor
    ) external payable returns (IMessageReceiverApp.ExecutionStatus);
}

contract MockcBridgeMsgBus {
    address public receiver;
    address public remoteMessageBus;
    uint64 public remoteChainId;

    receive() external payable {}

    function setReceiver(address _receiver) public {
        receiver = _receiver;
    }

    function setRemoteMsgBus(address _remoteMessageBus) public {
        remoteMessageBus = _remoteMessageBus;
    }

    function setRemoteChainId(uint64 _remoteChainId) public {
        remoteChainId = _remoteChainId;
    }

    function sendMessage(
        address,
        uint256,
        bytes calldata _message
    ) external payable {
        IMsgBus(remoteMessageBus).executeMessage(msg.sender, remoteChainId, _message, address(0));
    }

    function executeMessage(
        address sender,
        uint64 srcChainId,
        bytes memory message,
        address executor
    ) external payable returns (IMessageReceiverApp.ExecutionStatus status) {
        IMsgBus(receiver).executeMessage(sender, srcChainId, message, executor);
        status = IMessageReceiverApp.ExecutionStatus.Success;
    }
}

