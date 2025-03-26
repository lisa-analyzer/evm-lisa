// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {BytesLib} from "wormhole/libraries/external/BytesLib.sol";

import {CircleIntegrationStructs} from "./CircleIntegrationStructs.sol";

contract CircleIntegrationMessages is CircleIntegrationStructs {
    using BytesLib for bytes;

    /**
     * @notice `encodeDepositWithPayload` encodes the `DepositWithPayload` struct into bytes
     * so that it can be sent as an arbitrary message payload via Wormhole.
     * @param message `DepositWithPayload` struct containing the following attributes:
     * - `token` Address (bytes32 left-zero-padded) of token to be minted
     * - `amount` Amount of tokens to be minted
     * - `sourceDomain` Circle domain for the source chain
     * - `targetDomain` Circle domain for the target chain
     * - `nonce` Circle sequence number for the transfer
     * - `fromAddress` Source CircleIntegration contract caller's address
     * - `mintRecipient` Recipient of minted tokens (must be caller of this contract)
     * - `payload` Arbitrary Wormhole message payload
     * @return EncodedDepositWithPayload bytes
     */
    function encodeDepositWithPayload(DepositWithPayload memory message) public pure returns (bytes memory) {
        return abi.encodePacked(
            uint8(1), // payloadId
            message.token,
            message.amount,
            message.sourceDomain,
            message.targetDomain,
            message.nonce,
            message.fromAddress,
            message.mintRecipient,
            uint16(message.payload.length),
            message.payload
        );
    }

    /**
     * @notice `decodeDepositWithPayload` decodes an encoded `DepositWithPayload` struct
     * @dev reverts if:
     * - the first byte (payloadId) does not equal 1
     * - the length of the payload is short or longer than expected
     * @param encoded Encoded `DepositWithPayload` struct
     * @return message `DepositWithPayload` struct containing the following attributes:
     * - `token` Address (bytes32 left-zero-padded) of token to be minted
     * - `amount` Amount of tokens to be minted
     * - `sourceDomain` Circle domain for the source chain
     * - `targetDomain` Circle domain for the target chain
     * - `nonce` Circle sequence number for the transfer
     * - `fromAddress` Source CircleIntegration contract caller's address
     * - `mintRecipient` Recipient of minted tokens (must be caller of this contract)
     * - `payload` Arbitrary Wormhole message payload
     */
    function decodeDepositWithPayload(bytes memory encoded) public pure returns (DepositWithPayload memory message) {
        // payloadId
        require(encoded.toUint8(0) == 1, "invalid message payloadId");

        uint256 index = 1;

        // token address
        message.token = encoded.toBytes32(index);
        index += 32;

        // token amount
        message.amount = encoded.toUint256(index);
        index += 32;

        // source domain
        message.sourceDomain = encoded.toUint32(index);
        index += 4;

        // target domain
        message.targetDomain = encoded.toUint32(index);
        index += 4;

        // nonce
        message.nonce = encoded.toUint64(index);
        index += 8;

        // fromAddress (contract caller)
        message.fromAddress = encoded.toBytes32(index);
        index += 32;

        // mintRecipient (target contract)
        message.mintRecipient = encoded.toBytes32(index);
        index += 32;

        // message payload length
        uint256 payloadLen = encoded.toUint16(index);
        index += 2;

        // parse the additional payload to confirm the entire message was parsed
        message.payload = encoded.slice(index, payloadLen);
        index += payloadLen;

        // confirm that the message payload is the expected length
        require(index == encoded.length, "invalid message length");
    }
}