// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@zeppelin-solidity/contracts/proxy/utils/Initializable.sol";
import "@zeppelin-solidity/contracts/security/Pausable.sol";
import "../../../interfaces/IMessager.sol";
import "../../../utils/AccessController.sol";
import "../../../utils/DailyLimit.sol";
import "../../../utils/TokenTransferHelper.sol";

// The Base contract for xToken protocol
// Backing or Issuing contract will inherit the contract.
// This contract define the access authorization, the message channel
contract xTokenBridgeBase is Initializable, Pausable, AccessController, DailyLimit {
    uint256 constant public TRANSFER_UNFILLED = 0x00;
    uint256 constant public TRANSFER_DELIVERED = 0x01;
    uint256 constant public TRANSFER_REFUNDED = 0x02;
    struct MessagerService {
        address sendService;
        address receiveService;
    }

    struct RequestInfo {
        bool isRequested;
        bool hasRefundForFailed;
    }

    // the version is to issue different xTokens for different version of bridge.
    string public version;
    // the protocol fee for each time user send transaction
    uint256 public protocolFee;
    // the reserved protocol fee in the contract
    uint256 public protocolFeeReserved;
    address public guard;
    // remoteChainId => info
    mapping(uint256 => MessagerService) public messagers;

    // transferId => RequestInfo
    mapping(bytes32 => RequestInfo) public requestInfos;

    // transferId => result
    // 1. 0x01: filled by receive message
    // 2. 0x02: filled by refund operation
    mapping(bytes32 => uint256) public filledTransfers;

    // must be called by message service configured
    modifier calledByMessager(uint256 _remoteChainId) {
        address receiveService = messagers[_remoteChainId].receiveService;
        require(receiveService == msg.sender, "invalid messager");
        _;
    }

    receive() external payable {}

    function initialize(address _dao, string calldata _version) public initializer {
        _initialize(_dao);
        version = _version;
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function pause() external onlyOperator {
        _pause();
    }

    function setProtocolFee(uint256 _protocolFee) external onlyOperator {
        protocolFee = _protocolFee;
    }

    function setSendService(uint256 _remoteChainId, address _remoteBridge, address _service) external onlyDao {
        messagers[_remoteChainId].sendService = _service;
        ILowLevelMessageSender(_service).registerRemoteReceiver(_remoteChainId, _remoteBridge);
    }

    function setReceiveService(uint256 _remoteChainId, address _remoteBridge, address _service) external onlyDao {
        messagers[_remoteChainId].receiveService = _service;
        ILowLevelMessageReceiver(_service).registerRemoteSender(_remoteChainId, _remoteBridge);
    }

    function withdrawProtocolFee(address _receiver, uint256 _amount) external onlyDao {
        require(_amount <= protocolFeeReserved, "not enough fee");
        protocolFeeReserved -= _amount;
        TokenTransferHelper.safeTransferNative(_receiver, _amount);
    }

    function _sendMessage(
        uint256 _remoteChainId,
        bytes memory _payload,
        uint256 _feePrepaid,
        bytes memory _extParams
    ) internal whenNotPaused {
        MessagerService memory service = messagers[_remoteChainId];
        require(service.sendService != address(0), "bridge not configured");
        uint256 _protocolFee = protocolFee;
        protocolFeeReserved += _protocolFee;
        ILowLevelMessageSender(service.sendService).sendMessage{value: _feePrepaid - _protocolFee}(
            _remoteChainId,
            _payload,
            _extParams
        );
    }

    // request a cross-chain transfer
    // 1. lock and remote issue
    // 2. burn and remote unlock
    // save the transferId if not exist, else revert
    function _requestTransfer(bytes32 _transferId) internal {
        require(requestInfos[_transferId].isRequested == false, "request exist");
        requestInfos[_transferId].isRequested = true;
    }

    // receive a cross-chain refund request
    // 1. request must be exist
    // 2. can't repeat
    function _handleRefund(bytes32 _transferId) internal {
        RequestInfo memory requestInfo = requestInfos[_transferId];
        require(requestInfo.isRequested == true, "request not exist");
        require(requestInfo.hasRefundForFailed == false, "request has been refund");
        requestInfos[_transferId].hasRefundForFailed = true;
    }

    // receive a cross-chain request
    // must not filled
    // fill the transfer with delivered transfer type
    function _handleTransfer(bytes32 _transferId) internal {
        require(filledTransfers[_transferId] == TRANSFER_UNFILLED, "!conflict");
        filledTransfers[_transferId] = TRANSFER_DELIVERED;
    }

    // request a cross-chain refund
    // 1. can retry
    // 2. can't be filled by delivery
    function _requestRefund(bytes32 _transferId) internal {
        uint256 filledTransfer = filledTransfers[_transferId];
        // already fill by refund, retry request
        if (filledTransfer == TRANSFER_REFUNDED) {
            return;
        }
        require(filledTransfer == TRANSFER_UNFILLED, "!conflict");
        filledTransfers[_transferId] = TRANSFER_REFUNDED;
    }

    function getTransferId(
        uint256 _nonce,
        uint256 _sourceChainId,
        uint256 _targetChainId,
        address _originalToken,
        address _originalSender,
        address _recipient,
        uint256 _amount
    ) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_nonce, _sourceChainId, _targetChainId, _originalToken, _originalSender, _recipient, _amount));
    }

    // settings
    function updateGuard(address _guard) external onlyDao {
        guard = _guard;
    }

    function setDailyLimit(address _token, uint256 _dailyLimit) external onlyDao {
        _setDailyLimit(_token, _dailyLimit);
    }
}

