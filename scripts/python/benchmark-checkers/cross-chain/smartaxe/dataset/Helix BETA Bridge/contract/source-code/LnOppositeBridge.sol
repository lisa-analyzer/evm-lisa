// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@zeppelin-solidity/contracts/proxy/utils/Initializable.sol";
import "./base/LnAccessController.sol";
import "./base/LnOppositeBridgeSource.sol";
import "./base/LnOppositeBridgeTarget.sol";
import "./interface/ILowLevelMessager.sol";

contract LnOppositeBridge is Initializable, LnAccessController, LnOppositeBridgeSource, LnOppositeBridgeTarget {
    struct MessagerService {
        address sendService;
        address receiveService;
    }
    mapping(uint256=>MessagerService) public messagers;

    receive() external payable {}

    function initialize(address _dao) public initializer {
        _initialize(_dao);
        _updateFeeReceiver(_dao);
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function pause() external onlyOperator {
        _pause();
    }

    function setSendService(uint256 _remoteChainId, address _remoteBridge, address _service) external onlyDao {
        messagers[_remoteChainId].sendService = _service;
        ILowLevelMessageSender(_service).registerRemoteReceiver(_remoteChainId, _remoteBridge);
    }

    function setReceiveService(uint256 _remoteChainId, address _remoteBridge, address _service) external onlyDao {
        messagers[_remoteChainId].receiveService = _service;
        ILowLevelMessageReceiver(_service).registerRemoteSender(_remoteChainId, _remoteBridge);
    }

    function updateFeeReceiver(address _receiver) external onlyDao {
        _updateFeeReceiver(_receiver);
    }

    function setTokenInfo(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _protocolFee,
        uint112 _penaltyLnCollateral,
        uint8 _sourceDecimals,
        uint8 _targetDecimals
    ) external onlyDao {
        _setTokenInfo(
            _remoteChainId,
            _sourceToken,
            _targetToken,
            _protocolFee,
            _penaltyLnCollateral,
            _sourceDecimals,
            _targetDecimals
        );
    }

    function _sendMessageToTarget(uint256 _remoteChainId, bytes memory _payload, bytes memory _extParams) whenNotPaused internal override {
        address sendService = messagers[_remoteChainId].sendService;
        require(sendService != address(0), "invalid messager");
        ILowLevelMessageSender(sendService).sendMessage{value: msg.value}(_remoteChainId, _payload, _extParams);
    }

    function _verifyRemote(uint256 _remoteChainId) whenNotPaused internal view override {
        address receiveService = messagers[_remoteChainId].receiveService;
        require(receiveService == msg.sender, "invalid messager");
    }
}

