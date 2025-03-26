// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interface/IZksyncMailbox.sol";
import "../base/LnAccessController.sol";
import "../interface/ILowLevelMessager.sol";

// from ethereum to zkSync messager
contract Eth2ZkSyncReceiveService is ILowLevelMessageReceiver, LnAccessController {
    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);
    uint256 immutable public REMOTE_CHAINID;
    IMailbox public mailbox;
    address public remoteMessagerAlias;

    mapping(address=>address) public appPairs;

    modifier onlyRemoteBridge() {
        require(msg.sender == remoteMessagerAlias, "invalid remote caller");
        _;
    }

    constructor(address _dao, address _mailbox, uint256 _remoteChainId) {
        _initialize(_dao);
        mailbox = IMailbox(_mailbox);
        REMOTE_CHAINID = _remoteChainId;
    }

    function setRemoteMessager(address _remoteMessager) onlyDao external {
        remoteMessagerAlias = address(uint160(_remoteMessager) + offset);
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

