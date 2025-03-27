// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity ^0.8.17;

import "./GovBridgeV2.sol";

/**
 * @notice [WIP] GovBridge PoS version.
 */
contract GovBridgeV2PoS is GovBridgeV2 {

    mapping(bytes32 => bool) private _processed;

    event EpochRatingsApplied(
        bytes32 epochHash,
        bytes32[] teamCollaterals,
        uint256[] teamRatings,
        uint8 ratingsDiff,
        uint32 epochNum,
        uint64 version
    );

    function setRatings(ReceiveParams calldata params) external {
        verifyEpoch(currentEpoch, params);
        bytes memory payload = Merkle.prove(params.merkleProof, Block.txRootHash(params.blockHeader));
        // TODO payload different with receiveparams - epoch hash should be on fixed position
        bytes32 epochHash;
        assembly {
            epochHash := mload(add(payload, add(0, 0x20))) // get first 32 bytes from 0 element
        }

        require(_processed[epochHash] == false, "GovBridgeV2PoS: raitings already set");
        _processed[epochHash] = true;

        // Emulate raiting calculation...
        uint256 size = 24; // amount oracles on cdp stand (20 in epoch + 4)
        bytes32[] memory teamCollaterals = new bytes32[](size);
        uint256[] memory teamRatings = new uint256[](size);
        uint8 ratingsDiff = 1;
        for (uint256 i = 0; i<size; i++) {
            teamCollaterals[i] = bytes32(uint(keccak256(abi.encodePacked(i, msg.sender, block.number))) % (20000000000000000000-10000000000000000));
            teamRatings[i] = uint(keccak256(abi.encodePacked(i, msg.sender, block.number))) % (20-10); // random btw 10 - 20
        }

        emit EpochRatingsApplied(epochHash, teamCollaterals, teamRatings, ratingsDiff, currentEpoch.epochNum, nextProtocolVersion);
    }
}
