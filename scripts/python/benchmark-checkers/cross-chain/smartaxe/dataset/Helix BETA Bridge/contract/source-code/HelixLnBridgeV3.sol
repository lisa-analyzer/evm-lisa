// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@zeppelin-solidity/contracts/proxy/utils/Initializable.sol";
import "./base/LnBridgeSourceV3.sol";
import "./base/LnBridgeTargetV3.sol";
import "../interfaces/IMessager.sol";

contract HelixLnBridgeV3 is Initializable, LnBridgeSourceV3, LnBridgeTargetV3 {
    struct MessagerService {
        address sendService;
        address receiveService;
    }

    // remoteChainId => messager
    mapping(uint256=>MessagerService) public messagers;

    receive() external payable {}

    function initialize(address dao) public initializer {
        _initialize(dao);
    }

    // the remote endpoint is unique, if we want multi-path to remote endpoint, then the messager should support multi-path
    function setSendService(uint256 _remoteChainId, address _remoteBridge, address _service) external onlyDao {
        messagers[_remoteChainId].sendService = _service;
        ILowLevelMessageSender(_service).registerRemoteReceiver(_remoteChainId, _remoteBridge);
    }

    function setReceiveService(uint256 _remoteChainId, address _remoteBridge, address _service) external onlyDao {
        messagers[_remoteChainId].receiveService = _service;
        ILowLevelMessageReceiver(_service).registerRemoteSender(_remoteChainId, _remoteBridge);
    }

    function _sendMessageToSource(uint256 _remoteChainId, bytes memory _payload, uint256 feePrepaid, bytes memory _extParams) whenNotPaused internal override {
        address sendService = messagers[_remoteChainId].sendService;
        require(sendService != address(0), "invalid messager");
        ILowLevelMessageSender(sendService).sendMessage{value: feePrepaid}(_remoteChainId, _payload, _extParams);
    }

    function _verifyRemote(uint256 _remoteChainId) whenNotPaused internal view override {
        address receiveService = messagers[_remoteChainId].receiveService;
        require(receiveService == msg.sender, "invalid messager");
    }
}

