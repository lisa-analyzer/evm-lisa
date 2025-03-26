// contracts/BridgeSetup.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./NFTBridgeGovernance.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

contract NFTBridgeSetup is NFTBridgeSetters, ERC1967Upgrade {
    function setup(
        address implementation,
        uint16 chainId,
        address wormhole,
        uint16 governanceChainId,
        bytes32 governanceContract,
        address tokenImplementation
    ) public {
        setChainId(chainId);

        setWormhole(wormhole);

        setGovernanceChainId(governanceChainId);
        setGovernanceContract(governanceContract);

        setTokenImplementation(tokenImplementation);

        // Register Solana contract
        setBridgeImplementation(1, 0x0def15a24423e1edd1a5ab16f557b9060303ddbab8c803d2ee48f4b78a1cfd6b);

        _upgradeTo(implementation);
    }
}