// SPDX-License-Identifier: MIT
// This is the Issuing Module(Mapping-token-factory) of the ethereum like bridge.
// We trust the inboundLane/outboundLane when we add them to the module.
// It means that each message from the inboundLane is verified correct and truthly from the sourceAccount.
// Only we need is to verify the sourceAccount is expected. And we add it to the Filter.

pragma solidity ^0.8.10;

import "./Erc721MappingToken.sol";
import "../MappingTokenFactory.sol";
import "../../interfaces/IErc721AttrSerializer.sol";
import "../../interfaces/IErc721Backing.sol";
import "../../interfaces/IErc721MappingToken.sol";
import "../../interfaces/IHelixMessageEndpoint.sol";

contract Erc721MappingTokenFactoryUnsupportingConfirm is MappingTokenFactory {
    event IssuingERC721Created(address originalToken, address mappingToken);
    event BurnAndRemoteUnlock(address sender, address recipient, address token, uint256[] ids);

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
     * @notice create new erc721 mapping contract, this can only be called by inboundLane
     * @param originalToken the original token address
     * @param attrSerializer the serializer address of the attributes
     */
    function newErc721Contract(
        address originalToken,
        address attrSerializer
    ) public onlyMessageEndpoint whenNotPaused returns (address mappingToken) {
        bytes32 salt = keccak256(abi.encodePacked(remoteBacking, originalToken));
        require(salt2MappingToken[salt] == address(0), "Erc721MTFUnsupportingConfirm:contract has been deployed");
        bytes memory bytecode = type(Erc721MappingToken).creationCode;
        bytes memory bytecodeWithInitdata = abi.encodePacked(bytecode, abi.encode(attrSerializer));
        mappingToken = _deploy(salt, bytecodeWithInitdata);
        _addMappingToken(salt, originalToken, mappingToken);
        emit IssuingERC721Created(originalToken, mappingToken);
    }

    /**
     * @notice issue mapping token, only can be called by inboundLane
     * @param originalToken the original token address
     * @param recipient the recipient of the issued mapping token
     * @param ids the ids of the issued mapping tokens
     * @param attrs the serialized data of the original token's attributes
     */
    function issueMappingToken(
        address originalToken,
        address recipient,
        uint256[] calldata ids,
        bytes[] calldata attrs
    ) public onlyMessageEndpoint whenNotPaused {
        address mappingToken = getMappingToken(remoteBacking, originalToken);
        require(mappingToken != address(0), "Erc721MTFUnsupportingConfirm:mapping token has not created");
        require(ids.length > 0, "Erc721MTFUnsupportingConfirm:can not receive empty ids");
        address serializer = IErc721MappingToken(mappingToken).attributeSerializer();
        for (uint idx = 0; idx < ids.length; idx++) {
            IErc721MappingToken(mappingToken).mint(recipient, ids[idx]);
            if (serializer != address(0)) {
                IErc721AttrSerializer(serializer).deserialize(ids[idx], attrs[idx]);
            }
        }
    }

    /**
     * @notice burn mapping token and unlock remote original token, waiting for the confirm
     * @param mappingToken the burt mapping token address
     * @param recipient the recipient of the remote unlocked token
     * @param ids the ids of the burn and unlock
     */
    function burnAndRemoteUnlock(
        address mappingToken,
        address recipient,
        uint256[] memory ids 
    ) external payable whenNotPaused {
        require(ids.length > 0, "Erc721MTFUnsupportingConfirm:can not transfer empty id");
        address originalToken = mappingToken2OriginalToken[mappingToken];
        require(originalToken != address(0), "Erc721MTFUnsupportingConfirm:token is not created by factory");
        // Lock the fund in this before message on remote backing chain get dispatched successfully and burn finally
        // If remote backing chain unlock the origin token successfully, then this fund will be burned.
        // Otherwise, these tokens will be transfered back to the msg.sender.
        bytes[] memory attrs = new bytes[](ids.length);
        address serializer = IErc721MappingToken(mappingToken).attributeSerializer();
        for (uint256 idx = 0; idx < ids.length; idx++) {
            IERC721(mappingToken).transferFrom(msg.sender, address(this), ids[idx]);
            IErc721MappingToken(mappingToken).burn(ids[idx]);
            if (serializer != address(0)) {
                attrs[idx] = IErc721AttrSerializer(serializer).serialize(ids[idx]);
            }
        }

        bytes memory unlockFromRemote = abi.encodeWithSelector(
            IErc721Backing.unlockFromRemote.selector,
            originalToken,
            recipient,
            ids,
            attrs
        );
        IHelixMessageEndpoint(messageEndpoint).sendMessage{value: msg.value}(remoteBacking, unlockFromRemote);
        emit BurnAndRemoteUnlock(msg.sender, recipient, mappingToken, ids);
    }
}

