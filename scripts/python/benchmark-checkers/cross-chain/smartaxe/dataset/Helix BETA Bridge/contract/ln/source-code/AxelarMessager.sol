// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { StringToAddress, AddressToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressString.sol';
import "../interface/ILowLevelMessager.sol";
import "../base/LnAccessController.sol";
import "./interface/IAxelarGateway.sol";
import "./interface/IAxelarGasReceiver.sol";

contract AxelarMessager is LnAccessController {
    using StringToAddress for string;
    using AddressToString for address;

    IAxelarGateway public immutable gateway;
    IAxelarGasReceiver public immutable gasReceiver;

    struct RemoteMessager {
        string axRemoteChainName;
        address messager;
    }

    // app remoteChainId => axelar remote messager
    mapping(uint256=>RemoteMessager) public remoteMessagers;
    // axRemoteChainName => trustedRemotes
    mapping(string=>address) public trustedRemotes;

    // token bridge pair
    // hash(axRemoteChainName, localAppAddress) => remoteAppAddress
    mapping(bytes32=>address) public remoteAppReceivers;
    mapping(bytes32=>address) public remoteAppSenders;

    event CallResult(string sourceChain, string srcAddress, bool successed);

    constructor(address _dao, address _gateway, address _gasReceiver) {
        _initialize(_dao);
        gateway = IAxelarGateway(_gateway);
        gasReceiver = IAxelarGasReceiver(_gasReceiver);
    }

    // receive remote message
    function execute(
        bytes32 _commandId,
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    ) external {
        // check message comes from remote messager
        require(gateway.validateContractCall(_commandId, _sourceChain, _sourceAddress, keccak256(_payload)), "invalid contract call");
        require(_sourceAddress.toAddress() == trustedRemotes[_sourceChain], "invalid remote messager");
        // check message comes from remote app
        (address remoteAppAddress, address localAppAddress, bytes memory message) = abi.decode(_payload, (address, address, bytes));
        bytes32 key = keccak256(abi.encodePacked(_sourceChain, localAppAddress));
        require(remoteAppAddress == remoteAppSenders[key], "invalid remote address");
        // call local app
        (bool success,) = localAppAddress.call(message);
        emit CallResult(_sourceChain, _sourceAddress, success);
    }

    function setRemoteMessager(uint256 _appRemoteChainId, string calldata _remoteChainName, address _remoteMessager) onlyDao external {
        remoteMessagers[_appRemoteChainId] = RemoteMessager(_remoteChainName, _remoteMessager);
        trustedRemotes[_remoteChainName] = _remoteMessager;
    }

    function registerRemoteReceiver(uint256 _remoteChainId, address _remoteBridge) onlyWhiteListCaller external {
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "remote not configured");
        bytes32 key = keccak256(abi.encodePacked(remoteMessager.axRemoteChainName, msg.sender));
        remoteAppReceivers[key] = _remoteBridge;
    }

    function registerRemoteSender(uint256 _remoteChainId, address _remoteBridge) onlyWhiteListCaller external {
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "remote not configured");
        bytes32 key = keccak256(abi.encodePacked(remoteMessager.axRemoteChainName, msg.sender));
        remoteAppSenders[key] = _remoteBridge;
    }

    function sendMessage(uint256 _remoteChainId, bytes memory _message, bytes memory _params) onlyWhiteListCaller external payable {
        address refunder = address(bytes20(_params));
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "remote not configured");
        bytes32 key = keccak256(abi.encodePacked(remoteMessager.axRemoteChainName, msg.sender));
        address remoteAppAddress = remoteAppReceivers[key];
        require(remoteAppAddress != address(0), "app pair not registered");
        bytes memory axPayload = abi.encode(msg.sender, remoteAppAddress, _message);

        string memory stringAddress = remoteMessager.messager.toString();
        gasReceiver.payNativeGasForContractCall{value: msg.value}(
            address(this),
            remoteMessager.axRemoteChainName,
            stringAddress,
            axPayload,
            refunder
        );
        gateway.callContract(
            remoteMessager.axRemoteChainName,
            stringAddress,
            axPayload
        );
    }
}

