// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interface/ILnBridgeSourceV3.sol";
import "../../utils/TokenTransferHelper.sol";

contract LnBridgeTargetV3 {
    uint256 constant public SLASH_EXPIRE_TIME = 60 * 60;
    // timestamp: the time when transfer filled, this is also the flag that the transfer is filled(relayed or slashed)
    // provider: the transfer lnProvider
    struct FillTransfer {
        uint64 timestamp;
        address provider;
    }

    // lockTimestamp: the time when the transfer start from source chain
    // the lockTimestamp is verified on source chain
    // 1. lockTimestamp verified successed: slasher get the transfer amount, fee and penalty on source chain
    // 2. lockTimestamp verified failed:    slasher get the transfer amount, but the fee and penalty back to the provider
    // sourceAmount: the send amount on source chain
    struct SlashInfo {
        uint256 remoteChainId;
        address slasher;
    }

    struct RelayParams {
        uint256 remoteChainId;
        address provider;
        address sourceToken;
        address targetToken;
        uint112 sourceAmount;
        uint112 targetAmount;
        address receiver;
        uint256 timestamp;
    }

    // transferId => FillTransfer
    mapping(bytes32 => FillTransfer) public fillTransfers;
    // transferId => SlashInfo
    mapping(bytes32 => SlashInfo) public slashInfos;

    event TransferFilled(bytes32 transferId, address provider);
    event SlashRequest(bytes32 transferId, uint256 remoteChainId, address provider, address sourceToken, address targetToken, address slasher);
    event LiquidityWithdrawRequested(bytes32[] transferIds, uint256 remoteChainId);

    function _sendMessageToSource(uint256 _remoteChainId, bytes memory _payload, uint256 feePrepaid, bytes memory _extParams) internal virtual {}

    // relay a tx, usually called by lnProvider
    // 1. update the fillTransfers storage to save the relay proof
    // 2. transfer token from lnProvider to the receiver
    function relay(
        RelayParams calldata _params,
        bytes32 _expectedTransferId,
        bool _relayBySelf
    ) external payable {
        // _relayBySelf = true to protect that the msg.sender don't relay for others
        // _relayBySelf = false to allow that lnProvider can use different account between source chain and target chain
        require(!_relayBySelf || _params.provider == msg.sender, "invalid provider");
        bytes32 transferId = keccak256(abi.encodePacked(
           _params.remoteChainId,
           block.chainid,
           _params.provider,
           _params.sourceToken,
           _params.targetToken,
           _params.receiver,
           _params.sourceAmount,
           _params.targetAmount,
           _params.timestamp
        ));
        require(_expectedTransferId == transferId, "check expected transferId failed");
        FillTransfer memory fillTransfer = fillTransfers[transferId];
        // Make sure this transfer was never filled before 
        require(fillTransfer.timestamp == 0, "transfer has been filled");
        fillTransfers[transferId] = FillTransfer(uint64(block.timestamp), _params.provider);

        if (_params.targetToken == address(0)) {
            require(msg.value == _params.targetAmount, "invalid amount");
            TokenTransferHelper.safeTransferNative(_params.receiver, _params.targetAmount);
        } else {
            require(msg.value == 0, "value not need");
            TokenTransferHelper.safeTransferFrom(_params.targetToken, msg.sender, _params.receiver, uint256(_params.targetAmount));
        }
        emit TransferFilled(transferId, _params.provider);
    }

    // slash a tx when timeout
    // 1. update fillTransfers and slashInfos storage to save slash proof
    // 2. transfer tokens from slasher to receiver for this tx
    // 3. send a cross-chain message to source chain to withdraw the amount, fee and penalty from lnProvider
    function requestSlashAndRemoteRelease(
        RelayParams calldata _params,
        bytes32 _expectedTransferId,
        uint256 _feePrepaid,
        bytes memory _extParams
    ) external payable {
        bytes32 transferId = keccak256(abi.encodePacked(
           _params.remoteChainId,
           block.chainid,
           _params.provider,
           _params.sourceToken,
           _params.targetToken,
           _params.receiver,
           _params.sourceAmount,
           _params.targetAmount,
           _params.timestamp
        ));
        require(_expectedTransferId == transferId, "check expected transferId failed");

        FillTransfer memory fillTransfer = fillTransfers[transferId];
        require(fillTransfer.timestamp == 0, "transfer has been filled");

        // suppose source chain and target chain has the same block timestamp
        // event the timestamp is not sync exactly, this TIMEOUT is also verified on source chain
        require(_params.timestamp < block.timestamp - SLASH_EXPIRE_TIME, "time not expired");
        fillTransfers[transferId] = FillTransfer(uint64(block.timestamp), _params.provider);
        slashInfos[transferId] = SlashInfo(_params.remoteChainId, msg.sender);

        if (_params.targetToken == address(0)) {
            require(msg.value == _params.targetAmount + _feePrepaid, "invalid value");
            TokenTransferHelper.safeTransferNative(_params.receiver, _params.targetAmount);
        } else {
            require(msg.value == _feePrepaid, "value too large");
            TokenTransferHelper.safeTransferFrom(_params.targetToken, msg.sender, _params.receiver, uint256(_params.targetAmount));
        }
        bytes memory message = encodeSlashRequest(transferId, _params.provider, msg.sender);
        _sendMessageToSource(_params.remoteChainId, message, _feePrepaid, _extParams);
        emit SlashRequest(transferId, _params.remoteChainId, _params.provider, _params.sourceToken, _params.targetToken, msg.sender);
    }

    // it's allowed to retry a slash tx because the cross-chain message may fail on source chain
    // But it's required that the params must not be modified, it read from the storage saved
    function retrySlash(bytes32 transferId, bytes memory _extParams) external payable {
        FillTransfer memory fillTransfer = fillTransfers[transferId];
        require(fillTransfer.timestamp > 0, "transfer not filled");
        SlashInfo memory slashInfo = slashInfos[transferId];
        require(slashInfo.slasher == msg.sender, "invalid slasher");
        // send message
        bytes memory message = encodeSlashRequest(transferId, fillTransfer.provider, slashInfo.slasher);
        _sendMessageToSource(slashInfo.remoteChainId, message, msg.value, _extParams);
    }

    // can't withdraw for different providers each time
    // the size of the _transferIds should not be too large to be processed outof gas on source chain
    function requestWithdrawLiquidity(
        uint256 _remoteChainId,
        bytes32[] calldata _transferIds,
        address _provider,
        bytes memory _extParams
    ) external payable {
        for (uint i = 0; i < _transferIds.length; i++) {
            bytes32 transferId = _transferIds[i];
            FillTransfer memory fillTransfer = fillTransfers[transferId];
            // make sure that each transfer has the same provider
            require(fillTransfer.provider == _provider, "provider invalid");
        }
        bytes memory message = encodeWithdrawLiquidityRequest(_transferIds, _provider);
        _sendMessageToSource(_remoteChainId, message, msg.value, _extParams);
        emit LiquidityWithdrawRequested(_transferIds, _remoteChainId);
    }

    function encodeWithdrawLiquidityRequest(
        bytes32[] calldata _transferIds,
        address _provider
    ) public view returns(bytes memory message) {
        message = abi.encodeWithSelector(
           ILnBridgeSourceV3.withdrawLiquidity.selector,
           _transferIds,
           block.chainid,
           _provider
        );
    }

    function encodeSlashRequest(
        bytes32 _transferId,
        address _provider,
        address _slasher
    ) public view returns(bytes memory message) {
        message = abi.encodeWithSelector(
           ILnBridgeSourceV3.slash.selector,
           block.chainid,
           _transferId,
           _provider,
           _slasher
        );
    }
}

