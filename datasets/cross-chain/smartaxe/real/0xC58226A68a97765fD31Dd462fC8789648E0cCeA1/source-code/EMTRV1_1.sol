// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import { MeterERC20 } from "./EMTR.sol";
import { Pausable } from "./Pausable.sol";
import { Rescuable } from "./Rescuable.sol";


/**
 * @title MeterERC20V1_1
 * @dev ERC20 Token backed by Meter
 */
contract MeterERC20V1_1 is MeterERC20, Pausable, Rescuable {

    /// @notice Send to multiple addresses using two arrays which
    ///  includes the address and the amount
    /// @param _addresses Array of addresses to send to
    /// @param _amounts Array of amounts to send
    function multiDistributeToken (address[] memory _addresses, uint[] memory _amounts)
    onlyOwner public returns(bool)
    {
        for (uint i = 0; i < _addresses.length; i++) {
            distributeToken(_addresses[i], _amounts[i]);
        }
        return true;
    }

}
