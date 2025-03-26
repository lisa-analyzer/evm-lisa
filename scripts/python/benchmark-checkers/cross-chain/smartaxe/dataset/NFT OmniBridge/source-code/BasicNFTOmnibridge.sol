pragma solidity 0.7.5;
// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "../Initializable.sol";
import "../Upgradeable.sol";
import "../../interfaces/IBurnableMintableERC1155Token.sol";
import "./components/common/BridgeOperationsStorage.sol";
import "./components/common/FailedMessagesProcessor.sol";
import "./components/common/NFTBridgeLimits.sol";
import "./components/common/ERC721Relayer.sol";
import "./components/common/ERC1155Relayer.sol";
import "./components/common/NFTOmnibridgeInfo.sol";
import "./components/native/NativeTokensRegistry.sol";
import "./components/native/MetadataReader.sol";
import "./components/bridged/BridgedTokensRegistry.sol";
import "./components/bridged/TokenImageStorage.sol";
import "./components/bridged/ERC721TokenProxy.sol";
import "./components/bridged/ERC1155TokenProxy.sol";
import "./components/native/NFTMediatorBalanceStorage.sol";
import "../../tokens/ERC721BridgeToken.sol";

/**
 * @title BasicNFTOmnibridge
 * @dev Commong functionality for multi-token mediator for ERC721 tokens intended to work on top of AMB bridge.
 */
