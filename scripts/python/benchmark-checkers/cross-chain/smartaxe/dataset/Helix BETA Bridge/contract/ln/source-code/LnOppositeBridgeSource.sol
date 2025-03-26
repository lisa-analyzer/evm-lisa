// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@zeppelin-solidity/contracts/security/Pausable.sol";
import "./LnBridgeHelper.sol";

/// @title LnBridgeSource
/// @notice LnBridgeSource is a contract to help user transfer token to liquidity node and generate proof,
///         then the liquidity node must transfer the same amount of the token to the user on target chain.
///         Otherwise if timeout the slasher can paid for relayer and slash the transfer, then request slash from lnProvider's margin.
/// @dev See https://github.com/helix-bridge/contracts/tree/master/helix-contract
contract LnOppositeBridgeSource is Pausable {
    // the Liquidity Node provider info
    // Liquidity Node need register first
    struct SourceProviderConfigure {
        uint112 margin;
        uint112 baseFee;
        // liquidityFeeRate / 100,000 * amount = liquidityFee
        // the max liquidity fee rate is 0.255%
        uint16 liquidityFeeRate;
        bool pause;
    }
    struct SourceProviderInfo {
        SourceProviderConfigure config;
        bytes32 lastTransferId;
    }
    
    // the Snapshot is the state of the token bridge when user prepare to transfer across chains.
    // If the snapshot updated when the across chain transfer confirmed, it will
    // 1. if lastTransferId updated, revert
    // 2. if margin decrease or totalFee increase, revert
    // 3. if margin increase or totalFee decrease, success
    struct Snapshot {
        uint256 remoteChainId;
        address provider;
        address sourceToken;
        address targetToken;
        bytes32 transferId;
        uint112 totalFee;
        uint112 depositedMargin;
    }
    // registered token info
    // tokenKey => token info
    mapping(bytes32=>LnBridgeHelper.TokenInfo) public tokenInfos;
    // registered srcProviders
    mapping(bytes32=>SourceProviderInfo) public srcProviders;
    // each time cross chain transfer, amount and fee can't be larger than type(uint112).max
    struct LockInfo {
        // amount + providerFee + penaltyLnCollateral
        // the Indexer should be care about this value, it will frozen lnProvider's margin when the transfer not finished.
        // and when the slasher slash success, this amount of token will be transfer from lnProvider's margin to slasher.
        uint112 amount;
        uint112 feeAndPenalty;
        uint32 timestamp;
        bool hasSlashed;
    }
    // key: transferId = hash(proviousTransferId, targetToken, receiver, targetAmount)
    // * `proviousTransferId` is used to ensure the continuous of the transfer
    // * `timestamp` is the block.timestmap to judge timeout on target chain(here we support source and target chain has the same world clock)
    // * `targetToken`, `receiver` and `targetAmount` are used on target chain to transfer target token.
    mapping(bytes32 => LockInfo) public lockInfos;

    address public protocolFeeReceiver;

    event TokenLocked(
        uint256 remoteChainId,
        bytes32 transferId,
        address provider,
        address sourceToken,
        address targetToken,
        uint112 amount,
        uint112 fee,
        uint32 timestamp,
        address receiver);
    event LiquidityWithdrawn(uint256 remoteChainId, address provider, address sourceToken, address targetToken, uint112 amount);
    event Slash(uint256 remoteChainId, bytes32 transferId, address provider, address sourceToken, address targetToken, uint112 margin, address slasher);
    // relayer
    event LnProviderUpdated(uint256 remoteChainId, address provider, address sourceToken, address targetToken, uint112 margin, uint112 baseFee, uint16 liquidityfeeRate);

    modifier allowRemoteCall(uint256 _remoteChainId) {
        _verifyRemote(_remoteChainId);
        _;
    }

    function _verifyRemote(uint256 _remoteChainId) internal virtual {}

    function _updateFeeReceiver(address _feeReceiver) internal {
        require(_feeReceiver != address(this), "invalid system fee receiver");
        protocolFeeReceiver = _feeReceiver;
    }

    function _setTokenInfo(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _protocolFee,
        uint112 _penaltyLnCollateral,
        uint8 _sourceDecimals,
        uint8 _targetDecimals
    ) internal {
        bytes32 tokenKey = LnBridgeHelper.getTokenKey(_remoteChainId, _sourceToken, _targetToken);
        tokenInfos[tokenKey] = LnBridgeHelper.TokenInfo(
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

    // lnProvider can register or update its configure by using this function
    // * `margin` is the increased value of the deposited margin
    function updateProviderFeeAndMargin(
        uint256 _remoteChainId,
        address _sourceToken,
        address _targetToken,
        uint112 _margin,
        uint112 _baseFee,
        uint16 _liquidityFeeRate
    ) external payable {
        require(_liquidityFeeRate < LnBridgeHelper.LIQUIDITY_FEE_RATE_BASE, "liquidity fee too large");
        bytes32 tokenKey = LnBridgeHelper.getTokenKey(_remoteChainId, _sourceToken, _targetToken);
        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[tokenKey];
        require(tokenInfo.isRegistered, "token is not registered");

        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, msg.sender, _sourceToken, _targetToken);
        SourceProviderInfo memory providerInfo = srcProviders[providerKey];

        SourceProviderConfigure memory config = SourceProviderConfigure(
            // the margin can be only increased here
            _margin + providerInfo.config.margin,
            _baseFee,
            _liquidityFeeRate,
            providerInfo.config.pause
        );

        srcProviders[providerKey].config = config;

        if (_sourceToken == address(0)) {
            require(msg.value == _margin, "invalid margin value");
        } else {
            if (_margin > 0) {
                LnBridgeHelper.safeTransferFrom(_sourceToken, msg.sender, address(this), _margin);
            }
        }
        emit LnProviderUpdated(_remoteChainId, msg.sender, _sourceToken, _targetToken, config.margin, _baseFee, _liquidityFeeRate);
    }

    // the fee user should paid when transfer.
    // totalFee = providerFee + protocolFee
    // providerFee = provider.baseFee + provider.liquidityFeeRate * amount
    function totalFee(
        uint256 _remoteChainId,
        address _provider,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) external view returns(uint256) {
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, _provider, _sourceToken, _targetToken);
        SourceProviderInfo memory providerInfo = srcProviders[providerKey];
        uint112 providerFee = LnBridgeHelper.calculateProviderFee(providerInfo.config.baseFee, providerInfo.config.liquidityFeeRate, _amount);
        bytes32 tokenKey = LnBridgeHelper.getTokenKey(_remoteChainId, _sourceToken, _targetToken);
        return providerFee + tokenInfos[tokenKey].protocolFee;
    }

    // This function transfers tokens from the user to LnProvider and generates a proof on the source chain.
    // The snapshot represents the state of the LN bridge for this LnProvider, obtained by the off-chain indexer.
    // If the chain state is updated and does not match the snapshot state, the transaction will be reverted.
    // 1. the state(lastTransferId, fee, margin) must match snapshot
    // 2. transferId not exist
    function transferAndLockMargin(
        Snapshot calldata _snapshot,
        uint112 _amount,
        address _receiver
    ) whenNotPaused external payable {
        require(_amount > 0, "invalid amount");

        bytes32 providerKey = LnBridgeHelper.getProviderKey(_snapshot.remoteChainId, _snapshot.provider, _snapshot.sourceToken, _snapshot.targetToken);
        SourceProviderInfo memory providerInfo = srcProviders[providerKey];

        require(!providerInfo.config.pause, "provider paused");

        LnBridgeHelper.TokenInfo memory tokenInfo = tokenInfos[
            LnBridgeHelper.getTokenKey(_snapshot.remoteChainId, _snapshot.sourceToken, _snapshot.targetToken)
        ];

        uint112 providerFee = LnBridgeHelper.calculateProviderFee(providerInfo.config.baseFee, providerInfo.config.liquidityFeeRate, _amount);
        
        // the chain state not match snapshot
        require(providerInfo.lastTransferId == _snapshot.transferId, "snapshot expired");
        // Note: this requirement is not enough to ensure that the lnProvider's margin is enough because there maybe some frozen margins in other transfers
        require(providerInfo.config.margin >= _amount + tokenInfo.penaltyLnCollateral + providerFee, "amount not valid");
        require(_snapshot.depositedMargin <= providerInfo.config.margin, "margin updated");
        require(_snapshot.totalFee >= tokenInfo.protocolFee + providerFee, "fee is invalid");
        
        uint112 targetAmount = LnBridgeHelper.sourceAmountToTargetAmount(tokenInfo, _amount);
        require(targetAmount > 0, "invalid amount");
        require(block.timestamp < type(uint32).max, "timestamp overflow");
        bytes32 transferId = keccak256(abi.encodePacked(
            block.chainid,
            _snapshot.remoteChainId,
            _snapshot.transferId,
            _snapshot.provider,
            _snapshot.sourceToken,
            _snapshot.targetToken,
            _receiver,
            targetAmount));
        require(lockInfos[transferId].timestamp == 0, "transferId exist");
        lockInfos[transferId] = LockInfo(_amount, tokenInfo.penaltyLnCollateral + providerFee, uint32(block.timestamp), false);

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

    // this slash is called by remote message
    // the token should be sent to the slasher who slash and finish the transfer on target chain.
    // latestSlashTransferId is the latest slashed transfer trusted from the target chain, and the current slash transfer cannot be executed before the latestSlash transfer.
    // after slash, the margin of lnProvider need to be updated
    function slash(
        bytes32 _latestSlashTransferId,
        bytes32 _transferId,
        uint256 _remoteChainId,
        uint256 _timestamp,
        address _sourceToken,
        address _targetToken,
        address _provider,
        address _slasher
    ) external allowRemoteCall(_remoteChainId) {
        // check lastTransfer
        // ensure last slash transfer(checked on target chain) has been slashed
        LockInfo memory lastLockInfo = lockInfos[_latestSlashTransferId];
        require(lastLockInfo.hasSlashed || _latestSlashTransferId == LnBridgeHelper.INIT_SLASH_TRANSFER_ID, "latest slash transfer invalid");
        LockInfo memory lockInfo = lockInfos[_transferId];

        // ensure transfer exist and not slashed yet
        require(!lockInfo.hasSlashed, "transfer has been slashed");
        require(lockInfo.timestamp > 0, "lnBridgeSource:invalid timestamp");

        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, _provider, _sourceToken, _targetToken);

        SourceProviderInfo memory lnProvider = srcProviders[providerKey];
        lockInfos[_transferId].hasSlashed = true;
        // transfer token to the slasher
        uint112 slashAmount = (lockInfo.timestamp == _timestamp ? lockInfo.amount + lockInfo.feeAndPenalty : lockInfo.amount);
        require(lnProvider.config.margin >= slashAmount, "margin not enough");
        uint112 updatedMargin = lnProvider.config.margin - slashAmount;
        srcProviders[providerKey].config.margin = updatedMargin;

        if (_sourceToken == address(0)) {
            LnBridgeHelper.safeTransferNative(_slasher, slashAmount);
        } else {
            LnBridgeHelper.safeTransfer(_sourceToken, _slasher, slashAmount);
        }

        emit Slash(_remoteChainId, _transferId, _provider, _sourceToken, _targetToken, updatedMargin, _slasher);
    }

    // lastTransfer is the latest slash transfer, all transfer must be relayed or slashed
    // if user use the snapshot before this transaction to send cross-chain transfer, it should be reverted because this `withdrawMargin` will decrease margin.
    function withdrawMargin(
        bytes32 _latestSlashTransferId,
        bytes32 _lastTransferId,
        uint256 _remoteChainId,
        address _provider,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) external allowRemoteCall(_remoteChainId) {
        // check the latest slash transfer 
        // ensure latest slash tranfer(verified on target chain) has been slashed on source chain
        LockInfo memory lastRefundLockInfo = lockInfos[_latestSlashTransferId];
        require(lastRefundLockInfo.hasSlashed || _latestSlashTransferId == LnBridgeHelper.INIT_SLASH_TRANSFER_ID, "latest slash transfer invalid");

        // use this condition to ensure that the withdraw message is sent by the provider
        // the parameter provider is the message sender of this remote withdraw call
        bytes32 providerKey = LnBridgeHelper.getProviderKey(_remoteChainId, _provider, _sourceToken, _targetToken);
        SourceProviderInfo memory lnProvider = srcProviders[providerKey];

        // ensure all transfer has finished
        require(lnProvider.lastTransferId == _lastTransferId, "invalid last transferid");
        require(lnProvider.config.margin >= _amount, "margin not enough");
        uint112 updatedMargin = lnProvider.config.margin - _amount;
        srcProviders[providerKey].config.margin = updatedMargin;
        if (_sourceToken == address(0)) {
            LnBridgeHelper.safeTransferNative(_provider, _amount);
        } else {
            LnBridgeHelper.safeTransfer(_sourceToken, _provider, _amount);
        }
        emit LiquidityWithdrawn(_remoteChainId, _provider, _sourceToken, _targetToken, updatedMargin);
    }
}
 
