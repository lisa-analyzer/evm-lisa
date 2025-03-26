pragma solidity 0.7.5;

import "../../../BasicAMBMediator.sol";
import "./BridgeOperationsStorage.sol";

/**
 * @title FailedMessagesProcessor
 * @dev Functionality for fixing failed bridging operations.
 */
abstract contract FailedMessagesProcessor is BasicAMBMediator, BridgeOperationsStorage {
    event FailedMessageFixed(bytes32 indexed messageId, address token);

    /**
     * @dev Method to be called when a bridged message execution failed. It will generate a new message requesting to
     * fix/roll back the transferred assets on the other network.
     * It is important to specify parameters very carefully.
     * Please, take exact values from the TokensBridgingInitiated event. Otherwise, execution will revert.
     * @param _messageId id of the message which execution failed.
     * @param _token address of the bridged token on the other side of the bridge.
     * @param _sender address of the tokens sender on the other side.
     * @param _tokenIds ids of the sent tokens.
     * @param _values amounts of tokens sent.
     */
    function requestFailedMessageFix(
        bytes32 _messageId,
        address _token,
        address _sender,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values
    ) external {
        require(_tokenIds.length > 0);
        require(_values.length == 0 || _tokenIds.length == _values.length);

        IAMB bridge = bridgeContract();
        require(!bridge.messageCallStatus(_messageId));
        require(bridge.failedMessageReceiver(_messageId) == address(this));
        require(bridge.failedMessageSender(_messageId) == mediatorContractOnOtherSide());

        bytes memory data =
            abi.encodeWithSelector(this.fixFailedMessage.selector, _messageId, _token, _sender, _tokenIds, _values);
        _passMessage(data, false);
    }

    /**
     * @dev Handles the request to fix transferred assets which bridged message execution failed on the other network.
     * Compares the reconstructed message checksum with the original one. Revert if message params were altered.
     * @param _messageId id of the message which execution failed on this side of the bridge.
     * @param _token address of the bridged token on this side of the bridge.
     * @param _sender address of the tokens sender on this side of the bridge.
     * @param _tokenIds ids of the sent tokens.
     * @param _values amounts of tokens sent.
     */
    function fixFailedMessage(
        bytes32 _messageId,
        address _token,
        address _sender,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) public onlyMediator {
        require(!messageFixed(_messageId));
        require(getMessageChecksum(_messageId) == _messageChecksum(_token, _sender, _tokenIds, _values));

        setMessageFixed(_messageId);
        executeActionOnFixedTokens(_token, _sender, _tokenIds, _values);
        emit FailedMessageFixed(_messageId, _token);
    }

    /**
     * @dev Tells if a message sent to the AMB bridge has been fixed.
     * @return bool indicating the status of the message.
     */
    function messageFixed(bytes32 _messageId) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("messageFixed", _messageId))];
    }

    /**
     * @dev Sets that the message sent to the AMB bridge has been fixed.
     * @param _messageId of the message sent to the bridge.
     */
    function setMessageFixed(bytes32 _messageId) internal {
        boolStorage[keccak256(abi.encodePacked("messageFixed", _messageId))] = true;
    }

    function executeActionOnFixedTokens(
        address _token,
        address _recipient,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal virtual;
}