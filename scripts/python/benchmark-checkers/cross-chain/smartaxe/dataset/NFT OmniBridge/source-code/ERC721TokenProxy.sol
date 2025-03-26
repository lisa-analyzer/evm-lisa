pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../../../upgradeability/Proxy.sol";
import "../../../../interfaces/IOwnable.sol";

/**
 * @title ERC721TokenProxy
 * @dev Helps to reduces the size of the deployed bytecode for automatically created tokens, by using a proxy contract.
 */
contract ERC721TokenProxy is Proxy {
    // storage layout is copied from ERC721BridgeToken.sol
    mapping(bytes4 => bool) private _supportedInterfaces;
    mapping(address => uint256) private _holderTokens;

    //EnumerableMap.UintToAddressMap private _tokenOwners;
    uint256[] private _tokenOwnersEntries;
    mapping(bytes32 => uint256) private _tokenOwnersIndexes;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private name;
    string private symbol;
    mapping(uint256 => string) private _tokenURIs;
    string private _baseURI;
    address private bridgeContract;

    /**
     * @dev Creates an upgradeable token proxy for ERC721BridgeToken.sol, initializes its eternalStorage.
     * @param _tokenImage address of the token image used for mirroring all functions.
     * @param _name token name.
     * @param _symbol token symbol.
     * @param _owner address of the owner for this contract.
     */
    constructor(
        address _tokenImage,
        string memory _name,
        string memory _symbol,
        address _owner
    ) {
        assembly {
            // EIP 1967
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _tokenImage)
        }
        name = _name;
        symbol = _symbol;
        bridgeContract = _owner; // _owner == HomeOmnibridgeNFT/ForeignOmnibridgeNFT mediator
    }

    /**
     * @dev Retrieves the implementation contract address, mirrored token image.
     * @return impl token image address.
     */
    function implementation() public view override returns (address impl) {
        assembly {
            impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
    }

    /**
     * @dev Updates the implementation contract address.
     * Only the bridge and bridge owner can call this method.
     * @param _implementation address of the new implementation.
     */
    function setImplementation(address _implementation) external {
        require(msg.sender == bridgeContract || msg.sender == IOwnable(bridgeContract).owner());
        require(_implementation != address(0));
        require(Address.isContract(_implementation));
        assembly {
            // EIP 1967
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _implementation)
        }
    }

    /**
     * @dev Tells the current version of the ERC721 token proxy interfaces.
     */
    function getTokenProxyInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }
}