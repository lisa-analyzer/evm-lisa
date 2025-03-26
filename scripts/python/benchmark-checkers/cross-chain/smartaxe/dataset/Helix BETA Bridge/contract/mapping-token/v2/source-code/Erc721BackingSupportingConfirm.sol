// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// This is the backing contract for Erc721 token
// Before the new Erc721 token registered, user should create two AttributesSerializer contract first
// One is deployed on the source chain to serialize the attributes of the token when lock_and_remote_issuing,
// and deserialize the attributes of the mapping token when unlock_from_remote
// The other is deployed on the target chain to deserialize the attributes of the token when the mapping token minted,
// and serialize the attributes of the mapping token when burn_and_unlock
// The AttributesSerializer must implement interfaces in IErc721AttrSerializer.

import "@zeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "../Backing.sol";
import "../../interfaces/IErc721AttrSerializer.sol";
import "../../interfaces/IErc721Backing.sol";
import "../../interfaces/IErc721MappingTokenFactory.sol";
import "../../interfaces/IHelixMessageEndpoint.sol";

contract Erc721BackingSupportingConfirm is Backing, IErc721Backing {
    struct LockedInfo {
        address token;
        address sender;
        uint256[] ids;
    }

    struct TokenInfo {
        address token;
        address serializer;
    }

    // (messageId => tokenAddress)
    mapping(uint256 => TokenInfo) public registerMessages;

    // tokenAddress => reistered
    mapping(address => TokenInfo) public registeredTokens;

    // (messageId => lockedInfo)
    mapping(uint256 => LockedInfo) public lockMessages;

    event NewErc721TokenRegistered(uint256 messageId, address token);
    event TokenLocked(uint256 messageId, address token, address recipient, uint256[] ids);
    event TokenLockFinished(uint256 messageId, bool result);
    event TokenRegisterFinished(uint256 messageId, bool result);
    event TokenUnlocked(address token, address recipient, uint256[] ids);

    function setMessageEndpoint(address _messageEndpoint) external onlyAdmin {
        _setMessageEndpoint(_messageEndpoint);
    }

    /**
     * @notice reigister new erc721 token to the bridge. Only owner can do this.
     * @param token the original token address
     * @param attributesSerializer local serializer address of the token's attributes
     * @param remoteAttributesSerializer remote serializer address of the mapping token's attributes
     */
    function registerErc721Token(
        address token,
        address attributesSerializer,
        address remoteAttributesSerializer
    ) external payable onlyOperator {
        require(registeredTokens[token].token == address(0), "Erc721Backing:token has been registered");
        bytes memory newErc721Contract = abi.encodeWithSelector(
            IErc721MappingTokenFactory.newErc721Contract.selector,
            token,
            remoteAttributesSerializer
        );
        uint256 messageId = IHelixMessageEndpoint(messageEndpoint).sendMessage{value: msg.value}(remoteMappingTokenFactory, newErc721Contract);
        // save register info waiting for confirm
        registerMessages[messageId] = TokenInfo(token, attributesSerializer);
        emit NewErc721TokenRegistered(messageId, token);
    }

    /**
     * @notice lock original token and issuing mapping token from bridged chain
     * @dev maybe some tokens will take some fee when transfer
     * @param token the original token address
     * @param recipient the recipient who will receive the issued mapping token
     * @param ids ids of the locked token
     */
    function lockAndRemoteIssuing(
        address token,
        address recipient,
        uint256[] calldata ids
    ) external payable whenNotPaused {
        TokenInfo memory info = registeredTokens[token];
        require(info.token != address(0), "Erc721Backing:the token is not registed");

        bytes[] memory attrs = new bytes[](ids.length);
        for (uint idx = 0; idx < ids.length; idx++) {
            IERC721(token).transferFrom(msg.sender, address(this), ids[idx]);
            if (info.serializer != address(0)) {
                attrs[idx] = IErc721AttrSerializer(info.serializer).serialize(ids[idx]);
            }
        }

        bytes memory issueMappingToken = abi.encodeWithSelector(
            IErc721MappingTokenFactory.issueMappingToken.selector,
            token,
            recipient,
            ids,
            attrs
        );
        uint256 messageId = IHelixMessageEndpoint(messageEndpoint).sendMessage{value: msg.value}(remoteMappingTokenFactory, issueMappingToken);
        lockMessages[messageId] = LockedInfo(token, msg.sender, ids);
        emit TokenLocked(messageId, token, recipient, ids);
    }

    /**
     * @notice this will be called by outboundLane when the register/lock message confirmed
     * @param messageId message id to identify the register/lock message
     * @param result the result of the remote call
     */
    function onMessageDelivered(
        uint256 messageId,
        bool result
    ) external onlyMessageEndpoint {
        LockedInfo memory lockedInfo = lockMessages[messageId];
        // it is lock message, if result is false, need to transfer back to the user, otherwise will be locked here
        if (lockedInfo.token != address(0)) {
            delete lockMessages[messageId];
            if (!result) {
                for (uint idx = 0; idx < lockedInfo.ids.length; idx++) {
                    IERC721(lockedInfo.token).transferFrom(address(this), lockedInfo.sender, lockedInfo.ids[idx]);
                }
            }
            emit TokenLockFinished(messageId, result);
            return;
        }
        TokenInfo memory info = registerMessages[messageId];
        // it is register message, if result is true, need to save the token
        if (info.token != address(0)) {
            delete registerMessages[messageId];
            if (result) {
                registeredTokens[info.token] = info;
            }
            emit TokenRegisterFinished(messageId, result);
        }
    }

    /**
     * @notice this will be called by inboundLane when the remote mapping token burned and want to unlock the original token
     * @param token the original token address
     * @param recipient the recipient who will receive the unlocked token
     * @param ids ids of the unlocked token
     * @param attrs the serialized data of the token's attributes may be updated from mapping token
     */
    function unlockFromRemote(
        address token,
        address recipient,
        uint256[] calldata ids,
        bytes[] calldata attrs
    ) public onlyMessageEndpoint whenNotPaused {
        TokenInfo memory info = registeredTokens[token];
        require(info.token != address(0), "Erc721Backing:the token is not registered");
        for (uint idx = 0; idx < ids.length; idx++) {
            IERC721(token).transferFrom(address(this), recipient, ids[idx]);
            if (info.serializer != address(0)) {
                IErc721AttrSerializer(info.serializer).deserialize(ids[idx], attrs[idx]);
            }
        }
        emit TokenUnlocked(token, recipient, ids);
    }

    /**
     * @notice this should not be used unless there is a non-recoverable error in the bridge or the target chain
     * we use this to protect user's asset from being locked up
     */
    function rescueFunds(
        address token,
        uint256 id,
        address recipient
    ) external onlyAdmin {
        IERC721(token).transferFrom(address(this), recipient, id);
    }
}
 
