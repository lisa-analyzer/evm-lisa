// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/arbitrum/CrossChainEnabledArbitrumL2.sol)

pragma solidity ^0.8.4;

import "../CrossChainEnabled.sol";
import "./LibArbitrumL2.sol";

/**
 * @dev https://arbitrum.io/[Arbitrum] specialization or the
 * {CrossChainEnabled} abstraction the L2 side (arbitrum).
 *
 * This version should only be deployed on L2 to process cross-chain messages
 * originating from L1, or to send cross-chain messages from L2 to L1. For
 * the other side, use {CrossChainEnabledArbitrumL1}.
 *
 * Arbitrum L2 includes the `ArbSys` contract at a fixed address. Therefore,
 * this specialization of {CrossChainEnabled} does not include a constructor.
 *
 * _Available since v4.6._
 */
abstract contract CrossChainEnabledArbitrumL2 is CrossChainEnabled {
    event L2ToL1TxSubmitted(uint256 indexed crossChainTxId);

    /**
     * @dev see {CrossChainEnabled-_isCrossChain}
     */
    function _isCrossChain() internal view virtual override returns (bool) {
        return LibArbitrumL2.isCrossChain(LibArbitrumL2.ARBSYS);
    }

    /**
     * @dev see {CrossChainEnabled-_crossChainSender}
     */
    function _crossChainSender() internal view virtual override onlyCrossChain returns (address) {
        return LibArbitrumL2.crossChainSender(LibArbitrumL2.ARBSYS);
    }

    /**
     * @dev see {CrossChainEnabled-_sendCrossChainMessage}
     *
     * NOTE: Emits a L2ToL1TxSubmitted with a unique Id representing the L2/L1 transaction.
     */
    function _sendCrossChainMessage(
        address destination,
        bytes memory data,
        bytes memory crossChainTxParams
    ) internal virtual override {
        uint256 crossChainTxId = LibArbitrumL2.sendCrossChainMessage(
            LibArbitrumL2.ARBSYS,
            destination,
            data,
            crossChainTxParams
        );

        emit L2ToL1TxSubmitted(crossChainTxId);
    }
}
