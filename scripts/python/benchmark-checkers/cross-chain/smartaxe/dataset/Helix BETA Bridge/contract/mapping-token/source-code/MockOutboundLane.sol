// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import "./MockMessageVerifier.sol";
import "./MockInboundLane.sol";
import "../interfaces/IOutboundLane.sol";
import "hardhat/console.sol";

contract MockOutboundLane is MockMessageVerifier {
    IOutboundLane.OutboundLaneNonce public outboundLaneNonce;
    struct ConfirmInfo {
        address sender;
        bool result;
    }
    address remoteInboundLane;
    constructor(
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition,
        address _remoteInboundLane
    ) MockMessageVerifier(
        _thisChainPosition,
        _thisLanePosition,
        _bridgedChainPosition,
        _bridgedLanePosition
    ) {
        remoteInboundLane = _remoteInboundLane;
    }

    function send_message(address targetContract, bytes calldata encoded) external payable returns (uint64) {
        // call target contract
        bool result = MockInboundLane(remoteInboundLane).mock_dispatch(msg.sender, targetContract, encoded);
        console.log("remote dispatch return %s", result);
        outboundLaneNonce.latest_generated_nonce += 1;
        return outboundLaneNonce.latest_generated_nonce;
    }
}
 
