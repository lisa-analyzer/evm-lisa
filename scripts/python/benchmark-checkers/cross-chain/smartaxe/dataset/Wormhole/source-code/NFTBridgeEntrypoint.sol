// contracts/Wormhole.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./ERC1967Proxy.sol";

contract NFTBridgeEntrypoint is ERC1967Proxy {
    constructor (address implementation, bytes memory initData)
        ERC1967Proxy(
            implementation,
            initData
        )
    {}
}