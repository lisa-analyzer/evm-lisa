// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
    @title Interface for handler that handles generic deposits and deposit executions.
    @author Router Protocol.
 */
interface IGenericHandler {

    function genericDeposit(
        bytes32 _resourceID,
        uint8 _destChainID,
        uint64 _nonce,
        address _srcAddress,
        bytes4 _selector,
        bytes calldata _data,
        bytes32 _hash
    ) external;

    function executeProposal( bytes calldata data) external;
}