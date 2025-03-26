// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/V4/token/ERC20/IERC20.sol";

contract BalanceResolver {
    function balanceOf(IERC20 token, address[] memory addresses) external view returns (uint256[] memory balances) {
        balances = new uint256[](addresses.length);

        unchecked {
            for (uint i = 0; i < addresses.length; i++) {
                balances[i] = token.balanceOf(addresses[i]);
            }
        }
    }
}