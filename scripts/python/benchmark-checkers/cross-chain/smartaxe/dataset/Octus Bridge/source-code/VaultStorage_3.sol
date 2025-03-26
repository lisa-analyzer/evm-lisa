// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IVault.sol";

abstract contract VaultStorage is IVault, Initializable, ReentrancyGuard {
    uint256 constant MAX_BPS = 10_000;

    // Bridge
    // - Bridge address, used to verify relay's signatures. Read more on `saveWithdraw`
    address public override bridge;
    // - Bridge EVER-EVM event configuration
    // NOTE: Some variables have "_" postfix and not declared as a "public override"
    // Instead they have explicit corresponding getter
    // It's a compiler issue, described here - https://github.com/ethereum/solidity/issues/11826
    EverscaleAddress configuration_;

    function configuration()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return configuration_;
    }

    // - Withdrawal receipt IDs, used to prevent double spending
    mapping(bytes32 => bool) public override withdrawalIds;
    // - Rewards address in Everscale, receives fees
    EverscaleAddress rewards_;

    function rewards()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return rewards_;
    }

    // Ownership
    // - Governance
    address public override governance;
    // - Pending governance, used for 2-step governance transfer
    address pendingGovernance;
    // - Guardian, responsible for security actions
    address public override guardian;
    // - Management, responsible for managing strategies
    address public override management;

    // Token
    // - Vault's token
    address public override token;
    // - Decimals on corresponding token in the Everscale network
    uint256 public override targetDecimals;
    // - Decimals of `token`
    uint256 public override tokenDecimals;

    // Fees
    // - Deposit fee, in BPS
    uint256 public override depositFee;
    // - Withdraw fee, in BPS
    uint256 public override withdrawFee;

    // Security
    // - Emergency shutdown, most of operations are unavailable in emergency mode
    bool public override emergencyShutdown;

    // STORAGE UPDATE 1
    // - Total fees
    uint256 public override fees;
}