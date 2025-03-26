pragma solidity 0.7.5;

import "../../../../libraries/Bytes.sol";

/**
 * @title BaseRelayer
 * @dev Basic functionality for relaying different NFT tokens to the other side of the bridge.
 */
abstract contract BaseRelayer {
    /**
     * @dev Helper function for alternative receiver feature. Chooses the actual receiver out of sender and passed data.
     * @param _from address of the token sender.
     * @param _data passed data in the transfer message.
     * @return recipient address of the receiver on the other side.
     */
    function _chooseReceiver(address _from, bytes memory _data) internal pure returns (address recipient) {
        recipient = _from;
        if (_data.length > 0) {
            require(_data.length == 20);
            recipient = Bytes.bytesToAddress(_data);
        }
    }

    /**
     * @dev Wraps a given uint256 value into an array with a single element.
     * @param _value argument to wrap.
     * @return wrapper array.
     */
    function _singletonArray(uint256 _value) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = _value;
        return array;
    }

    function bridgeSpecificActionsOnTokenTransfer(
        address _token,
        address _from,
        address _receiver,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal virtual;
}