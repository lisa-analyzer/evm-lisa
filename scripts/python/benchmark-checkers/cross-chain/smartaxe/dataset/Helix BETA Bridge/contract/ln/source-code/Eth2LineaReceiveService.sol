// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interface/ILineaMessageService.sol";
import "../base/LnAccessController.sol";
import "../interface/ILowLevelMessager.sol";

// from ethereum to linea messager
contract Eth2LineaReceiveService is ILowLevelMessageReceiver, LnAccessController {
    uint256 immutable public REMOTE_CHAINID;
    ILineaMessageService public messageService;
    address public remoteMessager;

    mapping(address=>address) public appPairs;

    modifier onlyRemoteBridge() {
        require(msg.sender == address(messageService), "invalid msg.sender");
        require(messageService.sender() == remoteMessager, "invalid remote caller");
        _;
    }

    constructor(address _dao, address _messageService, uint256 _remoteChainId) {
        _initialize(_dao);
        messageService = ILineaMessageService(_messageService);
        REMOTE_CHAINID = _remoteChainId;
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
    
