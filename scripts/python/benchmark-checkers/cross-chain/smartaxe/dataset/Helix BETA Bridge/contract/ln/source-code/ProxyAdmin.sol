// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@zeppelin-solidity/contracts/proxy/transparent/ProxyAdmin.sol";

contract HelixProxyAdmin is ProxyAdmin {
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }
}
