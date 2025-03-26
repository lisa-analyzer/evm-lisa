pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IBurnableMintableERC1155Token.sol";

/**
 * @title ERC1155BridgeToken
 * @dev template token contract for bridged ERC1155 tokens.
 */
contract ERC1155BridgeToken is ERC1155, IBurnableMintableERC1155Token {
    string public name;
    string public symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private tokenURIs;
    // Base URI
    string private baseURI;

    address public bridgeContract;

    bool private hasAlreadyMinted;

    constructor(
        string memory _name,
        string memory _symbol,
        address _bridgeContract
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;
        bridgeContract = _bridgeContract;
    }

    /**
     * @dev Throws if sender is not a bridge contract.
     */
    modifier onlyBridge() {
        require(msg.sender == bridgeContract);
        _;
    }

    /**
     * @dev Throws if sender is not a bridge contract or bridge contract owner.
     */
    modifier onlyOwner() {
        require(msg.sender == bridgeContract || msg.sender == IOwnable(bridgeContract).owner());
        _;
    }

    /**
     * @dev Tells if this contract implements the interface defined by
     * `interfaceId`. See the corresponding EIP165.
     * @return true, if interface is implemented.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        bytes4 INTERFACE_ID_ERC165 = 0x01ffc9a7;
        bytes4 INTERFACE_ID_ERC1155 = 0xd9b67a26;
        bytes4 INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;
        return
            interfaceId == INTERFACE_ID_ERC165 ||
            interfaceId == INTERFACE_ID_ERC1155 ||
            interfaceId == INTERFACE_ID_ERC1155_METADATA_URI;
    }

    /**
     * @dev Stub for preventing unneeded storage writes.
     * All supported interfaces are hardcoded in the supportsInterface function.
     */
    function _registerInterface(bytes4) internal override {}

    /**
     * @dev Mint a batch of new ERC1155 tokens.
     * Only bridge contract is authorized to mint tokens.
     * @param _to address of the newly created token owner.
     * @param _tokenIds array of token ids to mint.
     * @param _values array of corresponding mint amounts for each tokenId.
     */
    function mint(
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) external override onlyBridge {
        if (_tokenIds.length == 1 && _values.length == 1) {
            _mint(_to, _tokenIds[0], _values[0], new bytes(0));
        } else {
            // Next few lines ensure that the first mint ever happened in his token contract will performed using TransferSingle event
            // Otherwise, NFT marketplaces have issues with indexing bridged token data.
            // On first mint ever (when hasAlreadyMinted is false), last token id from the list is minted using TransferSingle.
            // All over tokens from the list are minted using TransferBatch event.
            // All subsequent operations will always use TransferBatch for operations involving more than 1 token id.
            if (!hasAlreadyMinted) {
                require(_tokenIds.length > 1 && _tokenIds.length == _values.length);
                uint256 len = _tokenIds.length - 1;
                _mint(_to, _tokenIds[len], _values[len], new bytes(0));
                assembly {
                    mstore(_tokenIds, len) // _tokenIds.pop()
                    mstore(_values, len) // _values.pop()
                }
            }
            _mintBatch(_to, _tokenIds, _values, new bytes(0));
        }
        hasAlreadyMinted = true;
    }

    /**
     * @dev Burns a batch of ERC1155 tokens.
     * Only bridge contract is authorized to burn tokens.
     * @param _tokenIds array of token ids to burn.
     * @param _values array of corresponding burn amounts for each tokenId.
     */
    function burn(uint256[] memory _tokenIds, uint256[] memory _values) external override onlyBridge {
        _burnBatch(msg.sender, _tokenIds, _values);
    }

    /**
     * @dev Updates the bridge contract address.
     * Can be called by bridge owner after token contract was instantiated.
     * @param _bridgeContract address of the new bridge contract.
     */
    function setBridgeContract(address _bridgeContract) external onlyOwner {
        require(_bridgeContract != address(0));
        bridgeContract = _bridgeContract;
    }

    /**
     * @dev Sets the base URI for all tokens.
     * Can be called by bridge owner after token contract was instantiated.
     * @param _baseURI new base URI.
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @dev Sets the URI for the particular token.
     * Can be called by bridge owner after token bridging.
     * @param _tokenId URI for the bridged token metadata.
     * @param _tokenURI new token URI.
     */
    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external onlyOwner {
        tokenURIs[_tokenId] = _tokenURI;
    }

    /**
     * @dev Tells the metadata URI for the particular tokenId.
     * @param _tokenId unique token id for which to return metadata URI.
     * @return token metadata URI.
     */
    function uri(uint256 _tokenId) external view override returns (string memory) {
        string memory tokenURI = tokenURIs[_tokenId];
        string memory base = baseURI;

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        return string(abi.encodePacked(base, tokenURI));
    }

    /**
     * @dev Tells the current version of the ERC1155 token interfaces.
     */
    function getTokenInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 1, 0);
    }
}