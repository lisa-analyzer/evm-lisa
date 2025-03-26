// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../AccessController.sol";
import "../../interfaces/ICrossChainFilter.sol";
import "../../interfaces/IFeeMarket.sol";
import "../../interfaces/IHelixApp.sol";
import "../../interfaces/IInboundLane.sol";
import "../../interfaces/IOutboundLane.sol";

contract DarwiniaSub2EthMessageEndpoint is ICrossChainFilter, AccessController {
    address immutable public inboundLane;
    address immutable public outboundLane;
    address immutable public feeMarket;
    uint16 immutable public version;

    address public remoteEndpoint;

    constructor(
        uint16 _version,
        address _inboundLane,
        address _outboundLane,
        address _feeMarket
    ) {
        version = _version;
        inboundLane = _inboundLane;
        outboundLane = _outboundLane;
        feeMarket = _feeMarket;
        _initialize(msg.sender);
    }

    modifier onlyInboundLane() {
        require(inboundLane == msg.sender, "DarwiniaSub2EthMessageEndpoint:caller is not the inboundLane account");
        _;
    }

    modifier onlyOutBoundLane() {
        require(outboundLane == msg.sender, "DarwiniaSub2EthMessageEndpoint:caller is not the outboundLane account");
        _;
    }

    function setRemoteEndpoint(address _remoteEndpoint) external onlyAdmin {
        require(remoteEndpoint == address(0), "DarwiniaSub2EthMessageEndpoint:can only set once");
        remoteEndpoint = _remoteEndpoint;
    }

    function cross_chain_filter(
        uint32,
        uint32,
        address sourceAccount,
        bytes calldata
    ) external view returns (bool) {
        return inboundLane == msg.sender && remoteEndpoint == sourceAccount;
    }

    function fee() public view returns(uint256) {
        return IFeeMarket(feeMarket).market_fee();
    }

    function nonceToMessageId(uint256 nonce) internal view returns(uint256) {
        return (uint256(version) << 64) + nonce;
    }

    function sendMessage(address receiver, bytes calldata message) external onlyCaller payable returns (uint256) {
        bytes memory messageWithCaller = abi.encodeWithSelector(
            DarwiniaSub2EthMessageEndpoint.recvMessage.selector,
            receiver,
            message
        );
        uint256 nonce = IOutboundLane(outboundLane).send_message{value: msg.value}(
            remoteEndpoint,
            messageWithCaller
        );
        return nonceToMessageId(nonce);
    }

    function recvMessage(
        address receiver,
        bytes calldata message
    ) external onlyInboundLane whenNotPaused {
        require(hasRole(CALLEE_ROLE, receiver), "DarwiniaSub2EthMessageEndpoint:receiver is not callee");
        (bool result,) = receiver.call(message);
        require(result, "DarwiniaSub2EthMessageEndpoint:call app failed");
    }

    // we use nonce as message id
    function currentDeliveredMessageId() public view returns(uint256) {
        IInboundLane.InboundLaneNonce memory inboundLaneNonce = IInboundLane(inboundLane).inboundLaneNonce();
        return nonceToMessageId(inboundLaneNonce.last_delivered_nonce + 1);
    }

    function isMessageDelivered(uint256 messageId) public view returns (bool) {
        IInboundLane.InboundLaneNonce memory inboundLaneNonce = IInboundLane(inboundLane).inboundLaneNonce();
        uint256 lastMessageNonce = inboundLaneNonce.last_delivered_nonce;
        return messageId <= nonceToMessageId(lastMessageNonce);
    }
}

