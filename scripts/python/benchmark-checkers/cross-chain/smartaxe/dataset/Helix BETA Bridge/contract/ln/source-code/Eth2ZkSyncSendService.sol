// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interface/IZksyncMailbox.sol";
import "../base/LnAccessController.sol";
import "../interface/ILowLevelMessager.sol";

// from ethereum to zkSync messager
contract Eth2ZkSyncSendService is ILowLevelMessageSender, LnAccessController {
    uint256 immutable public REMOTE_CHAINID;
    IMailbox public mailbox;
    address public remoteMessager;

    mapping(address=>address) public appPairs;

    constructor(address _dao, address _mailbox, uint256 _remoteChainId) {
        _initialize(_dao);
        mailbox = IMailbox(_mailbox);
        REMOTE_CHAINID = _remoteChainId;
    }

    function setRemoteMessager(address _remoteMessager) onlyDao external {
        remoteMessager = _remoteMessager;
    }

    function registerRemoteReceiver(uint256 _remoteChainId, address _remoteBridge) onlyWhiteListCaller external {
        require(_remoteChainId == REMOTE_CHAINID, "invalid remote chainId");
        appPairs[msg.sender] = _remoteBridge;
    }

    function sendMessage(uint256 _remoteChainId, bytes memory _message, bytes memory _params) onlyWhiteListCaller external payable {
        require(_remoteChainId == REMOTE_CHAINID, "invalid remote chainId");
        address remoteAppAddress = appPairs[msg.sender];
        require(remoteAppAddress != address(0), "app not registered");

        (uint256 l2GasLimit, uint256 l2GasPerPubdataByteLimit, address refunder) = abi.decode(_params, (uint256, uint256, address));

        bytes memory remoteReceiveCall = abi.encodeWithSelector(
            ILowLevelMessageReceiver.recvMessage.selector,
            msg.sender,
            remoteAppAddress,
            _message
        );
        mailbox.requestL2Transaction{value: msg.value}(
            remoteMessager,
            0,
            remoteReceiveCall,
            l2GasLimit,
            l2GasPerPubdataByteLimit,
            new bytes[](0),
            refunder
        );
    }

    function fee(
        uint256 _gasPrice,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit
    ) external view returns(uint256) {
        return mailbox.l2TransactionBaseCost(_gasPrice, _l2GasLimit, _l2GasPerPubdataByteLimit);
    }

    function encodeParams(
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit,
        address _refunder
    ) external pure returns(bytes memory) {
        return abi.encode(_l2GasLimit, _l2GasPerPubdataByteLimit, _refunder);
    }
}

