// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../base/LnBridgeHelper.sol";
import "../interface/ILnDefaultBridgeTarget.sol";
import "../interface/ILnOppositeBridgeSource.sol";

contract DebugMessager {
    address public owner;
    address public app;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "invalid owner");
        _;
    }

    function slashDefault(
        LnBridgeHelper.TransferParameter memory _params,
        uint256 _remoteChainId,
        address _slasher,
        uint112 _fee,
        uint112 _penalty
    ) external onlyOwner {
        ILnDefaultBridgeTarget(app).slash(_params, _remoteChainId, _slasher, _fee, _penalty);
    }

    function slashOpposite(
        bytes32 _latestSlashTransferId,
        bytes32 _transferId,
        uint256 _remoteChainId,
        uint256 _timestamp,
        address _sourceToken,
        address _targetToken,
        address _provider,
        address _slasher
    ) external onlyOwner {
        ILnOppositeBridgeSource(app).slash(
            _latestSlashTransferId,
            _transferId,
            _remoteChainId,
            _timestamp,
            _sourceToken,
            _targetToken,
            _provider,
            _slasher
        );
    }

    function withdrawDefault(
        uint256 _remoteChainId,
        bytes32 _lastTransferId,
        uint64  _withdrawNonce,
        address _provider,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) external onlyOwner {
        ILnDefaultBridgeTarget(app).withdraw(
            _remoteChainId,
            _lastTransferId,
            _withdrawNonce,
            _provider,
            _sourceToken,
            _targetToken,
            _amount
        );
    }

    function withdrawOpposite(
        bytes32 _latestSlashTransferId,
        bytes32 _lastTransferId,
        uint256 _remoteChainId,
        address _provider,
        address _sourceToken,
        address _targetToken,
        uint112 _amount
    ) external onlyOwner {
        ILnOppositeBridgeSource(app).withdrawMargin(
            _latestSlashTransferId,
            _lastTransferId,
            _remoteChainId,
            _provider,
            _sourceToken,
            _targetToken,
            _amount
        );
    }

    function registerRemoteReceiver(uint256 _remoteChainId, address _remoteBridge) external {
    }

    function registerRemoteSender(uint256 _remoteChainId, address _remoteBridge) external {
        app = msg.sender;
    }
}

