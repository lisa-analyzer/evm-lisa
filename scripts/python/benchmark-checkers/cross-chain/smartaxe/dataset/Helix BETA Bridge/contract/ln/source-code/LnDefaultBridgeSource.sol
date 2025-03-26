// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@zeppelin-solidity/contracts/security/Pausable.sol";
import "./LnBridgeHelper.sol";
import "../interface/ILnDefaultBridgeTarget.sol";

/// @title LnDefaultBridgeSource
/// @notice LnDefaultBridgeSource is a contract to help user transfer token to liquidity node and generate proof,
///         then the liquidity node must transfer the same amount of the token to the user on target chain.
///         Otherwise if timeout the slasher can send a slash request message to target chain, then force transfer from lnProvider's margin to the user.
/// @dev See https://github.com/helix-bridge/contracts/tree/master/helix-contract
contract LnDefaultBridgeSource is Pausable {
    // provider fee is paid to liquidity node's account
    // the fee is charged by the same token that user transfered
    // providerFee = baseFee + liquidityFeeRate/LIQUIDITY_FEE_RATE_BASE * sendAmount
    struct SourceProviderConfigure {
        uint112 baseFee;
        uint16 liquidityFeeRate;
        uint64 withdrawNonce;
        bool pause;
    }
    
    struct SourceProviderInfo {
        SourceProviderConfigure config;
        // we use this nonce to generate the unique withdraw id
        bytes32 lastTransferId;
    }
    // the Snapshot is the state of the token bridge when user prepare to transfer across chains.
    // If the snapshot updated when the across chain transfer confirmed, it will
    // 1. if lastTransferId or withdrawNonce updated, revert
    // 2. if totalFee increase, revert
    // 3. if totalFee decrease, success
    struct Snapshot {
        uint256 remoteChainId;
        address provider;
        address sourceToken;
        address targetToken;
        bytes32 transferId;
        uint112 totalFee;
        uint64 withdrawNonce;
    }

    // lock info
    // the fee and penalty is the state of the transfer confirmed
    struct LockInfo {
        uint112 fee;
        uint112 penalty;
        // the timestamp when token locked, if zero, the lockinfo not exist
        uint32 timestamp;
    }

    // hash(remoteChainId, sourceToken, targetToken) => token info
    mapping(bytes32=>LnBridgeHelper.TokenInfo) public tokenInfos;
    // hash(remoteChainId, provider, sourceToken, targetToken) => provider info
    mapping(bytes32=>SourceProviderInfo) public srcProviders;
    // transferId => lock info
    mapping(bytes32=>LockInfo) public lockInfos;

    address public protocolFeeReceiver;

    event TokenLocked(
        uint256 remoteChainId,
        bytes32 transferId,
        address provider,
        address sourceToken,
        address targetToken,
        uint112 amount,
        uint112 fee,
        uint32  timestamp,
        address receiver);
    event LnProviderUpdated(uint256 remoteChainId, address provider, address sourceToken, address targetToken, uint112 baseFee, uint8 liquidityfeeRate);

    event WithdrawMarginRequest(uint256 remoteChainId, address sourceToken, address targetToken, uint112 amount);
    event SlashRequest(uint256 remoteChainId, address sourceToken, address targetToken, bytes32 expectedTransferId);

    // protocolFeeReceiver is the protocol fee reciever, we don't use the contract itself as the receiver
    /// @notice should be called by special privileges
    function _updateFeeReceiver(address _feeReceiver) internal {
        require(_feeReceiver != address(this), "invalid system fee receiver");
        protocolFeeReceiver = _feeReceiver;
    }

    // register or update token info, it can be only called by contract owner
    // source token can only map a unique target token on target chain
    /// @notice should be called by special privileges
    function _setTokenInfo(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _protocolFee,
        uint112 _penaltyLnCollateral,
        uint8 _sourceDecimals,
        uint8 _targetDecimals
    ) internal {
        bytes32 key = keccak256(abi.encodePacked(_remoteChainId, _sourceToken, _targetToken));
        tokenInfos[key] = LnBridgeHelper.TokenInfo(
            _protocolFee,
            _penaltyLnCollateral,
            _sourceDecimals,
            _targetDecimals,
            true
        );
    }

    function providerPause(uint256 _remoteChainId, address _sourceToken, address _targetToken) external {
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        srcProviders[providerKey].config.pause = true;
    }

    function providerUnpause(uint256 _remoteChainId, address _sourceToken, address _targetToken) external {
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        srcProviders[providerKey].config.pause = false;
    }

    // lnProvider register
    // 1. set fee on source chain
    // 2. deposit margin on target chain
    function setProviderFee(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _baseFee,
        uint8 _liquidityFeeRate
    ) external {
        bytes32 key = keccak256(abi.encodePacked(_remoteChainId, _sourceToken, _targetToken));
        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[key];
        require(tokenInfo.isRegistered, "token not registered");
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);

        require(_liquidityFeeRate < LnBridgeHelper.LIQUIDITY_FEE_RATE_BASE, "liquidity fee too large");
        SourceProviderConfigure memory providerConfigure = srcProviders[providerKey].config;
        providerConfigure.baseFee = _baseFee;
        providerConfigure.liquidityFeeRate = _liquidityFeeRate;

        // we only update the field fee of the provider info
        // if the provider has not been registered, then this line will register, otherwise update fee
        srcProviders[providerKey].config = providerConfigure;

        emit LnProviderUpdated(_remoteChainId, msg.sender, _sourceToken, _targetToken, _baseFee, _liquidityFeeRate);
    }

    // the fee user should paid when transfer.
    // totalFee = providerFee + protocolFee
    function totalFee(
        uint256 _remoteChainId,
        address _provider,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) external view returns(uint256) {
        bytes32 key = keccak256(abi.encodePacked(_remoteChainId, _sourceToken, _targetToken));
        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[key];
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, _provider, _sourceToken, _targetToken);
        SourceProviderInfo memory providerInfo = srcProviders[providerKey];
        uint112 providerFee = LnBridgeHelper.calculateProviderFee(providerInfo.config.baseFee, providerInfo.config.liquidityFeeRate, _amount);
        return providerFee + tokenInfo.protocolFee;
    }

    // This function transfers tokens from the user to LnProvider and generates a proof on the source chain.
    // The snapshot represents the state of the LN bridge for this LnProvider, obtained by the off-chain indexer.
    // If the chain state is updated and does not match the snapshot state, the transaction will be reverted.
    // 1. the state(lastTransferId, fee, withdrawNonce) must match snapshot
    // 2. transferId not exist
    function transferAndLockMargin(
        Snapshot calldata _snapshot,
        uint112 _amount,
        address _receiver
    ) whenNotPaused external payable {
        require(_amount > 0, "invalid amount");
        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[
            LnBridgeHelper.getTokenKey(_snapshot.remoteChainId, _snapshot.sourceToken, _snapshot.targetToken)
        ];
        require(tokenInfo.isRegistered, "token not registered");
        
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_snapshot.remoteChainId, _snapshot.provider, _snapshot.sourceToken, _snapshot.targetToken);

        SourceProviderInfo memory providerInfo = srcProviders[providerKey];
        require(!providerInfo.config.pause, "provider paused");
        uint112 providerFee = LnBridgeHelper.calculateProviderFee(providerInfo.config.baseFee, providerInfo.config.liquidityFeeRate, _amount);

        // the chain state not match snapshot
        require(providerInfo.lastTransferId == _snapshot.transferId, "snapshot expired:transfer");
        require(_snapshot.withdrawNonce == providerInfo.config.withdrawNonce, "snapshot expired:withdraw");
        require(_snapshot.totalFee >= providerFee + tokenInfo.protocolFee && providerFee > 0, "fee is invalid");
        
        uint112 targetAmount = LnBridgeHelper.sourceAmountToTargetAmount(tokenInfo, _amount);
        require(targetAmount > 0, "invalid target amount");
        require(block.timestamp < type(uint32).max, "timestamp overflow");
        bytes32 transferId = keccak256(abi.encodePacked(
            block.chainid,
            _snapshot.remoteChainId,
            _snapshot.transferId,
            _snapshot.provider,
            _snapshot.sourceToken,
            _snapshot.targetToken,
            _receiver,
            targetAmount
        ));
        require(lockInfos[transferId].timestamp == 0, "transferId exist");
        // if the transfer refund, then the fee and penalty should be given to slasher, but the protocol fee is ignored
        // and we use the penalty value configure at the moment transfer confirmed
        lockInfos[transferId] = LockInfo(providerFee, tokenInfo.penaltyLnCollateral, uint32(block.timestamp));

        // update the state to prevent other transfers using the same snapshot
        srcProviders[providerKey].lastTransferId = transferId;

        if (_snapshot.sourceToken == address(0)) {
            require(_amount + _snapshot.totalFee == msg.value, "amount unmatched");
            LnBridgeHelper.safeTransferNative(_snapshot.provider, _amount + providerFee);
            if (tokenInfo.protocolFee > 0) {
                LnBridgeHelper.safeTransferNative(protocolFeeReceiver, tokenInfo.protocolFee);
            }
            uint256 refund = _snapshot.totalFee - tokenInfo.protocolFee - providerFee;
            if ( refund > 0 ) {
                LnBridgeHelper.safeTransferNative(msg.sender, refund);
            }
        } else {
            LnBridgeHelper.safeTransferFrom(
                _snapshot.sourceToken,
                msg.sender,
                _snapshot.provider,
                _amount + providerFee
            );
            if (tokenInfo.protocolFee > 0) {
                LnBridgeHelper.safeTransferFrom(
                    _snapshot.sourceToken,
                    msg.sender,
                    protocolFeeReceiver,
                    tokenInfo.protocolFee 
                );
            }
        }
        emit TokenLocked(
            _snapshot.remoteChainId,
            transferId,
            _snapshot.provider,
            _snapshot.sourceToken,
            _snapshot.targetToken,
            targetAmount,
            providerFee,
            uint32(block.timestamp),
            _receiver);
    }

    function _slashAndRemoteReleaseCall(
        LnBridgeHelper.TransferParameter memory _params,
        uint256 _remoteChainId,
        bytes32 _expectedTransferId
    ) internal view returns(bytes memory message) {
        bytes32 key = keccak256(abi.encodePacked(_remoteChainId, _params.sourceToken, _params.targetToken));
        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[key];
        require(tokenInfo.isRegistered, "token not registered");
        uint112 targetAmount = LnBridgeHelper.sourceAmountToTargetAmount(tokenInfo, _params.amount);

        bytes32 transferId = keccak256(abi.encodePacked(
           block.chainid,
           _remoteChainId,
           _params.previousTransferId,
           _params.provider,
           _params.sourceToken,
           _params.targetToken,
           _params.receiver,
           targetAmount
        ));
        require(_expectedTransferId == transferId, "expected transfer id not match");
        LockInfo memory lockInfo = lockInfos[transferId];
        require(lockInfo.timestamp == _params.timestamp, "invalid timestamp");
        require(block.timestamp > lockInfo.timestamp + LnBridgeHelper.SLASH_EXPIRE_TIME, "invalid timestamp");
        uint112 targetFee = LnBridgeHelper.sourceAmountToTargetAmount(tokenInfo, lockInfo.fee);
        uint112 targetPenalty = LnBridgeHelper.sourceAmountToTargetAmount(tokenInfo, lockInfo.penalty);

        message = abi.encodeWithSelector(
           ILnDefaultBridgeTarget.slash.selector,
           _params,
           block.chainid,
           msg.sender, // slasher
           targetFee,
           targetPenalty
        );
    }

    function _withdrawMarginCall(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) internal returns(bytes memory message) {
        bytes32 key = keccak256(abi.encodePacked(_remoteChainId, _sourceToken, _targetToken));
        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[key];
        require(tokenInfo.isRegistered, "token not registered");

        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        SourceProviderInfo memory providerInfo = srcProviders[providerKey];
        srcProviders[providerKey].config.withdrawNonce = providerInfo.config.withdrawNonce + 1;
        uint112 targetAmount = LnBridgeHelper.sourceAmountToTargetAmount(tokenInfo, _amount);
        message = abi.encodeWithSelector(
            ILnDefaultBridgeTarget.withdraw.selector,
            block.chainid,
            providerInfo.lastTransferId,
            providerInfo.config.withdrawNonce + 1,
            msg.sender, //provider,
            _sourceToken,
            _targetToken,
            targetAmount
        );
    }

    function encodeSlashCall(
        LnBridgeHelper.TransferParameter memory _params,
        uint256 _localChainId,
        address _slasher,
        uint112 _fee,
        uint112 _penalty
    ) public pure returns(bytes memory message) {
        return abi.encodeWithSelector(
           ILnDefaultBridgeTarget.slash.selector,
           _params,
           _localChainId,
           _slasher,
           _fee,
           _penalty
        );
    }

    function encodeWithdrawCall(
        bytes32 _lastTransferId,
        uint256 _localChainId,
        uint64  _withdrawNonce,
        address _provider,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) public pure returns(bytes memory message) {
        return abi.encodeWithSelector(
            ILnDefaultBridgeTarget.withdraw.selector,
            _localChainId,
            _lastTransferId,
            _withdrawNonce,
            _provider,
            _sourceToken,
            _targetToken,
            _amount
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

    function requestWithdrawMargin(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _amount,
        bytes memory _extParams
    ) payable external {
        bytes memory withdrawCallMessage = _withdrawMarginCall(
            _remoteChainId,
            _sourceToken,
            _targetToken,
            _amount
        );
        _sendMessageToTarget(_remoteChainId, withdrawCallMessage, _extParams);
        emit WithdrawMarginRequest(_remoteChainId, _sourceToken, _targetToken, _amount);
    }
}
 
