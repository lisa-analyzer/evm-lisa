// SPDX-License-Identifier: MIT
// This is the Erc1155 Token Issuing Module(Mapping-token-factory) of the ethereum like bridge.
// We trust the inboundLane/outboundLane when we add them to the module.
// It means that each message from the inboundLane is verified correct and truthly from the sourceAccount.
// Only we need is to verify that the sourceAccount is expected. And we add it to the Filter.

pragma solidity ^0.8.10;

import "./Erc1155MappingToken.sol";
import "../MappingTokenFactory.sol";
import "../../interfaces/IErc1155Backing.sol";
import "../../interfaces/IErc1155MappingToken.sol";
import "../../interfaces/IHelixMessageEndpoint.sol";

contract Erc1155MappingTokenFactorySupportingConfirm is MappingTokenFactory {
    struct UnconfirmedInfo {
        address sender;
        address mappingToken;
        uint256[] ids;
        uint256[] amounts;
    }
    mapping(uint256 => UnconfirmedInfo) public unlockRemoteUnconfirmed;

    event IssuingERC1155Created(address originalToken, address mappingToken);
    event BurnAndWaitingConfirm(uint256 messageId, address sender, address recipient, address token, uint256[] ids, uint256[] amounts);
    event RemoteUnlockConfirmed(uint256 messageId, bool result);

    function setMessageEndpoint(address _messageEndpoint) external onlyAdmin {
        _setMessageEndpoint(_messageEndpoint);
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

    /**
     * @notice create new erc1155 mapping contract, this can only be called by inboundLane
     * @param originalToken the original token address
     * @param metadataAddress the contract address of the metadata
     */
    function newErc1155Contract(
        address originalToken,
        address metadataAddress
    ) public onlyMessageEndpoint whenNotPaused returns (address mappingToken) {
        bytes32 salt = keccak256(abi.encodePacked(remoteBacking, originalToken));
        require(salt2MappingToken[salt] == address(0), "Erc1155MTFSupportingConfirm:contract has been deployed");
        bytes memory bytecode = type(Erc1155MappingToken).creationCode;
        bytes memory bytecodeWithInitdata = abi.encodePacked(bytecode, abi.encode(metadataAddress));
        mappingToken = _deploy(salt, bytecodeWithInitdata);
        _addMappingToken(salt, originalToken, mappingToken);
        emit IssuingERC1155Created(originalToken, mappingToken);
    }

    /**
     * @notice issue mapping token, only can be called by inboundLane
     * @param originalToken the original token address
     * @param recipient the recipient of the issued mapping token
     * @param ids the ids of the issued mapping tokens
     */
    function issueMappingToken(
        address originalToken,
        address recipient,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public onlyMessageEndpoint whenNotPaused {
        bytes32 salt = keccak256(abi.encodePacked(remoteBacking, originalToken));
        address mappingToken = salt2MappingToken[salt];
        require(mappingToken != address(0), "Erc1155MTFSupportingConfirm:mapping token has not created");
        require(ids.length > 0, "Erc1155MTFSupportingConfirm:can not receive empty ids");
        IErc1155MappingToken(mappingToken).mintBatch(recipient, ids, amounts);
    }

    /**
     * @notice burn mapping token and unlock remote original token, waiting for the confirm
     * @param mappingToken the burt mapping token address
     * @param recipient the recipient of the remote unlocked token
     * @param ids the ids of the burn and unlock
     */
    function burnAndRemoteUnlockWaitingConfirm(
        address mappingToken,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external payable whenNotPaused {
        require(ids.length > 0, "Erc1155MTFSupportingConfirm:can not transfer empty id");
        address originalToken = mappingToken2OriginalToken[mappingToken];
        require(originalToken != address(0), "Erc1155MTFSupportingConfirm:token is not created by factory");
        // Lock the fund in this before message on remote backing chain get dispatched successfully and burn finally
        // If remote backing chain unlock the origin token successfully, then this fund will be burned.
        // Otherwise, these tokens will be transfered back to the msg.sender.
        IERC1155(mappingToken).safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");

        bytes memory unlockFromRemote = abi.encodeWithSelector(
            IErc1155Backing.unlockFromRemote.selector,
            originalToken,
            recipient,
            ids,
            amounts
        );
        uint256 messageId = IHelixMessageEndpoint(messageEndpoint).sendMessage{value: msg.value}(remoteBacking, unlockFromRemote);
        unlockRemoteUnconfirmed[messageId] = UnconfirmedInfo(msg.sender, mappingToken, ids, amounts);
        emit BurnAndWaitingConfirm(messageId, msg.sender, recipient, mappingToken, ids, amounts);
    }

    /**
     * @notice this will be called when the burn and unlock from remote message confirmed
     * @param messageId the message id, is used to identify the unlocked message
     * @param result the result of the remote backing's unlock, if false, the mapping token need to transfer back to the user, otherwise burt
     */
    function onMessageDelivered(
        uint256 messageId,
        bool result
    ) external onlyMessageEndpoint {
        UnconfirmedInfo memory info = unlockRemoteUnconfirmed[messageId];
        require(info.ids.length > 0 && info.sender != address(0) && info.mappingToken != address(0), "Erc1155MTFSupportingConfirm:invalid unconfirmed message");
        if (result) {
            IErc1155MappingToken(info.mappingToken).burnBatch(info.ids, info.amounts);
        } else {
            IERC1155(info.mappingToken).safeBatchTransferFrom(address(this), info.sender, info.ids, info.amounts, "");
        }
        delete unlockRemoteUnconfirmed[messageId];
        emit RemoteUnlockConfirmed(messageId, result);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return Erc1155MappingTokenFactorySupportingConfirm.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return Erc1155MappingTokenFactorySupportingConfirm.onERC1155BatchReceived.selector;
    }
}

