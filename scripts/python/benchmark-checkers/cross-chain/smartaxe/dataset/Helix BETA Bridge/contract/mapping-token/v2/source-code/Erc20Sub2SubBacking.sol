// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "@zeppelin-solidity/contracts/utils/structs/BitMaps.sol";
import "../Backing.sol";
import "../../interfaces/IBacking.sol";
import "../../interfaces/IErc20MappingTokenFactory.sol";
import "../../interfaces/IGuard.sol";
import "../../interfaces/IHelixApp.sol";
import "../../interfaces/IHelixSub2SubMessageEndpoint.sol";
import "../../interfaces/IWToken.sol";
import "../../../utils/DailyLimit.sol";

contract Erc20Sub2SubBacking is Backing, DailyLimit, IBacking {
    struct LockedInfo {
        bytes32 hash;
        bool hasRefundForFailed;
    }

    address public guard;
    string  public chainName;
    uint256 public helixFee;

    // (transferId => LockedInfo)
    mapping(uint256 => LockedInfo) public lockedMessages;
    BitMaps.BitMap unlockedMessages;
    address public wToken;

    event NewErc20TokenRegistered(uint256 transferId, address token);
    event TokenLocked(uint256 transferId, bool isNative, address token, address sender, address recipient, uint256 amount, uint256 fee);
    event TokenUnlocked(uint256 transferId, bool isNative, address token, address recipient, uint256 amount);
    event RemoteIssuingFailure(uint256 refundId, uint256 transferId, uint256 fee);
    event TokenUnlockedForFailed(uint256 transferId, bool isNative, address token, address recipient, uint256 amount);

    receive() external payable {}

    function setMessageEndpoint(address _messageEndpoint) external onlyAdmin {
        _setMessageEndpoint(_messageEndpoint);
    }

    function setChainName(string memory _chainName) external onlyAdmin {
        chainName = _chainName;
    }

    function changeDailyLimit(address token, uint amount) public onlyAdmin  {
        _changeDailyLimit(token, amount);
    }

    function setHelixFee(uint256 _helixFee) external onlyAdmin {
        helixFee = _helixFee;
    }

    function updateGuard(address newGuard) external onlyAdmin {
        guard = newGuard;
    }

    function setWToken(address _wToken) external onlyAdmin {
        wToken = _wToken;
    }

    function fee() external view returns(uint256) {
        return IHelixSub2SubMessageEndpoint(messageEndpoint).fee() + helixFee;
    }

    function _sendMessage(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        bytes memory message,
        uint256 prepaid
    ) internal nonReentrant returns(uint256, uint256) {
        uint256 bridgeFee = IHelixSub2SubMessageEndpoint(messageEndpoint).fee();
        uint256 totalFee = bridgeFee + helixFee;
        require(prepaid >= totalFee, "Backing:the fee is not enough");
        if (prepaid > totalFee) {
            // refund fee to msgSender
            payable(msg.sender).transfer(prepaid - totalFee);
        }
        uint256 transferId = IHelixSub2SubMessageEndpoint(messageEndpoint).sendMessage{value: bridgeFee}(
            remoteSpecVersion,
            remoteReceiveGasLimit,
            remoteMappingTokenFactory,
            message);
        return (transferId, totalFee);
    }

    /**
     * @notice reigister new erc20 token to the bridge. Only owner can do this.
     * @param token the original token address
     * @param name the name of the original token
     * @param symbol the symbol of the original token
     * @param decimals the decimals of the original token
     */
    function register(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        address token,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 dailyLimit
    ) external payable onlyOperator {
        bytes memory newErc20Contract = abi.encodeWithSelector(
            IErc20MappingTokenFactory.newErc20Contract.selector,
            token,
            chainName,
            name,
            symbol,
            decimals,
            dailyLimit
        );
        (uint256 transferId,) = _sendMessage(
            remoteSpecVersion,
            remoteReceiveGasLimit,
            newErc20Contract,
            msg.value
        );
        _changeDailyLimit(token, dailyLimit);
        emit NewErc20TokenRegistered(transferId, token);
    }

    function _lockAndRemoteIssuing(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
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
        (uint256 transferId, uint256 totalFee) = _sendMessage(
            remoteSpecVersion,
            remoteReceiveGasLimit,
            issueMappingToken,
            prepaid
        );
        require(lockedMessages[transferId].hash == bytes32(0), "backing: message exist");
        bytes32 lockMessageHash = hash(abi.encodePacked(transferId, token, msg.sender, amount));
        lockedMessages[transferId] = LockedInfo(lockMessageHash, false);
        emit TokenLocked(transferId, isNative, token, msg.sender, recipient, amount, totalFee);
    }


    /**
     * @notice lock original token and issuing mapping token from bridged chain
     * @dev maybe some tokens will take some fee when transfer
     * @param token the original token address
     * @param recipient the recipient who will receive the issued mapping token
     * @param amount amount of the locked token
     */
    function lockAndRemoteIssuing(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        address token,
        address recipient,
        uint256 amount
    ) external payable whenNotPaused {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Backing:transfer tokens failed");
        _lockAndRemoteIssuing(
            remoteSpecVersion,
            remoteReceiveGasLimit,
            token,
            recipient,
            amount,
            msg.value,
            false);
    }

    function lockAndRemoteIssuingNative(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        address recipient,
        uint256 amount
    ) external payable whenNotPaused {
        IWToken(wToken).deposit{value: amount}();
        _lockAndRemoteIssuing(
            remoteSpecVersion,
            remoteReceiveGasLimit,
            wToken,
            recipient,
            amount,
            msg.value - amount,
            true);
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
        expendDailyLimit(token, amount);
        // current message id is last message id + 1
        uint256 transferId = IHelixSub2SubMessageEndpoint(messageEndpoint).lastDeliveredMessageId() + 1;
        require(BitMaps.get(unlockedMessages, transferId) == false, "Backing:message has been accepted");
        BitMaps.set(unlockedMessages, transferId);
        if (guard != address(0)) {
            uint allowance = IERC20(token).allowance(address(this), guard);
            require(IERC20(token).approve(guard, amount + allowance), "Backing:approve token transfer to guard failed");
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
        uint256 transferId = IHelixSub2SubMessageEndpoint(messageEndpoint).lastDeliveredMessageId() + 1;
        require(BitMaps.get(unlockedMessages, transferId) == false, "Backing:message has been accepted");
        BitMaps.set(unlockedMessages, transferId);
        if (guard != address(0)) {
            uint allowance = IERC20(wToken).allowance(address(this), guard);
            require(IERC20(wToken).approve(guard, amount + allowance), "Backing:approve token transfer to guard failed");
            IGuard(guard).deposit(transferId, wToken, recipient, amount);
        } else {
            IWToken(wToken).withdraw(amount);
            recipient.transfer(amount);
        }
        emit TokenUnlocked(transferId, true, wToken, recipient, amount);
    }

    function _handleUnlockFailureFromRemote(
        uint256 transferId,
        address token,
        address originSender,
        uint256 amount
    ) internal {
        LockedInfo memory lockedMessage = lockedMessages[transferId];
        require(lockedMessage.hasRefundForFailed == false, "Backing: the locked message has been refund");
        bytes32 messageHash = hash(abi.encodePacked(transferId, token, originSender, amount));
        require(lockedMessage.hash == messageHash, "Backing: message is not matched");
        lockedMessages[transferId].hasRefundForFailed = true;
    }

    /**
     * @notice this will be called by messageEndpoint when the remote issue failed and want to unlock the original token
     * @param token the original token address
     * @param originSender the originSender who will receive the unlocked token
     * @param amount amount of the unlocked token
     */
    function handleUnlockFailureFromRemote(
        uint256 transferId,
        address token,
        address originSender,
        uint256 amount
    ) external onlyMessageEndpoint whenNotPaused {
        _handleUnlockFailureFromRemote(transferId, token, originSender, amount);
        require(IERC20(token).transfer(originSender, amount), "Backing:unlock transfer failed");
        emit TokenUnlockedForFailed(transferId, false, token, originSender, amount);
    }

    /**
     * @notice this will be called by messageEndpoint when the remote issue failed and want to unlock the original native token
     * @param originSender the originSender who will receive the unlocked token
     * @param amount amount of the unlocked token
     */
    function handleUnlockFailureFromRemoteNative(
        uint256 transferId,
        address originSender,
        uint256 amount
    ) external onlyMessageEndpoint whenNotPaused {
        _handleUnlockFailureFromRemote(transferId, wToken, originSender, amount);
        IWToken(wToken).withdraw(amount);
        payable(originSender).transfer(amount);
        emit TokenUnlockedForFailed(transferId, true, wToken, originSender, amount);
    }

    function remoteIssuingFailure(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        uint256 transferId,
        address mappingToken,
        address originalSender,
        uint256 amount
    ) external payable whenNotPaused {
        // must not exist in successful issue list
        require(BitMaps.get(unlockedMessages, transferId) == false, "Backing:success message can't refund for failed");
        // must has been checked by message layer
        bool messageChecked = IHelixSub2SubMessageEndpoint(messageEndpoint).isMessageDelivered(transferId);
        require(messageChecked, "Backing:the message is not checked by message layer");
        bytes memory unlockForFailed = abi.encodeWithSelector(
            IHelixAppSupportWithdrawFailed.handleIssuingFailureFromRemote.selector,
            transferId,
            mappingToken,
            originalSender,
            amount
        );
        (uint256 refundId, uint256 totalFee) = _sendMessage(
            remoteSpecVersion,
            remoteReceiveGasLimit,
            unlockForFailed,
            msg.value
        );
        emit RemoteIssuingFailure(refundId, transferId, totalFee);
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

    function withdrawFee(
        address payable recipient,
        uint256 amount
    ) external onlyAdmin {
        recipient.transfer(amount);
    }

    function hash(bytes memory value) public pure returns (bytes32) {
        return sha256(value);
    }
}