abstract contract BasicNFTOmnibridge is
    Initializable,
    Upgradeable,
    BridgeOperationsStorage,
    BridgedTokensRegistry,
    NativeTokensRegistry,
    NFTOmnibridgeInfo,
    NFTBridgeLimits,
    MetadataReader,
    TokenImageStorage,
    ERC721Relayer,
    ERC1155Relayer,
    NFTMediatorBalanceStorage,
    FailedMessagesProcessor
{
    using SafeMath for uint256;

    // Workaround for storing variable up-to-32 bytes suffix
    uint256 private immutable SUFFIX_SIZE;
    bytes32 private immutable SUFFIX;

    // Since contract is intended to be deployed under EternalStorageProxy, only constant and immutable variables can be set here
    constructor(string memory _suffix) {
        require(bytes(_suffix).length <= 32);
        bytes32 suffix;
        assembly {
            suffix := mload(add(_suffix, 32))
        }
        SUFFIX = suffix;
        SUFFIX_SIZE = bytes(_suffix).length;
    }

    /**
     * @dev Checks if specified token was already bridged at least once and it is registered in the Omnibridge.
     * @param _token address of the token contract.
     * @return true, if token was already bridged.
     */
    function isTokenRegistered(address _token) public view override returns (bool) {
        return isRegisteredAsNativeToken(_token) || nativeTokenAddress(_token) != address(0);
    }

    /**
     * @dev Handles the bridged token for the first time, includes deployment of new ERC721TokenProxy contract.
     * @param _token address of the native ERC721 token on the other side.
     * @param _name name of the native token, name suffix will be appended, if empty, symbol will be used instead.
     * @param _symbol symbol of the bridged token, if empty, name will be used instead.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     * @param _tokenURIs URIs for the bridged token instances.
     */
    function deployAndHandleBridgedNFT(
        address _token,
        string memory _name,
        string memory _symbol,
        address _recipient,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values,
        string[] calldata _tokenURIs
    ) external onlyMediator {
        address bridgedToken = bridgedTokenAddress(_token);
        if (bridgedToken == address(0)) {
            if (bytes(_name).length == 0) {
                if (bytes(_symbol).length > 0) {
                    _name = _transformName(_symbol);
                }
            } else {
                if (bytes(_symbol).length == 0) {
                    _symbol = _name;
                }
                _name = _transformName(_name);
            }
            bridgedToken = _values.length > 0
                ? address(new ERC1155TokenProxy(tokenImageERC1155(), _name, _symbol, address(this)))
                : address(new ERC721TokenProxy(tokenImageERC721(), _name, _symbol, address(this)));
            _setTokenAddressPair(_token, bridgedToken);
        }

        _handleTokens(bridgedToken, false, _recipient, _tokenIds, _values);
        _setTokensURI(bridgedToken, _tokenIds, _tokenURIs);
    }

    /**
     * @dev Handles the bridged token for the already registered token pair.
     * Checks that the bridged token is inside the execution limits and invokes the Mint accordingly.
     * @param _token address of the native ERC721 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     * @param _tokenURIs URIs for the bridged token instances.
     */
    function handleBridgedNFT(
        address _token,
        address _recipient,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values,
        string[] calldata _tokenURIs
    ) external onlyMediator {
        address token = bridgedTokenAddress(_token);

        _handleTokens(token, false, _recipient, _tokenIds, _values);
        _setTokensURI(token, _tokenIds, _tokenURIs);
    }

    /**
     * @dev Handles the bridged token that are native to this chain.
     * Checks that the bridged token is inside the execution limits and invokes the Unlock accordingly.
     * @param _token address of the native ERC721 token contract.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function handleNativeNFT(
        address _token,
        address _recipient,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values
    ) external onlyMediator {
        require(isRegisteredAsNativeToken(_token));

        _setNativeTokenIsRegistered(_token, REGISTERED_AND_DEPLOYED);

        _handleTokens(_token, true, _recipient, _tokenIds, _values);
    }

    /**
     * @dev Allows to pre-set the bridged token contract for not-yet bridged token.
     * Only the owner can call this method.
     * @param _nativeToken address of the token contract on the other side that was not yet bridged.
     * @param _bridgedToken address of the bridged token contract.
     */
    function setCustomTokenAddressPair(address _nativeToken, address _bridgedToken) external onlyOwner {
        require(Address.isContract(_bridgedToken));
        require(!isTokenRegistered(_bridgedToken));
        require(bridgedTokenAddress(_nativeToken) == address(0));
        // Unfortunately, there is no simple way to verify that the _nativeToken address
        // does not belong to the bridged token on the other side,
        // since information about bridged tokens addresses is not transferred back.
        // Therefore, owner account calling this function SHOULD manually verify on the other side of the bridge that
        // nativeTokenAddress(_nativeToken) == address(0) && isTokenRegistered(_nativeToken) == false.

        _setTokenAddressPair(_nativeToken, _bridgedToken);
    }

    /**
     * @dev Allows to send to the other network some ERC721 token that can be forced into the contract
     * without the invocation of the required methods. (e. g. regular transferFrom without a call to onERC721Received)
     * Before calling this method, it must be carefully investigated how imbalance happened
     * in order to avoid an attempt to steal the funds from a token with double addresses.
     * @param _token address of the token contract.
     * @param _receiver the address that will receive the token on the other network.
     * @param _tokenIds unique ids of the bridged tokens.
     */
    function fixMediatorBalanceERC721(
        address _token,
        address _receiver,
        uint256[] calldata _tokenIds
    ) external onlyIfUpgradeabilityOwner {
        require(isRegisteredAsNativeToken(_token));
        require(_tokenIds.length > 0);

        uint256[] memory values = new uint256[](0);

        bytes memory data = _prepareMessage(_token, _receiver, _tokenIds, values);
        bytes32 _messageId = _passMessage(data, true);
        _recordBridgeOperation(_messageId, _token, _receiver, _tokenIds, values);
    }

    /**
     * @dev Allows to send to the other network some ERC1155 token that can be forced into the contract
     * without the invocation of the required methods.
     * Before calling this method, it must be carefully investigated how imbalance happened
     * in order to avoid an attempt to steal the funds from a token with double addresses.
     * @param _token address of the token contract.
     * @param _receiver the address that will receive the token on the other network.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values corresponding amounts of the bridged tokens.
     */
    function fixMediatorBalanceERC1155(
        address _token,
        address _receiver,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values
    ) external onlyIfUpgradeabilityOwner {
        require(isRegisteredAsNativeToken(_token));
        require(_tokenIds.length == _values.length);
        require(_tokenIds.length > 0);

        bytes memory data = _prepareMessage(_token, _receiver, _tokenIds, _values);
        bytes32 _messageId = _passMessage(data, true);
        _recordBridgeOperation(_messageId, _token, _receiver, _tokenIds, _values);
    }

    /**
     * @dev Executes action on deposit of ERC721 token.
     * @param _token address of the ERC721 token contract.
     * @param _from address of token sender.
     * @param _receiver address of token receiver on the other side.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function bridgeSpecificActionsOnTokenTransfer(
        address _token,
        address _from,
        address _receiver,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal override {
        if (!isTokenRegistered(_token)) {
            _setNativeTokenIsRegistered(_token, REGISTERED);
        }

        bytes memory data = _prepareMessage(_token, _receiver, _tokenIds, _values);

        bytes32 _messageId = _passMessage(data, _isOracleDrivenLaneAllowed(_token, _from, _receiver));

        _recordBridgeOperation(_messageId, _token, _from, _tokenIds, _values);
    }

    /**
     * @dev Constructs the message to be sent to the other side. Burns/locks bridged token.
     * @param _token bridged token address.
     * @param _receiver address of the tokens receiver on the other side.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function _prepareMessage(
        address _token,
        address _receiver,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal returns (bytes memory) {
        require(_receiver != address(0) && _receiver != mediatorContractOnOtherSide());

        address nativeToken = nativeTokenAddress(_token);

        // process token is native with respect to this side of the bridge
        if (nativeToken == address(0)) {
            string[] memory tokenURIs = new string[](_tokenIds.length);

            if (_values.length > 0) {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    uint256 oldBalance = mediatorOwns(_token, _tokenIds[i]);
                    uint256 newBalance = oldBalance.add(_values[i]);
                    require(IERC1155(_token).balanceOf(address(this), _tokenIds[i]) >= newBalance);
                    _setMediatorOwns(_token, _tokenIds[i], newBalance);
                    tokenURIs[i] = _readERC1155TokenURI(_token, _tokenIds[i]);
                }
            } else {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    require(mediatorOwns(_token, _tokenIds[i]) == 0);
                    require(IERC721(_token).ownerOf(_tokenIds[i]) == address(this));
                    _setMediatorOwns(_token, _tokenIds[i], 1);
                    tokenURIs[i] = _readERC721TokenURI(_token, _tokenIds[i]);
                }
            }

            // process token which bridged alternative was already ACKed to be deployed
            if (isBridgedTokenDeployAcknowledged(_token)) {
                require(_tokenIds.length <= MAX_BATCH_BRIDGE_LIMIT);
                return
                    abi.encodeWithSelector(
                        this.handleBridgedNFT.selector,
                        _token,
                        _receiver,
                        _tokenIds,
                        _values,
                        tokenURIs
                    );
            }

            require(_tokenIds.length <= MAX_BATCH_BRIDGE_AND_DEPLOY_LIMIT);

            string memory name = _readName(_token);
            string memory symbol = _readSymbol(_token);

            return
                abi.encodeWithSelector(
                    this.deployAndHandleBridgedNFT.selector,
                    _token,
                    name,
                    symbol,
                    _receiver,
                    _tokenIds,
                    _values,
                    tokenURIs
                );
        }

        // process already known token that is bridged from other chain
        if (_values.length > 0) {
            IBurnableMintableERC1155Token(_token).burn(_tokenIds, _values);
        } else {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                IBurnableMintableERC721Token(_token).burn(_tokenIds[i]);
            }
        }
        return abi.encodeWithSelector(this.handleNativeNFT.selector, nativeToken, _receiver, _tokenIds, _values);
    }

    /**
     * @dev Unlock/Mint back the bridged token that was bridged to the other network but failed.
     * @param _token address that bridged token contract.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function executeActionOnFixedTokens(
        address _token,
        address _recipient,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal override {
        _releaseTokens(_token, nativeTokenAddress(_token) == address(0), _recipient, _tokenIds, _values);
    }

    /**
     * @dev Handles the bridged token that came from the other side of the bridge.
     * Checks that the operation is inside the execution limits and invokes the Mint or Unlock accordingly.
     * @param _token token contract address on this side of the bridge.
     * @param _isNative true, if given token is native to this chain and Unlock should be used.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function _handleTokens(
        address _token,
        bool _isNative,
        address _recipient,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values
    ) internal {
        require(isTokenExecutionAllowed(_token));

        _releaseTokens(_token, _isNative, _recipient, _tokenIds, _values);

        emit TokensBridged(_token, _recipient, _tokenIds, _values, messageId());
    }

    /**
     * Internal function for setting token URI for the bridged token instance.
     * @param _token address of the token contract.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _tokenURIs URIs for the bridged token instances.
     */
    function _setTokensURI(
        address _token,
        uint256[] calldata _tokenIds,
        string[] calldata _tokenURIs
    ) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (bytes(_tokenURIs[i]).length > 0) {
                IBurnableMintableERC721Token(_token).setTokenURI(_tokenIds[i], _tokenURIs[i]);
            }
        }
    }

    /**
     * Internal function for unlocking/minting some specific ERC721 token.
     * @param _token address of the token contract.
     * @param _isNative true, if the token contract is native w.r.t to the bridge.
     * @param _recipient address of the tokens receiver.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function _releaseTokens(
        address _token,
        bool _isNative,
        address _recipient,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal {
        if (_values.length > 0) {
            if (_isNative) {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    _setMediatorOwns(_token, _tokenIds[i], mediatorOwns(_token, _tokenIds[i]).sub(_values[i]));
                }
                IERC1155(_token).safeBatchTransferFrom(address(this), _recipient, _tokenIds, _values, new bytes(0));
            } else {
                IBurnableMintableERC1155Token(_token).mint(_recipient, _tokenIds, _values);
            }
        } else {
            if (_isNative) {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    _setMediatorOwns(_token, _tokenIds[i], 0);
                    IERC721(_token).transferFrom(address(this), _recipient, _tokenIds[i]);
                }
            } else {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    IBurnableMintableERC721Token(_token).mint(_recipient, _tokenIds[i]);
                }
            }
        }
    }

    /**
     * @dev Internal function for recording bridge operation for further usage.
     * Recorded information is used for fixing failed requests on the other side.
     * @param _messageId id of the sent message.
     * @param _token bridged token address.
     * @param _sender address of the tokens sender.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function _recordBridgeOperation(
        bytes32 _messageId,
        address _token,
        address _sender,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal {
        require(isTokenBridgingAllowed(_token));

        setMessageChecksum(_messageId, _messageChecksum(_token, _sender, _tokenIds, _values));

        emit TokensBridgingInitiated(_token, _sender, _tokenIds, _values, _messageId);
    }

    /**
     * @dev Checks if bridge operation is allowed to use oracle driven lane.
     * @param _token address of the token contract on the foreign side of the bridge.
     * @param _sender address of the tokens sender on the home side of the bridge.
     * @param _receiver address of the tokens receiver on the foreign side of the bridge.
     * @return true, if message can be forwarded to the oracle-driven lane.
     */
    function _isOracleDrivenLaneAllowed(
        address _token,
        address _sender,
        address _receiver
    ) internal view virtual returns (bool) {
        (_token, _sender, _receiver);
        return true;
    }

    /**
     * @dev Internal function for transforming the bridged token name. Appends a side-specific suffix.
     * @param _name bridged token from the other side.
     * @return token name for this side of the bridge.
     */
    function _transformName(string memory _name) internal view returns (string memory) {
        string memory result = string(abi.encodePacked(_name, SUFFIX));
        uint256 size = SUFFIX_SIZE;
        assembly {
            mstore(result, add(mload(_name), size))
        }
        return result;
    }
}