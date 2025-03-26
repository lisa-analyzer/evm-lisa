// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interface/IScrollMessenger.sol";
import "../base/LnAccessController.sol";
import "../interface/ILowLevelMessager.sol";

// from ethereum to arbitrum messager
contract Eth2ScrollReceiveService is ILowLevelMessageReceiver, LnAccessController {
    uint256 immutable public REMOTE_CHAINID;
    address immutable public scrollMessager;
    address public remoteMessager;

    mapping(address=>address) public appPairs;

    modifier onlyRemoteBridge() {
        require(msg.sender == scrollMessager, "invalid caller");
        require(remoteMessager == IScrollMessenger(scrollMessager).xDomainMessageSender(), "invalid remote caller");
        _;
    }

    constructor(address _dao, address _scrollMessager, uint256 _remoteChainId) {
        _initialize(_dao);
        REMOTE_CHAINID = _remoteChainId;
        scrollMessager = _scrollMessager;
    }

    function setRemoteMessager(address _remoteMessager) onlyDao external {
        remoteMessager = _remoteMessager;
    }

    function registerRemoteSender(uint256 _remoteChainId, address _remoteBridge) onlyWhiteListCaller external {
        require(_remoteChainId == REMOTE_CHAINID, "invalid remote chainId");
        appPairs[msg.sender] = _remoteBridge;
    }

    function recvMessage(address _remoteApp, address _localApp, bytes memory _message) onlyRemoteBridge external {
        address remoteAppAddress = appPairs[_localApp];
        require(remoteAppAddress == _remoteApp, "invalid remote app");
        (bool result,) = _localApp.call(_message);
        require(result == true, "local call failed");
    }
}

