// SPDX-License-Identifier: MIT
// This is the Issuing Module(Mapping-token-factory) of the ethereum like bridge.
// We trust the inboundLane/outboundLane when we add them to the module.
// It means that each message from the inboundLane is verified correct and truthly from the sourceAccount.
// Only we need is to verify the sourceAccount is expected. And we add it to the Filter.
pragma solidity ^0.8.10;

import "@zeppelin-solidity/contracts/utils/structs/BitMaps.sol";
import "./Erc20.sol";
import "../MappingTokenFactory.sol";
import "../../interfaces/IBacking.sol";
import "../../interfaces/IGuard.sol";
import "../../interfaces/IHelixApp.sol";
import "../../interfaces/IHelixSub2SubMessageEndpoint.sol";
import "../../interfaces/IErc20MappingTokenFactory.sol";
import "../../../utils/DailyLimit.sol";

contract Erc20Sub2SubMappingTokenFactory is DailyLimit, IErc20MappingTokenFactory, MappingTokenFactory {
    struct BurnInfo {
        bytes32 hash;
        bool hasRefundForFailed;
    }

    // guard
    address public guard;
    uint256 public helixFee;

    mapping(uint256 => BurnInfo) public burnMessages;
    BitMaps.BitMap issueMessages;
    address public xwToken;

    event NewLogicSetted(uint32 tokenType, address addr);
    event IssuingERC20Created(address originalToken, address mappingToken);
    event BurnAndRemoteUnlocked(uint256 transferId, bool isNative, bytes32 messageHash, address sender, address recipient, address token, uint256 amount, uint256 fee);
    event TokenIssued(uint256 transferId, address token, address recipient, uint256 amount);
    event TokenRemintForFailed(uint256 transferId, address token, address recipient, uint256 amount);
    event RemoteUnlockFailure(uint256 refundId, uint256 transferId, uint256 fee);

    function setMessageEndpoint(address _messageEndpoint) external onlyAdmin {
        _setMessageEndpoint(_messageEndpoint);
    }

    function setMappingNativeWrappedToken(address _xwToken) external onlyAdmin {
        xwToken = _xwToken;
    }

    receive() external payable {
    }

    /**
     * @notice only admin can transfer the ownership of the mapping token from factory to other account
     * generally we should not do this. When we encounter a non-recoverable error, we temporarily transfer the privileges to a maintenance account.
     * @param mappingToken the address the mapping token
     * @param new_owner the new owner of the mapping token
     */
    function transferMappingTokenOwnership(address mappingToken, address new_owner) external onlyAdmin {
        _transferMappingTokenOwnership(mappingToken, new_owner);
    }

    function updateGuard(address newGuard) external onlyAdmin {
        guard = newGuard;
    }

    function changeDailyLimit(address mappingToken, uint amount) public onlyAdmin  {
        _changeDailyLimit(mappingToken, amount);
    }

    function setHelixFee(uint256 _helixFee) external onlyAdmin {
        helixFee = _helixFee;
    }

    function fee() external view returns(uint256) {
        return IHelixSub2SubMessageEndpoint(messageEndpoint).fee() + helixFee;
    }

    function _sendMessage(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        bytes memory message
    ) internal nonReentrant returns(uint256, uint256) {
        uint256 bridgeFee = IHelixSub2SubMessageEndpoint(messageEndpoint).fee();
        uint256 totalFee = bridgeFee + helixFee;
        require(msg.value >= totalFee, "MTF:the fee is not enough");
        if (msg.value > totalFee) {
            // refund fee to msgSender
            payable(msg.sender).transfer(msg.value - totalFee);
        }
        uint256 transferId = IHelixSub2SubMessageEndpoint(messageEndpoint).sendMessage{value: bridgeFee}(
            remoteSpecVersion,
            remoteReceiveGasLimit,
            remoteBacking,
            message);
        return (transferId, totalFee);
    }

    /**
     * @notice create new erc20 mapping contract, this can only be called by inboundLane
     * @param originalToken the original token address
     * @param name the name of the original erc20 token
     * @param symbol the symbol of the original erc20 token
     * @param decimals the decimals of the original erc20 token
     */
    function newErc20Contract(
        address originalToken,
        string memory bridgedChainName,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 dailyLimit
    ) public onlyMessageEndpoint whenNotPaused returns (address mappingToken) {
        bytes32 salt = keccak256(abi.encodePacked(remoteBacking, originalToken));
        require(salt2MappingToken[salt] == address(0), "MTF:contract has been deployed");

        bytes memory bytecode = type(Erc20).creationCode;
        bytes memory bytecodeWithInitdata = abi.encodePacked(
            bytecode,
            abi.encode(
                string(abi.encodePacked(name, "[", bridgedChainName, ">")),
                string(abi.encodePacked("x", symbol)),
                decimals
            ));
        mappingToken = _deploy(salt, bytecodeWithInitdata);
        _addMappingToken(salt, originalToken, mappingToken);
        _changeDailyLimit(mappingToken, dailyLimit);
        emit IssuingERC20Created(originalToken, mappingToken);
    }

    /**
     * @notice issue mapping token, only can be called by inboundLane
     * @param originalToken the original token address
     * @param recipient the recipient of the issued mapping token
     * @param amount the amount of the issued mapping token
     */
    function issueMappingToken(
        address originalToken,
        address recipient,
        uint256 amount
    ) public onlyMessageEndpoint whenNotPaused {
        address mappingToken = getMappingToken(remoteBacking, originalToken);
        require(mappingToken != address(0), "MTF:mapping token has not created");
        require(amount > 0, "MTF:can not receive amount zero");
        expendDailyLimit(mappingToken, amount);
        uint256 transferId = IHelixSub2SubMessageEndpoint(messageEndpoint).lastDeliveredMessageId() + 1;
        require(BitMaps.get(issueMessages, transferId) == false, "MTF:message has been accepted");
        BitMaps.set(issueMessages, transferId);
        if (guard != address(0)) {
            Erc20(mappingToken).mint(address(this), amount);
            uint allowance = IERC20(mappingToken).allowance(address(this), guard);
            require(IERC20(mappingToken).approve(guard, allowance + amount), "MTF:approve token transfer to guard failed");
            IGuard(guard).deposit(transferId, mappingToken, recipient, amount);
        } else {
            Erc20(mappingToken).mint(recipient, amount);
        }
        emit TokenIssued(transferId, mappingToken, recipient, amount);
    }

    /**
     * @notice burn mapping token and unlock remote original token
     * @param mappingToken the burt mapping token address
     * @param recipient the recipient of the remote unlocked token
     * @param amount the amount of the burn and unlock
     */
    function _burnAndRemoteUnlock(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        address mappingToken,
        address recipient,
        uint256 amount,
        bytes memory remoteUnlockCall,
        bool isNative
    ) internal {
        require(amount > 0, "MTF:can not transfer amount zero");
        // transfer to this and then burn
        require(IERC20(mappingToken).transferFrom(msg.sender, address(this), amount), "MTF:transfer token failed");
        Erc20(mappingToken).burn(address(this), amount);

        (uint256 transferId, uint256 totalFee) = _sendMessage(
            remoteSpecVersion,
            remoteReceiveGasLimit,
            remoteUnlockCall
        );
        require(burnMessages[transferId].hash == bytes32(0), "MTF: message exist");
        bytes32 messageHash = hash(abi.encodePacked(transferId, mappingToken, msg.sender, amount));
        burnMessages[transferId] = BurnInfo(messageHash, false);
        emit BurnAndRemoteUnlocked(transferId, isNative, messageHash, msg.sender, recipient, mappingToken, amount, totalFee);
    }

    /**
     * @notice burn mapping token and unlock remote original token
     * @param mappingToken the burt mapping token address
     * @param recipient the recipient of the remote unlocked token
     * @param amount the amount of the burn and unlock
     */
    function burnAndRemoteUnlock(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        address mappingToken,
        address recipient,
        uint256 amount
    ) external payable whenNotPaused {
        address originalToken = mappingToken2OriginalToken[mappingToken];
        require(originalToken != address(0), "MTF:token is not created by factory");
        bytes memory unlockFromRemote = abi.encodeWithSelector(
            IBacking.unlockFromRemote.selector,
            originalToken,
            recipient,
            amount
        );
        _burnAndRemoteUnlock(
            remoteSpecVersion,
            remoteReceiveGasLimit,
            mappingToken,
            recipient,
            amount,
            unlockFromRemote,
            false
        );
    }

    function burnAndRemoteUnlockNative(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        address recipient,
        uint256 amount
    ) external payable whenNotPaused {
        require(amount > 0, "MTF:can not transfer amount zero");
        address originalToken = mappingToken2OriginalToken[xwToken];
        require(originalToken != address(0), "MTF:token is not created by factory");
        bytes memory unlockFromRemoteNative = abi.encodeWithSelector(
            IBackingSupportNative.unlockFromRemoteNative.selector,
            recipient,
            amount
        );
        _burnAndRemoteUnlock(
            remoteSpecVersion,
            remoteReceiveGasLimit,
            xwToken,
            recipient,
            amount,
            unlockFromRemoteNative,
            true);
    }

    /**
     * @notice send a unlock message to backing when issue mapping token faild to redeem original token.
     * @param originalToken the original token address
     * @param originalSender the originalSender of the remote unlocked token, must be the same as msg.send of the failed message.
     * @param amount the amount of the failed issue token.
     */
    function remoteUnlockFailure(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        uint256 transferId,
        address originalToken,
        address originalSender,
        uint256 amount
    ) external payable whenNotPaused {
        // must not exist in successful issue list
        require(BitMaps.get(issueMessages, transferId) == false, "MTF:success message can't refund for failed");
        // must has been checked by message layer
        bool messageChecked = IHelixSub2SubMessageEndpoint(messageEndpoint).isMessageDelivered(transferId);
        require(messageChecked, "MTF:the message is not checked by message layer");
        bytes memory handleUnlockForFailed = abi.encodeWithSelector(
            IHelixAppSupportWithdrawFailed.handleUnlockFailureFromRemote.selector,
            transferId,
            originalToken,
            originalSender,
            amount
        );
        (uint256 refundId, uint256 totalFee) = _sendMessage(
            remoteSpecVersion,
            remoteReceiveGasLimit,
            handleUnlockForFailed
        );
        emit RemoteUnlockFailure(refundId, transferId, totalFee);
    }

    /**
     * @notice send a unlock message to backing when issue mapping token faild to redeem original token.
     * @param originalSender the originalSender of the remote unlocked token, must be the same as msg.send of the failed message.
     * @param amount the amount of the failed issue token.
     */
    function remoteUnlockFailureNative(
        uint32  remoteSpecVersion,
        uint256 remoteReceiveGasLimit,
        uint256 transferId,
        address originalSender,
        uint256 amount
    ) external payable whenNotPaused {
        // must not exist in successful issue list
        require(BitMaps.get(issueMessages, transferId) == false, "MTF:success message can't refund for failed");
        // must has been checked by message layer
        bool messageChecked = IHelixSub2SubMessageEndpoint(messageEndpoint).isMessageDelivered(transferId);
        require(messageChecked, "MTF:the message is not checked by message layer");
        bytes memory handleUnlockForFailed = abi.encodeWithSelector(
            IHelixAppSupportWithdrawFailed.handleUnlockFailureFromRemoteNative.selector,
            transferId,
            originalSender,
            amount
        );
        (uint256 refundId, uint256 totalFee) = _sendMessage(
            remoteSpecVersion,
            remoteReceiveGasLimit,
            handleUnlockForFailed
        );
        emit RemoteUnlockFailure(refundId, transferId, totalFee);
    }

    /**
     * @notice this will be called by messageEndpoint when the remote backing unlock failed and want to unlock the mapping token
     * @param token the original token address
     * @param origin_sender the origin_sender who will receive the unlocked token
     * @param amount amount of the unlocked token
     */
    function handleIssuingFailureFromRemote(
        uint256 transferId,
        address token,
        address origin_sender,
        uint256 amount
    ) external onlyMessageEndpoint whenNotPaused {
        BurnInfo memory burnInfo = burnMessages[transferId];
        require(burnInfo.hasRefundForFailed == false, "MTF:the burn message has been refund");
        bytes32 messageHash = hash(abi.encodePacked(transferId, token, origin_sender, amount));
        require(burnInfo.hash == messageHash, "MTF:message is not matched");
        burnMessages[transferId].hasRefundForFailed = true;
        // remint token
        Erc20(token).mint(origin_sender, amount);
        emit TokenRemintForFailed(transferId, token, origin_sender, amount);
    }

    function hash(bytes memory value) public pure returns (bytes32) {
        return sha256(value);
    }

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
}

