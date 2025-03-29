// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./TransparentUpgradeableProxy.sol";
import "./ProxyAdmin.sol";

contract TransparentUpgradeableProxyHelper is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, admin_, _data) {}
}

contract ProxyAdminHelper is ProxyAdmin {}
