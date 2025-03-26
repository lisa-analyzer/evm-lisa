// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import "./MockMessageVerifier.sol";
import "../interfaces/ICrossChainFilter.sol";
import "../interfaces/IInboundLane.sol";
import "hardhat/console.sol";

contract MockInboundLane is MockMessageVerifier {
    IInboundLane.InboundLaneNonce public inboundLaneNonce;
    constructor(
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition
    ) MockMessageVerifier(
        _thisChainPosition,
        _thisLanePosition,
        _bridgedChainPosition,
        _bridgedLanePosition
    ) {
    }

    function mock_dispatch(address sender, address targetContract, bytes calldata encoded) external returns(bool) {
        if (targetContract == address(0)) {
            return false;
        }
        bool filter = ICrossChainFilter(targetContract).cross_chain_filter(bridgedChainPosition, bridgedLanePosition, sender, encoded);

        if (filter) {
            (bool result, ) = targetContract.call(encoded);
            inboundLaneNonce.last_delivered_nonce += 1;
            console.log("inbound call return %s, target %s", result, targetContract);
            return result;
        }
        return false;
    }

    function test_dispatch(address targetContract, bytes calldata encoded) external {
        (bool result, ) = targetContract.call(encoded);
        require(result, "test_dispatch failed");
    }
}
 
