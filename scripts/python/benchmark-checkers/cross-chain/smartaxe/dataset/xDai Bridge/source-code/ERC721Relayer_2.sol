pragma solidity 0.7.5;

import "../../../../interfaces/IBurnableMintableERC721Token.sol";
import "../../../ReentrancyGuard.sol";
import "./BaseRelayer.sol";

/**
 * @title ERC721Relayer
 * @dev Functionality for bridging multiple ERC721 tokens to the other side of the bridge.
 */
abstract contract ERC721Relayer is BaseRelayer, ReentrancyGuard {
    /**
     * @dev ERC721 transfer callback function.
     * @param _from address of token sender.
     * @param _tokenId id of the transferred token.
     * @param _data additional transfer data, can be used for passing alternative receiver address.
     */
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        if (!lock()) {
            bridgeSpecificActionsOnTokenTransfer(
                msg.sender,
                _from,
                _chooseReceiver(_from, _data),
                _singletonArray(_tokenId),
                new uint256[](0)
            );
        }
        return msg.sig;
    }

    /**
     * @dev Initiate the bridge operation for some token from msg.sender.
     * The user should first call Approve method of the ERC721 token.
     * @param token bridged token contract address.
     * @param _receiver address that will receive the token on the other network.
     * @param _tokenId id of the token to be transferred to the other network.
     */
    function relayToken(
        IERC721 token,
        address _receiver,
        uint256 _tokenId
    ) external {
        _relayToken(token, _receiver, _tokenId);
    }

    /**
     * @dev Initiate the bridge operation for some token from msg.sender to msg.sender on the other side.
     * The user should first call Approve method of the ERC721 token.
     * @param token bridged token contract address.
     * @param _tokenId id of token to be transferred to the other network.
     */
    function relayToken(IERC721 token, uint256 _tokenId) external {
        _relayToken(token, msg.sender, _tokenId);
    }

    /**
     * @dev Validates that the token amount is inside the limits, calls transferFrom to transfer the token to the contract
     * and invokes the method to burn/lock the token and unlock/mint the token on the other network.
     * The user should first call Approve method of the ERC721 token.
     * @param _token bridge token contract address.
     * @param _receiver address that will receive the token on the other network.
     * @param _tokenId id of the token to be transferred to the other network.
     */
    function _relayToken(
        IERC721 _token,
        address _receiver,
        uint256 _tokenId
    ) internal {
        // This lock is to prevent calling bridgeSpecificActionsOnTokenTransfer twice.
        // When transferFrom is called, after the transfer, the ERC721 token might call onERC721Received from this contract
        // which will call bridgeSpecificActionsOnTokenTransfer.
        require(!lock());

        setLock(true);
        _token.transferFrom(msg.sender, address(this), _tokenId);
        setLock(false);
        bridgeSpecificActionsOnTokenTransfer(
            address(_token),
            msg.sender,
            _receiver,
            _singletonArray(_tokenId),
            new uint256[](0)
        );
    }
}