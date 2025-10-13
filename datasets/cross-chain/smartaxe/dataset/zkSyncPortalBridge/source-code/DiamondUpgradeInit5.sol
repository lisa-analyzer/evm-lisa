pragma solidity ^0.8.13;

// SPDX-License-Identifier: MIT



import "./Config.sol";
import "./Mailbox.sol";
import "./Diamond.sol";
import "./L2ContractHelper.sol";
import "./L2ContractAddresses.sol";

/// @author Matter Labs
contract DiamondUpgradeInit5 is MailboxFacet {
    function forceDeploy(
        bytes calldata _upgradeDeployerCalldata,
        bytes calldata _upgradeSystemContractsCalldata,
        bytes[] calldata _factoryDeps
    ) external payable returns (bytes32) {
        // 1. Update bytecode for the deployer smart contract
        _requestL2Transaction(
            L2_FORCE_DEPLOYER_ADDR,
            L2_DEPLOYER_SYSTEM_CONTRACT_ADDR,
            0,
            _upgradeDeployerCalldata,
            72000000,
            REQUIRED_L2_GAS_PRICE_PER_PUBDATA,
            _factoryDeps,
            true,
            address(0)
        );

        // 2. Redeploy system contracts by one priority transaction
        _requestL2Transaction(
            L2_FORCE_DEPLOYER_ADDR,
            L2_DEPLOYER_SYSTEM_CONTRACT_ADDR,
            0,
            _upgradeSystemContractsCalldata,
            72000000,
            REQUIRED_L2_GAS_PRICE_PER_PUBDATA,
            _factoryDeps,
            true,
            address(0)
        );

        return Diamond.DIAMOND_INIT_SUCCESS_RETURN_VALUE;
    }
}