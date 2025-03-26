// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "@zeppelin-solidity/contracts/utils/structs/BitMaps.sol";
import "../Backing.sol";
import "../../interfaces/IBacking.sol";
import "../../interfaces/IErc20MappingTokenFactory.sol";
import "../../interfaces/IGuard.sol";
import "../../interfaces/IHelixApp.sol";
import "../../interfaces/IHelixSub2EthMessageEndpoint.sol";
import "../../interfaces/IWToken.sol";
import "../../../utils/DailyLimit.sol";

contract Erc20Sub2EthBacking is Backing, DailyLimit, IBacking {
    struct LockedInfo {
        bytes32 hash;
        bool hasRefundForFailed;
    }
    address public guard;
    uint256 public helixFee;
    // This is the wrapped native token address
    address public wToken;

    // (transferId => lockedInfo)
    mapping(uint256 => LockedInfo) public lockedMessages;
    BitMaps.BitMap unlockedTransferIds;

    event TokenLocked(uint256 transferId, bool isNative, address token, address sender, address recipient, uint256 amount, uint256 fee);
    event TokenUnlocked(uint256 transferId, bool isNative, address token, address recipient, uint256 amount);
    event RemoteIssuingFailure(uint256 refundId, uint256 transferId, address mappingToken, address originalSender, uint256 amount, uint256 fee);
    event TokenUnlockedForFailed(uint256 transferId, bool isNative, address token, address recipient, uint256 amount);

    receive() external payable {}

    // !!! admin must check the nonce of the newEndpoint is larger than the old one
    function setMessageEndpoint(address _messageEndpoint) external onlyAdmin {
        _setMessageEndpoint(_messageEndpoint);
    }

    function changeDailyLimit(address token, uint amount) public onlyAdmin  {
        _changeDailyLimit(token, amount);
    }

    function setHelixFee(uint256 _helixFee) external onlyAdmin {
        helixFee = _helixFee;
    }

    function setNativeWrappedToken(address _wToken) external onlyAdmin {
        wToken = _wToken;
    }

    function updateGuard(address newGuard) external onlyAdmin {
        guard = newGuard;
    }

    function currentFee() external view returns(uint256) {
        return IHelixSub2EthMessageEndpoint(messageEndpoint).fee() + helixFee;
    }

    // we use messageId as transferId directly here
    function _sendMessage(bytes memory message, uint256 prepaid) internal nonReentrant returns(uint256, uint256) {
        uint256 bridgeFee = IHelixSub2EthMessageEndpoint(messageEndpoint).fee();
        uint256 totalFee = bridgeFee + helixFee;
        require(prepaid >= totalFee, "backing:the fee is not enough");
        if (prepaid > totalFee) {
            // refund fee to msgSender
            payable(msg.sender).transfer(prepaid - totalFee);
        }
        uint256 transferId = IHelixSub2EthMessageEndpoint(messageEndpoint).sendMessage{value: bridgeFee}(
            remoteMappingTokenFactory,
            message);
        return (transferId, totalFee);
    }

    function _lockAndRemoteIssuing(
        address token,
        address recipient,
        uint256 amount,
        uint256 prepaid,
        bool isNative
    ) internal {
        bytes memory issueMappingToken = abi.encodeWithSelector(
            IErc20MappingTokenFactory.issueMappingToken.selector,
            token,
            recipient,
            amount
        );
        (uint256 transferId, uint256 fee) = _sendMessage(issueMappingToken, prepaid);
        bytes32 lockMessageHash = hash(abi.encodePacked(transferId, token, msg.sender, amount));
        lockedMessages[transferId] = LockedInfo(lockMessageHash, false);
        emit TokenLocked(transferId, isNative, token, msg.sender, recipient, amount, fee);
    }

    /**
     * @notice lock original token and issuing mapping token from bridged chain
     * @dev maybe some tokens will take some fee when transfer
     * @param token the original token address
     * @param recipient the recipient who will receive the issued mapping token
     * @param amount amount of the locked token
     */
    function lockAndRemoteIssuing(
        address token,
        address recipient,
        uint256 amount
    ) external payable whenNotPaused {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Backing:transfer tokens failed");
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(balanceBefore + amount == balanceAfter, "Backing:Transfer amount is invalid");
        _lockAndRemoteIssuing(token, recipient, amount, msg.value, false);
    }

    /**
     * @notice lock original native token and issuing mapping token from bridged chain
     * @dev maybe some tokens will take some fee when transfer
     * @param recipient the recipient who will receive the issued mapping token
     * @param amount amount of the locked token
     */
    function lockAndRemoteIssuingNative(
        address recipient,
        uint256 amount
    ) external payable whenNotPaused {
        require(msg.value > amount, "Backing: msg.value must larger than amount");
        IWToken(wToken).deposit{value: amount}();
        _lockAndRemoteIssuing(wToken, recipient, amount, msg.value - amount, true);
    }

    /**
     * @notice this will be called by inboundLane when the remote mapping token burned and want to unlock the original token
     * @param token the original token address
     * @param recipient the recipient who will receive the unlocked token
     * @param amount amount of the unlocked token
     */
    function unlockFromRemote(
        address token,
        address recipient,
        uint256 amount
    ) public onlyMessageEndpoint whenNotPaused {
        uint256 transferId = IHelixSub2EthMessageEndpoint(messageEndpoint).currentDeliveredMessageId();
        require(BitMaps.get(unlockedTransferIds, transferId) == false, "Backing:message has been accepted");
        BitMaps.set(unlockedTransferIds, transferId);
        expendDailyLimit(token, amount);
        if (guard != address(0)) {
            // see https://github.com/helix-bridge/contracts/issues/18
            uint allowance = IERC20(token).allowance(address(this), guard);
            require(IERC20(token).approve(guard, allowance + amount), "Backing:approve token transfer to guard failed");
            IGuard(guard).deposit(transferId, token, recipient, amount);
        } else {
            require(IERC20(token).transfer(recipient, amount), "Backing:unlock transfer failed");
        }
        emit TokenUnlocked(transferId, false, token, recipient, amount);
    }

    /**
     * @notice this will be called by inboundLane when the remote mapping token burned and want to unlock the original native token
     * @param recipient the recipient who will receive the unlocked token
     * @param amount amount of the unlocked token
     */
    function unlockFromRemoteNative(
        address payable recipient,
        uint256 amount
    ) public onlyMessageEndpoint whenNotPaused {
        expendDailyLimit(wToken, amount);
        uint256 transferId = IHelixSub2EthMessageEndpoint(messageEndpoint).currentDeliveredMessageId();
        require(BitMaps.get(unlockedTransferIds, transferId) == false, "Backing:message has been accepted");
        BitMaps.set(unlockedTransferIds, transferId);
        if (guard != address(0)) {
            uint allowance = IERC20(wToken).allowance(address(this), guard);
            require(IERC20(wToken).approve(guard, allowance + amount), "Backing:approve token transfer to guard failed");
            IGuard(guard).deposit(transferId, wToken, recipient, amount);
        } else {
            IWToken(wToken).withdraw(amount);
            recipient.transfer(amount);
        }
        emit TokenUnlocked(transferId, true, wToken, recipient, amount);
    }

    function remoteIssuingFailure(
        uint256 transferId,
        address mappingToken,
        address originalSender,
        uint256 amount
    ) external payable whenNotPaused {
        // must not exist in successful issue list
        require(BitMaps.get(unlockedTransferIds, transferId) == false, "Backing:success message can't refund for failed");
        bool messageChecked = IHelixSub2EthMessageEndpoint(messageEndpoint).isMessageDelivered(transferId);
        require(messageChecked, "Backing:the message is not checked by message layer");
        bytes memory unlockForFailed = abi.encodeWithSelector(
            IHelixAppSupportWithdrawFailed.handleIssuingFailureFromRemote.selector,
            transferId,
            mappingToken,
            originalSender,
            amount
        );
        (uint256 refundId, uint256 fee) = _sendMessage(unlockForFailed, msg.value);
        emit RemoteIssuingFailure(refundId, transferId, mappingToken, originalSender, amount, fee);
    }

    /**
     * @notice this will be called by messageEndpoint when the remote issue failed and want to unlock the original token
     * @param token the original token address
     * @param originSender the origin sender who will receive the unlocked token
     * @param amount amount of the unlocked token
     */
    function _handleUnlockFailureFromRemote(
        uint256 transferId,
        address token,
        address originSender,
        uint256 amount
    ) internal whenNotPaused {
        LockedInfo memory lockedMessage = lockedMessages[transferId];
        require(lockedMessage.hasRefundForFailed == false, "Backing: the locked message has been refund");
        bytes32 messageHash = hash(abi.encodePacked(transferId, token, originSender, amount));
        require(lockedMessage.hash == messageHash, "Backing: message is not matched");
        lockedMessages[transferId].hasRefundForFailed = true;
    }

    /**
     * @notice this will be called by messageEndpoint when the remote issue failed and want to unlock the original token
     * @param token the original token address
     * @param originSender the origin sender who will receive the unlocked token
     * @param amount amount of the unlocked token
     */
    function handleUnlockFailureFromRemote(
        uint256 transferId,
        address token,
        address originSender,
        uint256 amount
    ) external onlyMessageEndpoint {
        _handleUnlockFailureFromRemote(transferId, token, originSender, amount);
        require(IERC20(token).transfer(originSender, amount), "Backing:unlock transfer failed");
        emit TokenUnlockedForFailed(transferId, false, token, originSender, amount);
    }

    /**
     * @notice this will be called by messageEndpoint when the remote issue failed and want to unlock the original token
     * @param originSender the origin sender who will receive the unlocked token
     * @param amount amount of the unlocked token
     */
    function handleUnlockFailureFromRemoteNative(
        uint256 transferId,
        address originSender,
        uint256 amount
    ) external onlyMessageEndpoint {
        _handleUnlockFailureFromRemote(transferId, wToken, originSender, amount);
        IWToken(wToken).withdraw(amount);
        payable(originSender).transfer(amount);
        emit TokenUnlockedForFailed(transferId, true, wToken, originSender, amount);
    }

    /**
     * @notice this should not be used unless there is a non-recoverable error in the bridge or the target chain
     * we use this to protect user's asset from being locked up
     */
    function rescueFunds(
        address token,
        address recipient,
        uint256 amount
    ) external onlyAdmin {
        IERC20(token).transfer(recipient, amount);
    }


    function hash(bytes memory value) public pure returns (bytes32) {
        return sha256(value);
    }
}
 
