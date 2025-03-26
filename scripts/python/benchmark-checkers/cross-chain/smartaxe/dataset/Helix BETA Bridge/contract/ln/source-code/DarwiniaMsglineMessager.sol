// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interface/ILowLevelMessager.sol";
import "../base/LnAccessController.sol";
import "./interface/IDarwiniaMsgline.sol";

contract DarwiniaMsglineMessager is Application, LnAccessController {
    IMessageLine public immutable msgline;

    struct RemoteMessager {
        uint256 msglineRemoteChainId;
        address messager;
    }

    // app remoteChainId => msgline remote messager
    mapping(uint256=>RemoteMessager) public remoteMessagers;

    // token bridge pair
    // hash(msglineRemoteChainId, localAppAddress) => remoteAppAddress
    mapping(bytes32=>address) public remoteAppReceivers;
    mapping(bytes32=>address) public remoteAppSenders;

    event CallerUnMatched(uint256 srcAppChainId, address srcAppAddress);
    event CallResult(uint256 srcAppChainId, bool result);

    modifier onlyMsgline() {
        require(msg.sender == address(msgline), "invalid caller");
        _;
    }

    //event CallResult(string sourceChain, string srcAddress, bool successed);

    constructor(address _dao, address _msgline) {
        _initialize(_dao);
        msgline = IMessageLine(_msgline);
    }

    function setRemoteMessager(uint256 _appRemoteChainId, uint256 _msglineRemoteChainId, address _remoteMessager) onlyDao external {
        remoteMessagers[_appRemoteChainId] = RemoteMessager(_msglineRemoteChainId, _remoteMessager);
    }

    function registerRemoteReceiver(uint256 _remoteChainId, address _remoteBridge) onlyWhiteListCaller external {
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "remote not configured");
        bytes32 key = keccak256(abi.encodePacked(remoteMessager.msglineRemoteChainId, msg.sender));
        remoteAppReceivers[key] = _remoteBridge;
    }

    function registerRemoteSender(uint256 _remoteChainId, address _remoteBridge) onlyWhiteListCaller external {
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "remote not configured");
        bytes32 key = keccak256(abi.encodePacked(remoteMessager.msglineRemoteChainId, msg.sender));
        remoteAppSenders[key] = _remoteBridge;
    }

    function sendMessage(uint256 _remoteChainId, bytes memory _message, bytes memory _params) onlyWhiteListCaller external payable {
        RemoteMessager memory remoteMessager = remoteMessagers[_remoteChainId];
        require(remoteMessager.messager != address(0), "remote not configured");
        bytes32 key = keccak256(abi.encodePacked(remoteMessager.msglineRemoteChainId, msg.sender));
        address remoteAppAddress = remoteAppReceivers[key];
        require(remoteAppAddress != address(0), "app pair not registered");
        bytes memory msglinePayload = messagePayload(msg.sender, remoteAppAddress, _message);
        msgline.send{ value: msg.value }(
            remoteMessager.msglineRemoteChainId,
            remoteMessager.messager,
            msglinePayload,
            _params
        );
    }

    function receiveMessage(uint256 _srcAppChainId, address _remoteAppAddress, address _localAppAddress, bytes memory _message) onlyMsgline external {
        uint256 srcChainId = _fromChainId();
        RemoteMessager memory remoteMessager = remoteMessagers[_srcAppChainId];
        require(srcChainId == remoteMessager.msglineRemoteChainId, "invalid remote chainid");
        require(remoteMessager.messager == _xmsgSender(), "invalid remote messager");
        bytes32 key = keccak256(abi.encodePacked(srcChainId, _localAppAddress));
        // check remote appSender
        if (_remoteAppAddress != remoteAppSenders[key]) {
            emit CallerUnMatched(_srcAppChainId, _remoteAppAddress);
            return;
        }
        (bool success,) = _localAppAddress.call(_message);
        // don't revert to prevent message block
        emit CallResult(_srcAppChainId, success);
    }

    function messagePayload(address _from, address _to, bytes memory _message) public view returns(bytes memory) {
        return abi.encodeWithSelector(
            DarwiniaMsglineMessager.receiveMessage.selector,
            block.chainid,
            _from,
            _to,
            _message
        );
    }
}

