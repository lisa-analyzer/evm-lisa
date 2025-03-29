// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IMessageTransmitter {
    function receiveMessage(bytes calldata _message, bytes calldata _attestation) external returns (bool);
}