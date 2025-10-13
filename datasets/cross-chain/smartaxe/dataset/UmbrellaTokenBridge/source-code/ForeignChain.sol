// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Chain.sol";

/// @dev contract for foreign chains
contract ForeignChain is Chain {
    error NotSupported();

    /// @param _contractRegistry Registry address
    /// @param _padding required "space" between blocks in seconds
    /// @param _requiredSignatures number of required signatures for accepting consensus submission
    constructor(
        IRegistry _contractRegistry,
        uint32 _padding,
        uint16 _requiredSignatures,
        bool _allowForMixedType
    ) Chain(_contractRegistry, _padding, _requiredSignatures, _allowForMixedType) {
        // no additional configuration needed
    }

    /// @inheritdoc BaseChain
    function isForeign() external pure override returns (bool) {
        return true;
    }

    /// @inheritdoc Chain
    /// @notice this method is made to be compatible with MasterChain, but it does not return full data eg validators
    /// data will be missing.
    /// @return blockNumber `block.number`
    /// @return timePadding `this.padding`
    /// @return lastDataTimestamp timestamp for last submitted consensus
    /// @return lastId ID of last submitted consensus
    /// @return nextLeader will be always address(0)
    /// @return nextBlockId block ID for `block.timestamp + padding`
    /// @return validators array will be always empty
    /// @return powers array will be always empty
    /// @return locations array will be always empty
    /// @return staked total UMB staked by validators
    /// @return minSignatures `this.requiredSignatures`
    function getStatus() external view override returns(
        uint256 blockNumber,
        uint32 timePadding,
        uint32 lastDataTimestamp,
        uint32 lastId,
        address nextLeader,
        uint32 nextBlockId,
        address[] memory validators,
        uint256[] memory powers,
        string[] memory locations,
        uint256 staked,
        uint16 minSignatures
    ) {
        ConsensusData memory data = _consensusData;

        blockNumber = block.number;
        timePadding = data.padding;
        lastId = data.lastTimestamp;
        lastDataTimestamp = lastId;
        minSignatures = _REQUIRED_SIGNATURES;

        staked = stakingBank.totalSupply();
        uint256 numberOfValidators = 0;
        powers = new uint256[](numberOfValidators);
        validators = new address[](numberOfValidators);
        locations = new string[](numberOfValidators);
        nextLeader = address(0);

        unchecked {
            // we will not overflow with timestamp in a lifetime
            nextBlockId = lastId + data.padding + 1;
        }
    }

    function getLeaderIndex(uint256, uint256) public pure override returns (uint256) {
        revert NotSupported();
    }

    function getLeaderAddressAtTime(uint256) public pure override returns (address) {
        revert NotSupported();
    }
}