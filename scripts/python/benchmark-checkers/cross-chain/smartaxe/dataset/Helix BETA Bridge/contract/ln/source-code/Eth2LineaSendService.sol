// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interface/ILineaMessageService.sol";
import "../base/LnAccessController.sol";
import "../interface/ILowLevelMessager.sol";

// from ethereum to linea messager
contract Eth2LineaSendService is ILowLevelMessageSender, LnAccessController {
    uint256 immutable public REMOTE_CHAINID;
    ILineaMessageService public messageService;
    address public remoteMessager;

    mapping(address=>address) public appPairs;

    constructor(address _dao, address _messageService, uint256 _remoteChainId) {
        _initialize(_dao);
        messageService = ILineaMessageService(_messageService);
        REMOTE_CHAINID = _remoteChainId;
    }

    function setRemoteMessager(address _remoteMessager) onlyDao external {
        remoteMessager = _remoteMessager;
    }

    function registerRemoteReceiver(uint256 _remoteChainId, address _remoteBridge) onlyWhiteListCaller external {
        require(_remoteChainId == REMOTE_CHAINID, "invalid remote chainId");
        appPairs[msg.sender] = _remoteBridge;
    }

    function sendMessage(uint256 _remoteChainId, bytes memory _message, bytes memory) onlyWhiteListCaller external payable {
        require(_remoteChainId == REMOTE_CHAINID, "invalid remote chainId");
        address remoteAppAddress = appPairs[msg.sender];
        require(remoteAppAddress != address(0), "app not registered");

        bytes memory remoteReceiveCall = abi.encodeWithSelector(
            ILowLevelMessageReceiver.recvMessage.selector,
            msg.sender,
            remoteAppAddress,
            _message
        );
        messageService.sendMessage{value: msg.value}(
            remoteMessager,
            msg.value,
            remoteReceiveCall
        );
    }
}
