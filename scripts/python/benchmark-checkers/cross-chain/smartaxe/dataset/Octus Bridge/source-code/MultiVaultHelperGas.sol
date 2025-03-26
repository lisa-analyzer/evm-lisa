// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;


import "../storage/MultiVaultStorage.sol";


contract MultiVaultHelperGas {
    modifier drainGas() {
        _;

        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        address payable gasDonor = payable(s.gasDonor);

        if (gasDonor != address(0)) {
            (bool sent,) = gasDonor.call{value: address(this).balance}("");

            require(sent);
        }
    }
}