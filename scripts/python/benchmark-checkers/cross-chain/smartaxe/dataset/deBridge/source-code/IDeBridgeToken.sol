// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20Upgradeable.sol";
import "./IERC20Permit.sol";

interface IDeBridgeToken is IERC20Upgradeable, IERC20Permit {
    function mint(address _receiver, uint256 _amount) external;

    function burn(uint256 _amount) external;
}