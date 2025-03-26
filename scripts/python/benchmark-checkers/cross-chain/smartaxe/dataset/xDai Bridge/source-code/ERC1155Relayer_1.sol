pragma solidity 0.7.5;

import "../../../../interfaces/IERC1155TokenReceiver.sol";
import "./BaseRelayer.sol";

/**
 * @title ERC1155Relayer
 * @dev Functionality for bridging multiple ERC1155 tokens to the other side of the bridge.
 */
abstract contract ERC1155Relayer is IERC1155TokenReceiver, BaseRelayer {
    // max batch size, so that deployAndHandleBridgedNFT fits in 1.000.000 gas
    uint256 internal constant MAX_BATCH_BRIDGE_AND_DEPLOY_LIMIT = 14;
    // max batch size, so that handleBridgedNFT fits in 1.000.000 gas
    uint256 internal constant MAX_BATCH_BRIDGE_LIMIT = 19;

    /**
     * @dev ERC1155 transfer callback function.
     * @param _from address of token sender.
     * @param _tokenId id of the transferred token.
     * @param _value amount of received tokens.
     * @param _data additional transfer data, can be used for passing alternative receiver address.
     */
    function onERC1155Received(
        address,
        address _from,
        uint256 _tokenId,
        uint256 _value,
        bytes calldata _data
    ) external override returns (bytes4) {
        bridgeSpecificActionsOnTokenTransfer(
            msg.sender,
            _from,
            _chooseReceiver(_from, _data),
            _singletonArray(_tokenId),
            _singletonArray(_value)
        );
        return msg.sig;
    }

    /**
     * @dev ERC1155 transfer callback function.
     * @param _from address of token sender.
     * @param _tokenIds unique ids of the received tokens.
     * @param _values amounts of received tokens.
     * @param _data additional transfer data, can be used for passing alternative receiver address.
     */
    function onERC1155BatchReceived(
        address,
        address _from,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override returns (bytes4) {
        require(_tokenIds.length == _values.length);
        require(_tokenIds.length > 0);
        bridgeSpecificActionsOnTokenTransfer(msg.sender, _from, _chooseReceiver(_from, _data), _tokenIds, _values);
        return msg.sig;
    }
}