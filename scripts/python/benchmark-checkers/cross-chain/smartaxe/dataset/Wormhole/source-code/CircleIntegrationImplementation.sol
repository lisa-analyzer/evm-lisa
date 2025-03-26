// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {ERC1967Upgrade} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import {CircleIntegration} from "./CircleIntegration.sol";

contract CircleIntegrationImplementation is CircleIntegration {
    function initialize() public virtual initializer {
        // this function needs to be exposed for an upgrade to pass
    }

    modifier initializer() {
        address impl = ERC1967Upgrade._getImplementation();

        require(!isInitialized(impl), "already initialized");

        setInitialized(impl);

        _;
    }

    function circleIntegrationImplementation() public pure returns (bytes32) {
        return keccak256("circleIntegrationImplementation()");
    }
}