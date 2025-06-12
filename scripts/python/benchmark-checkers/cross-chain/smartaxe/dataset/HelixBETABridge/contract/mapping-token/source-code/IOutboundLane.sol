// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOutboundLane {
    struct OutboundLaneNonce {
        uint64 latest_received_nonce;
        uint64 latest_generated_nonce;
        uint64 oldest_unpruned_nonce;
    }

    function outboundLaneNonce() view external returns(OutboundLaneNonce memory);

    function send_message(address targetContract, bytes calldata encoded) external payable returns (uint64);
}
