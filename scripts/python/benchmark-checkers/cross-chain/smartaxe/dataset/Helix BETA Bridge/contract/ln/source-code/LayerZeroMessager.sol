// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interface/ILayerZeroEndpoint.sol";
import "../interface/ILowLevelMessager.sol";
import "../base/LnAccessController.sol";

contract LayerZeroMessager is LnAccessController {
    ILayerZeroEndpoint public endpoint;

    struct RemoteMessager {
        uint16 lzRemoteChainId;
        address messager;
    }

    // app remoteChainId => layerzero remote messager
    mapping(uint256=>RemoteMessager) public remoteMessagers;
    // lz remoteChainId => trustedRemotes
    mapping(uint16=>bytes32) public trustedRemotes;

    // token bridge pair
    // hash(lzRemoteChainId, localAppAddress) => remoteAppAddress
    mapping(bytes32=>address) public remoteAppReceivers;
    mapping(bytes32=>address) public remoteAppSenders;

    event CallResult(uint16 lzRemoteChainId, bytes srcAddress, bool successed);
    event CallerUnMatched(uint16 lzRemoteChainId, bytes srcAddress, address remoteAppAddress);

    constructor(address _dao, address _endpoint) {
        _initialize(_dao);
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    modifier onlyRemoteBridge(uint16 lzRemoteChainId, bytes calldata srcAddress) {
        require(msg.sender == address(endpoint), "invalid caller");
        require(trustedRemotes[lzRemoteChainId] == keccak256(srcAddress), "invalid remote caller");
        _;
    }

    function setRemoteMessager(uint256 _appRemoteChainId, uint16 _lzRemoteChainId, address _remoteMessager) onlyDao external {
        remoteMessagers[_appRemoteChainId] = RemoteMessager(_lzRemoteChainId, _remoteMessager);
        trustedRemotes[_lzRemoteChainId] = keccak256(abi.encodePacked(_remoteMessager, address(this)));
    }

    function registerRemoteReceiver(uint256 _remoteChainId, address _remoteBridge) onlyWhiteListCaller external {
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "remote not configured");
        bytes32 key = keccak256(abi.encodePacked(remoteMessager.lzRemoteChainId, msg.sender));
        remoteAppReceivers[key] = _remoteBridge;
    }

    function registerRemoteSender(uint256 _remoteChainId, address _remoteBridge) onlyWhiteListCaller external {
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "remote not configured");
        bytes32 key = keccak256(abi.encodePacked(remoteMessager.lzRemoteChainId, msg.sender));
        remoteAppSenders[key] = _remoteBridge;
    }

    function sendMessage(uint256 _remoteChainId, bytes memory _message, bytes memory _params) onlyWhiteListCaller external  payable {
        address refunder = address(bytes20(_params));
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "remote not configured");
        bytes memory destination = abi.encodePacked(
            remoteMessager.messager,
            address(this)
        );
        bytes32 key = keccak256(abi.encodePacked(remoteMessager.lzRemoteChainId, msg.sender));
        address remoteAppAddress = remoteAppReceivers[key];
        require(remoteAppAddress != address(0), "app pair not registered");
        bytes memory lzPayload = abi.encode(msg.sender, remoteAppAddress, _message);
        endpoint.send{ value: msg.value }(
            remoteMessager.lzRemoteChainId,
            destination,
            lzPayload,
            payable(refunder),
            // zro payment, future parameter
            address(0x0),
            bytes("")
        );
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64, //nonce unused
        bytes calldata _payload) onlyRemoteBridge(_srcChainId, _srcAddress) external {
        // call
        (address remoteAppAddress, address localAppAddress, bytes memory message) = abi.decode(_payload, (address, address, bytes));
        bytes32 key = keccak256(abi.encodePacked(_srcChainId, localAppAddress));
        if (remoteAppAddress != remoteAppSenders[key]) {
            emit CallerUnMatched(_srcChainId, _srcAddress, remoteAppAddress);
            return;
        }
        (bool success,) = localAppAddress.call(message);
        // don't revert to prevent message block
        emit CallResult(_srcChainId, _srcAddress, success);
    }

    function fee(
        uint256 _remoteChainId,
        bytes memory _message
    ) external view returns(uint256 nativeFee, uint256 zroFee) {
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "messager not configured");
        return endpoint.estimateFees(
            remoteMessager.lzRemoteChainId,
            remoteMessager.messager,
            _message,
            false,
            bytes("")
        );
    }
}

