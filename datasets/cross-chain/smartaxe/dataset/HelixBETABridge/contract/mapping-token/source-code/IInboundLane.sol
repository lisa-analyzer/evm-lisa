// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IInboundLane {
    struct RelayersRange {
        uint64 front;
        uint64 back;
    }

    struct InboundLaneNonce {
        uint64 last_confirmed_nonce;
        uint64 last_delivered_nonce;
        RelayersRange relayer_range;
    }

    function inboundLaneNonce() view external returns(InboundLaneNonce memory);
    function encodeMessageKey(uint64 nonce) view external returns(uint256);
}
