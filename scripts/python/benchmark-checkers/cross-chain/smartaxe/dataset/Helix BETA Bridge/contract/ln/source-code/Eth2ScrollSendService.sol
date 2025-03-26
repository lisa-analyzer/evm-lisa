// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interface/IScrollMessenger.sol";
import "../base/LnAccessController.sol";
import "../interface/ILowLevelMessager.sol";

contract Eth2ScrollSendService is ILowLevelMessageSender, LnAccessController {
    uint256 immutable public REMOTE_CHAINID;
    IScrollMessenger immutable public scrollMessager;
    address public remoteMessager;
    mapping(address=>address) public appPairs;

    constructor(address _dao, address _scrollMessager, uint256 _remoteChainId) {
        _initialize(_dao);
        scrollMessager = IScrollMessenger(_scrollMessager);
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

        (uint256 l2GasLimit, address refunder) = abi.decode(_params, (uint256, address));

        bytes memory remoteReceiveCall = abi.encodeWithSelector(
            ILowLevelMessageReceiver.recvMessage.selector,
            msg.sender,
            remoteAppAddress,
            _message
        );
        scrollMessager.sendMessage{value: msg.value}(
            remoteMessager,
            0,
            remoteReceiveCall,
            l2GasLimit,
            refunder
        );
    }

    function fee(uint256 _l2GasLimit) external view returns(uint256) {
        address messageQueue = scrollMessager.messageQueue();
        return IL1MessageQueue(messageQueue).estimateCrossDomainMessageFee(_l2GasLimit);
    }

    function encodeParams(
        uint256 _l2GasLimit,
        address _refunder
    ) external pure returns(bytes memory) {
        return abi.encode(_l2GasLimit, _refunder);
    }
}
