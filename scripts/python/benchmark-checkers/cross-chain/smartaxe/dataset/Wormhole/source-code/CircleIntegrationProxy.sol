// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {ERC1967Proxy} from "./ERC1967Proxy.sol";

contract CircleIntegrationProxy is ERC1967Proxy {
    constructor(address implementation, bytes memory initData) ERC1967Proxy(implementation, initData) {}
}