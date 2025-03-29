// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


contract ChainId {
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}