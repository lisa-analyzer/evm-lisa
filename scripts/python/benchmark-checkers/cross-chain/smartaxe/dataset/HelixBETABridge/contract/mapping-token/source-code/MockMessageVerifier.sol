// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract MockMessageVerifier {
    uint32 public immutable thisChainPosition;
    uint32 public immutable thisLanePosition;
    uint32 public immutable bridgedChainPosition;
    uint32 public immutable bridgedLanePosition;

    constructor(
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition
    ) {
        thisChainPosition = _thisChainPosition;
        thisLanePosition = _thisLanePosition;
        bridgedChainPosition = _bridgedChainPosition;
        bridgedLanePosition = _bridgedLanePosition;
    }

    function getLaneInfo() public view returns (uint256, uint256, uint256, uint256) {
        return (thisChainPosition, thisLanePosition, bridgedChainPosition, bridgedLanePosition);
    }
    
    function encodeMessageKey(uint64 nonce) public view returns (uint256) {
        return (uint256(thisChainPosition) << 160) + (uint256(thisLanePosition) << 128) + (uint256(bridgedChainPosition) << 96) + (uint256(bridgedLanePosition) << 64) + uint256(nonce);
    }
}
 
