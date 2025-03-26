// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../messager/Eth2ArbReceiveService.sol";

contract MockEth2ArbReceiveService is Eth2ArbReceiveService {
    constructor(address _dao, uint256 _remoteChainId) Eth2ArbReceiveService(_dao, _remoteChainId) {}

    function setRemoteMessagerAlias(address _remoteMessagerAlias) external {
        remoteMessagerAlias = _remoteMessagerAlias;
    }
}
