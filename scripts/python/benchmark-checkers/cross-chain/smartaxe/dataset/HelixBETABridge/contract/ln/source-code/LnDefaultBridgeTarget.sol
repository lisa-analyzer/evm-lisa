// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LnBridgeHelper.sol";

contract LnDefaultBridgeTarget {
    struct TargetProviderInfo {
        uint256 margin;
        // use this slash gas reserve to pay the slash fee if transfer filled but timeout
        uint256 slashReserveFund;
        uint64 lastExpireFillTime;
        uint64 withdrawNonce;
    }

    // providerKey => margin
    // providerKey = hash(remoteChainId, provider, sourceToken, targetToken)
    mapping(bytes32=>TargetProviderInfo) public tgtProviders;

    // if timestamp > 0, the Transfer has been relayed or slashed
    // if slasher == address(0), this FillTransfer is relayed by lnProvider
    // otherwise, this FillTransfer is slashed by slasher
    struct FillTransfer {
        uint64 timestamp;
        address slasher;
    }

    // transferId => FillTransfer
    mapping(bytes32 => FillTransfer) public fillTransfers;

    event TransferFilled(bytes32 transferId, address provider);
    event Slash(bytes32 transferId, uint256 remoteChainId, address provider, address sourceToken, address targetToken, uint256 margin, address slasher);
    event MarginUpdated(uint256 remoteChainId, address provider, address sourceToken, address targetToken, uint256 amount, uint64 withdrawNonce);
    event SlashReserveUpdated(address provider, address sourceToken, address targetToken, uint256 amount);

    modifier allowRemoteCall(uint256 _remoteChainId) {
        _verifyRemote(_remoteChainId);
        _;
    }

    function _verifyRemote(uint256 _remoteChainId) internal virtual {}

    function depositProviderMargin(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint256 _margin
    ) external payable {
        require(_margin > 0, "invalid margin");
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        TargetProviderInfo memory providerInfo = tgtProviders[providerKey];
        uint256 updatedMargin = providerInfo.margin + _margin;
        tgtProviders[providerKey].margin = updatedMargin;
        if (_targetToken == address(0)) {
            require(msg.value == _margin, "invalid margin value");
        } else {
            LnBridgeHelper.safeTransferFrom(_targetToken, msg.sender, address(this), _margin);
        }
        emit MarginUpdated(_remoteChainId, msg.sender, _sourceToken, _targetToken, updatedMargin, providerInfo.withdrawNonce);
    }

    function transferAndReleaseMargin(
        LnBridgeHelper.TransferParameter calldata _params,
        uint256 _remoteChainId,
        bytes32 _expectedTransferId
    ) external payable {
        require(_params.provider == msg.sender, "invalid provider");
        require(_params.previousTransferId == bytes32(0) || fillTransfers[_params.previousTransferId].timestamp > 0, "last transfer not filled");
        bytes32 transferId = keccak256(abi.encodePacked(
           _remoteChainId,
           block.chainid,
           _params.previousTransferId,
           _params.provider,
           _params.sourceToken,
           _params.targetToken,
           _params.receiver,
           _params.amount
        ));
        require(_expectedTransferId == transferId, "check expected transferId failed");
        FillTransfer memory fillTransfer = fillTransfers[transferId];
        // Make sure this transfer was never filled before 
        require(fillTransfer.timestamp == 0, "transfer has been filled");

        fillTransfers[transferId].timestamp = uint64(block.timestamp);
        if (block.timestamp - LnBridgeHelper.SLASH_EXPIRE_TIME > _params.timestamp) {
            bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _params.sourceToken, _params.targetToken);
            tgtProviders[providerKey].lastExpireFillTime = uint64(block.timestamp);
        }

        if (_params.targetToken == address(0)) {
            require(msg.value == _params.amount, "lnBridgeTarget:invalid amount");
            LnBridgeHelper.safeTransferNative(_params.receiver, _params.amount);
        } else {
            LnBridgeHelper.safeTransferFrom(_params.targetToken, msg.sender, _params.receiver, uint256(_params.amount));
        }
        emit TransferFilled(transferId, _params.provider);
    }

    function depositSlashFundReserve(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint256 _amount
    ) external payable {
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        TargetProviderInfo memory providerInfo = tgtProviders[providerKey];
        uint256 updatedAmount = providerInfo.slashReserveFund + _amount;
        tgtProviders[providerKey].slashReserveFund = updatedAmount;
        if (_targetToken == address(0)) {
            require(msg.value == _amount, "amount invalid");
        } else {
            LnBridgeHelper.safeTransferFrom(_targetToken, msg.sender, address(this), _amount);
        }
        emit SlashReserveUpdated(msg.sender, _sourceToken, _targetToken, updatedAmount);
    }

    // withdraw slash fund
    // provider can't withdraw until the block.timestamp overtime lastExpireFillTime for a period of time 
    function withdrawSlashFundReserve(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint256 _amount
    ) external {
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        TargetProviderInfo memory providerInfo = tgtProviders[providerKey];
        require(_amount <= providerInfo.slashReserveFund, "reserve not enough");
        require(block.timestamp - LnBridgeHelper.SLASH_EXPIRE_TIME >= providerInfo.lastExpireFillTime, "time not expired");
        uint256 updatedAmount = providerInfo.slashReserveFund - _amount;
        tgtProviders[providerKey].slashReserveFund = updatedAmount;
        if (_targetToken == address(0)) {
            LnBridgeHelper.safeTransferNative(msg.sender, _amount);
        } else {
            LnBridgeHelper.safeTransfer(_targetToken, msg.sender, _amount);
        }
        emit SlashReserveUpdated(msg.sender, _sourceToken, _targetToken, updatedAmount);
    }

    function withdraw(
        uint256 _remoteChainId,
        bytes32 _lastTransferId,
        uint64  _withdrawNonce,
        address _provider,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) external allowRemoteCall(_remoteChainId) {
        // ensure all transfer has finished
        require(_lastTransferId == bytes32(0) || fillTransfers[_lastTransferId].timestamp > 0, "last transfer not filled");

        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, _provider, _sourceToken, _targetToken);
        TargetProviderInfo memory providerInfo = tgtProviders[providerKey];
        // all the early withdraw info ignored
        require(providerInfo.withdrawNonce < _withdrawNonce, "withdraw nonce expired");

        // transfer token
        require(providerInfo.margin >= _amount, "margin not enough");
        uint256 updatedMargin = providerInfo.margin - _amount;
        tgtProviders[providerKey].margin = updatedMargin;
        tgtProviders[providerKey].withdrawNonce = _withdrawNonce;

        if (_targetToken == address(0)) {
            LnBridgeHelper.safeTransferNative(_provider, _amount);
        } else {
            LnBridgeHelper.safeTransfer(_targetToken, _provider, _amount);
        }
        emit MarginUpdated(_remoteChainId, _provider, _sourceToken, _targetToken, updatedMargin, _withdrawNonce);
    }

    function slash(
        LnBridgeHelper.TransferParameter memory _params,
        uint256 _remoteChainId,
        address _slasher,
        uint112 _fee,
        uint112 _penalty
    ) external allowRemoteCall(_remoteChainId) {
        require(_params.previousTransferId == bytes32(0) || fillTransfers[_params.previousTransferId].timestamp > 0, "last transfer not filled");

        bytes32 transferId = keccak256(abi.encodePacked(
            _remoteChainId,
            block.chainid,
            _params.previousTransferId,
            _params.provider,
            _params.sourceToken,
            _params.targetToken,
            _params.receiver,
            _params.amount
        ));
        FillTransfer memory fillTransfer = fillTransfers[transferId];
        require(fillTransfer.slasher == address(0), "transfer has been slashed");
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, _params.provider, _params.sourceToken, _params.targetToken);
        TargetProviderInfo memory providerInfo = tgtProviders[providerKey];
        uint256 updatedMargin = providerInfo.margin;
        // transfer is not filled
        if (fillTransfer.timestamp == 0) {
            require(_params.timestamp < block.timestamp - LnBridgeHelper.SLASH_EXPIRE_TIME, "time not expired");
            fillTransfers[transferId] = FillTransfer(uint64(block.timestamp), _slasher);

            // 1. transfer token to receiver
            // 2. trnasfer fee and penalty to slasher
            // update margin
            uint256 marginCost = _params.amount + _fee + _penalty;
            require(providerInfo.margin >= marginCost, "margin not enough");
            updatedMargin = providerInfo.margin - marginCost;
            tgtProviders[providerKey].margin = updatedMargin;

            if (_params.targetToken == address(0)) {
                LnBridgeHelper.safeTransferNative(_params.receiver, _params.amount);
                LnBridgeHelper.safeTransferNative(_slasher, _fee + _penalty);
            } else {
                LnBridgeHelper.safeTransfer(_params.targetToken, _params.receiver, uint256(_params.amount));
                LnBridgeHelper.safeTransfer(_params.targetToken, _slasher, _fee + _penalty);
            }
        } else {
            require(fillTransfer.timestamp > _params.timestamp + LnBridgeHelper.SLASH_EXPIRE_TIME, "time not expired");
            fillTransfers[transferId].slasher = _slasher;
            uint112 slashRefund = _penalty / 5;
            // transfer slashRefund to slasher
            require(providerInfo.slashReserveFund >= slashRefund, "slashReserveFund not enough");
            tgtProviders[providerKey].slashReserveFund = providerInfo.slashReserveFund - slashRefund;
            if (_params.targetToken == address(0)) {
                LnBridgeHelper.safeTransferNative(_slasher, slashRefund);
            } else {
                LnBridgeHelper.safeTransfer(_params.targetToken, _slasher, slashRefund);
            }
        }
        emit Slash(transferId, _remoteChainId, _params.provider, _params.sourceToken, _params.targetToken, updatedMargin, _slasher);
    }
}

