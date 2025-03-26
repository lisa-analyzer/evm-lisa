// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// This is the backing contract for Erc721 token
// Before the new Erc721 token registered, user should create two AttributesSerializer contract first
// One is deployed on the source chain to serialize the attributes of the token when lock_and_remote_issuing,
// and deserialize the attributes of the mapping token when unlock_from_remote
// The other is deployed on the target chain to deserialize the attributes of the token when the mapping token minted,
// and serialize the attributes of the mapping token when burn_and_unlock
// The AttributesSerializer must implement interfaces in IErc721AttrSerializer.
// It only receive message from messageEndpoint, and send message by messageEndpoint

import "@zeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "../Backing.sol";
import "../../interfaces/IErc721AttrSerializer.sol";
import "../../interfaces/IErc721Backing.sol";
import "../../interfaces/IErc721MappingTokenFactory.sol";
import "../../interfaces/IHelixMessageEndpoint.sol";

contract Erc721BackingUnsupportingConfirm is Backing, IErc721Backing {
    struct TokenInfo {
        address token;
        address serializer;
    }
    // tokenAddress => reistered
    mapping(address => TokenInfo) public registeredTokens;

    event NewErc721TokenRegistered(address token);
    event TokenLocked(address token, address recipient, uint256[] ids);
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
        require(registeredTokens[token].token == address(0), "Erc721BackingUnsupportingConfirm:token has been registered");
        bytes memory newErc721Contract = abi.encodeWithSelector(
            IErc721MappingTokenFactory.newErc721Contract.selector,
            token,
            remoteAttributesSerializer
        );
        IHelixMessageEndpoint(messageEndpoint).sendMessage{value: msg.value}(remoteMappingTokenFactory, newErc721Contract);
        registeredTokens[token] = TokenInfo(token, attributesSerializer);
        emit NewErc721TokenRegistered(token);
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
        require(info.token != address(0), "Erc721BackingUnsupportingConfirm:the token is not registed");

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
        IHelixMessageEndpoint(messageEndpoint).sendMessage{value: msg.value}(remoteMappingTokenFactory, issueMappingToken);
        emit TokenLocked(token, recipient, ids);
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
        require(info.token != address(0), "Erc721BackingUnsupportingConfirm:the token is not registered");
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
 
