// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interface/ILnOppositeBridgeSource.sol";
import "./LnBridgeHelper.sol";

contract LnOppositeBridgeTarget {
    // if slasher == address(0), this FillTransfer is relayed by lnProvider
    // otherwise, this FillTransfer is slashed by slasher
    // if there is no slash transfer before, then it's latestSlashTransferId is assigned by INIT_SLASH_TRANSFER_ID, a special flag
    struct SlashInfo {
        address provider;
        address sourceToken;
        address targetToken;
        address slasher;
        uint256 timestamp;
    }

    // transferId => latest slash transfer Id
    mapping(bytes32 => bytes32) public fillTransfers;
    // transferId => Slash info
    mapping(bytes32 => SlashInfo) public slashInfos;

    event TransferFilled(bytes32 transferId, address slasher);
    event SlashRequest(uint256 remoteChainId, address sourceToken, address targetToken, bytes32 transferId);
    event WithdrawMarginRequest(uint256 remoteChainId, address sourceToken, address targetToken, uint112 amount);

    // if slasher is nonzero, then it's a slash fill transfer
    function _checkPreviousAndFillTransfer(
        bytes32 _transferId,
        bytes32 _previousTransferId
    ) internal {
        // the first fill transfer, we fill the INIT_SLASH_TRANSFER_ID as the latest slash transferId
        if (_previousTransferId == bytes32(0)) {
            fillTransfers[_transferId] = LnBridgeHelper.INIT_SLASH_TRANSFER_ID;
        } else {
            // Find the previous slash fill, it is a slash fill if the slasher is not zero address.
            bytes32 previousLatestSlashTransferId = fillTransfers[_previousTransferId];
            require(previousLatestSlashTransferId != bytes32(0), "previous fill not exist");

            SlashInfo memory previousSlashInfo = slashInfos[_previousTransferId];
            // we use latestSlashTransferId to store the latest slash transferId
            // if previous.slasher != 0, then previous is slashed
            // if previous.slasher == 0, then previous is not slashed
            bytes32 latestSlashTransferId = previousSlashInfo.slasher != address(0) ? _previousTransferId : previousLatestSlashTransferId;

            fillTransfers[_transferId] = latestSlashTransferId;
        }
    }

    // fill transfer
    // 1. if transfer is not slashed or relayed, LnProvider relay message to fill the transfer, and the transfer finished on target chain
    // 2. if transfer is timeout and not processed, slasher(any account) can fill the transfer and request slash
    // if it's filled by slasher, we store the address of the slasher
    // expectedTransferId used to ensure the parameter is the same as on source chain
    // some cases
    // 1) If transferId is not exist on source chain, it'll be rejected by source chain when shashed.
    // 2) If transferId exist on source chain. We have the same hash process on source and target chain, so the previousTransferId is trusted.
    //    2.1) If transferId is the first transfer Id of this provider, then previousTransferId is zero and the latestSlashTransferId is INIT_SLASH_TRANSFER_ID
    //    2.2) If transferId is not the first transfer, then it's latestSlashTransferId has the next two scenarios
    //         * the previousTransfer is a slash transfer, then latestSlashTransferId is previousTransferId
    //         * the previousTransfer is a normal relayed transfer, then latestSlashTransferId is previousTransfer's latestSlashTransferId
    //    I.   transferId is trusted => previousTransferId is trusted => previousTransfer.previousTransferId is trusted => ... => firstTransfer is trusted
    //    II.  transferId is trusted => previousTransferId is trusted => latestSlashTransferId is trusted if previousTransfer is a slash transfer
    //    III. Both I and II => latestSlashTransferId is trusted if previousTransfer is normal relayed tranfer
    function _fillTransfer(
        LnBridgeHelper.TransferParameter calldata _params,
        uint256 _remoteChainId,
        bytes32 _expectedTransferId
    ) internal {
        bytes32 transferId = keccak256(abi.encodePacked(
            _remoteChainId,
            block.chainid,
            _params.previousTransferId,
            _params.provider,
            _params.sourceToken,
            _params.targetToken,
            _params.receiver,
            _params.amount));
        require(_expectedTransferId == transferId, "check expected transferId failed");
        // Make sure this transfer was never filled before 
        require(fillTransfers[transferId] == bytes32(0), "fill exist");

        _checkPreviousAndFillTransfer(transferId, _params.previousTransferId);

        if (_params.targetToken == address(0)) {
            require(msg.value >= _params.amount, "invalid amount");
            LnBridgeHelper.safeTransferNative(_params.receiver, _params.amount);
        } else {
            LnBridgeHelper.safeTransferFrom(_params.targetToken, msg.sender, _params.receiver, uint256(_params.amount));
        }
    }

    function transferAndReleaseMargin(
        LnBridgeHelper.TransferParameter calldata _params,
        uint256 _remoteChainId,
        bytes32 _expectedTransferId
    ) payable external {
        // normal relay message, fill slasher as zero
        require(_params.provider == msg.sender, "invalid provider");
        _fillTransfer(_params, _remoteChainId, _expectedTransferId);

        emit TransferFilled(_expectedTransferId, address(0));
    }

    // The condition for slash is that the transfer has timed out
    // Meanwhile we need to request a slash transaction to the source chain to withdraw the LnProvider's margin
    // On the source chain, we need to verify all the transfers before has been relayed or slashed.
    // So we needs to carry the the previous shash transferId to ensure that the slash is continuous.
    function _slashAndRemoteReleaseCall(
        LnBridgeHelper.TransferParameter calldata _params,
        uint256 _remoteChainId,
        bytes32 _expectedTransferId
    ) internal returns(bytes memory message) {
        require(block.timestamp > _params.timestamp + LnBridgeHelper.SLASH_EXPIRE_TIME, "slash time not expired");
        _fillTransfer(_params, _remoteChainId, _expectedTransferId);

        // slasher = msg.sender
        slashInfos[_expectedTransferId] = SlashInfo(_params.provider, _params.sourceToken, _params.targetToken, msg.sender, _params.timestamp);

        // Do not slash `transferId` in source chain unless `latestSlashTransferId` has been slashed
        message = encodeSlashCall(
            fillTransfers[_expectedTransferId],
            _expectedTransferId,
            _params.timestamp,
            _params.sourceToken,
            _params.targetToken,
            _params.provider,
            msg.sender
        );
        emit TransferFilled(_expectedTransferId, msg.sender);
    }

    // we use this to verify that the transfer has been slashed by user and it can resend the slash request
    function _retrySlashAndRemoteReleaseCall(bytes32 _transferId) internal view returns(bytes memory message) {
        bytes32 latestSlashTransferId = fillTransfers[_transferId];
        // transfer must be filled
        require(latestSlashTransferId != bytes32(0), "invalid transfer id");
        // transfer must be slashed
        SlashInfo memory slashInfo = slashInfos[_transferId];
        require(slashInfo.slasher != address(0), "slasher not exist");
        message = encodeSlashCall(
            latestSlashTransferId,
            _transferId,
            slashInfo.timestamp,
            slashInfo.sourceToken,
            slashInfo.targetToken,
            slashInfo.provider,
            slashInfo.slasher
        );
    }

    function encodeSlashCall(
        bytes32 _latestSlashTransferId,
        bytes32 _transferId,
        uint256 _timestamp,
        address _sourceToken,
        address _targetToken,
        address _provider,
        address _slasher
    ) public view returns(bytes memory) {
        return abi.encodeWithSelector(
            ILnOppositeBridgeSource.slash.selector,
            _latestSlashTransferId,
            _transferId,
            block.chainid,
            _timestamp,
            _sourceToken,
            _targetToken,
            _provider,
            _slasher
        );
    }

    function _sendMessageToTarget(uint256 _remoteChainId, bytes memory _payload, bytes memory _extParams) internal virtual {}

    function requestSlashAndRemoteRelease(
        LnBridgeHelper.TransferParameter calldata _params,
        uint256 _remoteChainId,
        bytes32 _expectedTransferId,
        bytes memory _extParams
    ) payable external {
        bytes memory slashCallMessage = _slashAndRemoteReleaseCall(
           _params,
           _remoteChainId,
           _expectedTransferId
        );
        _sendMessageToTarget(_remoteChainId, slashCallMessage, _extParams);
        emit SlashRequest(_remoteChainId, _params.sourceToken, _params.targetToken, _expectedTransferId);
    }

    function requestRetrySlashAndRemoteRelease(
        uint256 remoteChainId,
        bytes32 _transferId,
        bytes memory _extParams
    ) payable external {
        bytes memory retryCallMessage = _retrySlashAndRemoteReleaseCall(_transferId);
        _sendMessageToTarget(remoteChainId, retryCallMessage, _extParams);
    }

    function encodeWithdrawMargin(
        bytes32 _lastTransferId,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) public view returns(bytes memory message) {
        bytes32 latestSlashTransferId = LnBridgeHelper.INIT_SLASH_TRANSFER_ID;
        if (_lastTransferId != bytes32(0)) {
            latestSlashTransferId = fillTransfers[_lastTransferId];
            require(latestSlashTransferId != bytes32(0), "invalid last transfer");
        }

        return abi.encodeWithSelector(
            ILnOppositeBridgeSource.withdrawMargin.selector,
            latestSlashTransferId,
            _lastTransferId,
            block.chainid,
            msg.sender,
            _sourceToken,
            _targetToken,
            _amount
        );
    }

    function requestWithdrawMargin(
        uint256 _remoteChainId,
        bytes32 _lastTransferId,
        address _sourceToken,
        address _targetToken,
        uint112 _amount,
        bytes memory _extParams
    ) payable external {
        bytes memory withdrawCallMessage = encodeWithdrawMargin(
            _lastTransferId,
            _sourceToken,
            _targetToken,
            _amount
        );
        _sendMessageToTarget(_remoteChainId, withdrawCallMessage, _extParams);
        emit WithdrawMarginRequest(_remoteChainId, _sourceToken, _targetToken, _amount);
    }
}

