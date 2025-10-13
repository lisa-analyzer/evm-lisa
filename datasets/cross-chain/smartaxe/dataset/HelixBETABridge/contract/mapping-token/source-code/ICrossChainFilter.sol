// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title A interface for message layer to filter unsafe message
 * @author echo
 * @notice The app layer must implement the interface `ICrossChainFilter`
 */
interface ICrossChainFilter {
    /**
     * @notice Verify the source sender and payload of source chain messages,
     * Generally, app layer cross-chain messages require validation of sourceAccount
     * @param bridgedChainPosition The source chain position which send the message
     * @param bridgedLanePosition The source lane position which send the message
     * @param sourceAccount The source contract address which send the message
     * @param payload The calldata which encoded by ABI Encoding
     * @return Can call target contract if returns true
     */
    function cross_chain_filter(uint32 bridgedChainPosition, uint32 bridgedLanePosition, address sourceAccount, bytes calldata payload) external view returns (bool);
}
