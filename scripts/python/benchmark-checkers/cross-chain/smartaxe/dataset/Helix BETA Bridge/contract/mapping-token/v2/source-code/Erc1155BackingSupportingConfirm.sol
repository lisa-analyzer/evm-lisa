// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// This is the backing contract for Erc1155 token
// Before the new Erc1155 token registered, user should create a metadata contract on the target chain first
// the medata contract need support uri interface defined in IErc1155Metadata

import "@zeppelin-solidity/contracts/token/ERC1155/IERC1155.sol";
import "../Backing.sol";
import "../../interfaces/IErc1155Backing.sol";
import "../../interfaces/IErc1155MappingTokenFactory.sol";
import "../../interfaces/IHelixMessageEndpoint.sol";

contract Erc1155BackingSupportingConfirm is Backing, IErc1155Backing {
    struct LockedInfo {
        address token;
        address sender;
        uint256[] ids;
        uint256[] amounts;
    }

    struct TokenInfo {
        address token;
        address serializer;
    }

    // (messageId => tokenAddress)
    mapping(uint256 => address) public registerMessages;

    // tokenAddress => reistered
    mapping(address => bool) public registeredTokens;

    // (messageId => lockedInfo)
    mapping(uint256 => LockedInfo) public lockMessages;

    event NewErc1155TokenRegistered(uint256 messageId, address token);
    event TokenLocked(uint256 messageId, address token, address recipient, uint256[] ids, uint256[] amounts);
    event TokenLockFinished(uint256 messageId, bool result);
    event TokenRegisterFinished(uint256 messageId, bool result);
    event TokenUnlocked(address token, address recipient, uint256[] ids, uint256[] amounts);

    function setMessageEndpoint(address _messageEndpoint) external onlyAdmin {
        _setMessageEndpoint(_messageEndpoint);
    }

    /**
     * @notice reigister new erc1155 token to the bridge. Only owner can do this.
     * @param token the original token address
     * @param remoteMetadataAddress remote contract address to store metadata of the mapping token's attributes
     */
    function registerErc1155Token(
        address token,
        address remoteMetadataAddress
    ) external payable onlyOperator {
        require(!registeredTokens[token], "Erc1155Backing:token has been registered");
        bytes memory newErc1155Contract = abi.encodeWithSelector(
            IErc1155MappingTokenFactory.newErc1155Contract.selector,
            token,
            remoteMetadataAddress
        );
        uint256 messageId = IHelixMessageEndpoint(messageEndpoint).sendMessage{value: msg.value}(remoteMappingTokenFactory, newErc1155Contract);
        registerMessages[messageId] = token;
        emit NewErc1155TokenRegistered(messageId, token);
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
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external payable whenNotPaused {
        require(registeredTokens[token], "Erc1155Backing:the token is not registered");
        IERC1155(token).safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");

        bytes memory issueMappingToken = abi.encodeWithSelector(
            IErc1155MappingTokenFactory.issueMappingToken.selector,
            token,
            recipient,
            ids,
            amounts
        );
        uint256 messageId = IHelixMessageEndpoint(messageEndpoint).sendMessage{value: msg.value}(remoteMappingTokenFactory, issueMappingToken);
        lockMessages[messageId] = LockedInfo(token, msg.sender, ids, amounts);
        emit TokenLocked(messageId, token, recipient, ids, amounts);
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
                IERC1155(lockedInfo.token).safeBatchTransferFrom(address(this), lockedInfo.sender, lockedInfo.ids, lockedInfo.amounts, "");
            }
            emit TokenLockFinished(messageId, result);
            return;
        }
        address token = registerMessages[messageId];
        // it is register message, if result is true, need to save the token
        if (token != address(0)) {
            delete registerMessages[messageId];
            if (result) {
                registeredTokens[token] = true;
            }
            emit TokenRegisterFinished(messageId, result);
        }
    }

    /**
     * @notice this will be called by inboundLane when the remote mapping token burned and want to unlock the original token
     * @param token the original token address
     * @param recipient the recipient who will receive the unlocked token
     * @param ids ids of the unlocked token
     */
    function unlockFromRemote(
        address token,
        address recipient,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public onlyMessageEndpoint whenNotPaused {
        require(registeredTokens[token], "Erc1155Backing:the token is not registered");
        IERC1155(token).safeBatchTransferFrom(address(this), recipient, ids, amounts, "");
        emit TokenUnlocked(token, recipient, ids, amounts);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return Erc1155BackingSupportingConfirm.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return Erc1155BackingSupportingConfirm.onERC1155BatchReceived.selector;
    }

    /**
     * @notice this should not be used unless there is a non-recoverable error in the bridge or the target chain
     * we use this to protect user's asset from being locked up
     */
    function rescueFunds(
        address token,
        uint256 id,
        address recipient,
        uint256 amount
    ) external onlyAdmin {
        IERC1155(token).safeTransferFrom(address(this), recipient, id, amount, "");
    }
}
 
