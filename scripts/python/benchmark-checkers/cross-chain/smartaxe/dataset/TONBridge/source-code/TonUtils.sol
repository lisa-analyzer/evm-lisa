// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface TonUtils {
    struct TonAddress {
        int8 workchain;
        bytes32 address_hash;
    }
    struct TonTxID {
        TonAddress address_; // sender user address in TON network
        bytes32 tx_hash; // transaction hash on TON bridge smart contract
        uint64 lt; // transaction LT (logical time) on TON bridge smart contract
    }

  struct SwapData {
        address receiver; // user's EVM-address to receive wrapped TONs
        uint64 amount; // nanotons amount to receive in EVM-network
        TonTxID tx;
  }
  struct Signature {
        address signer; // oracle's EVM-address
        bytes signature; // oracle's signature
  }

}
