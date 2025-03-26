// SPDX-License-Identifier: MIT
// This is the Issuing Module(Mapping-token-factory) of the ethereum like bridge.
// We trust the inboundLane/outboundLane when we add them to the module.
// It means that each message from the inboundLane is verified correct and truthly from the sourceAccount.
// Only we need is to verify the sourceAccount is expected. And we add it to the Filter.
pragma solidity ^0.8.10;

import "@zeppelin-solidity/contracts/access/Ownable.sol";
import "@zeppelin-solidity/contracts/proxy/utils/Initializable.sol";
import "./AccessController.sol";

contract MappingTokenFactory is AccessController, Initializable {
    address[] public allMappingTokens;
    // salt=>mappingToken, the salt is derived from origin token on backing chain
    // so this is a mapping from origin to mapping token
    mapping(bytes32 => address) public salt2MappingToken;
    // mappingToken=>info the info is the original token info
    // so this is a mapping from mappingToken to original token
    mapping(address => address) public mappingToken2OriginalToken;

    address public messageEndpoint;
    address public remoteBacking;

    uint256 internal locked;
    modifier nonReentrant {
        require(locked == 0, "MappingTokenFactory: locked");
        locked = 1;
        _;
        locked = 0;
    }

    modifier onlyMessageEndpoint() {
        require(messageEndpoint == msg.sender, "MappingTokenFactory:Bad message handle");
        _;
    }

    function initialize(address _messageEndpoint) public initializer {
        _setMessageEndpoint(_messageEndpoint);
        _initialize(msg.sender);
    }

    function _setMessageEndpoint(address _messageEndpoint) internal {
        messageEndpoint = _messageEndpoint;
    }

    function setRemoteBacking(address _remoteBacking) external onlyAdmin {
        remoteBacking = _remoteBacking;
    }

    function _transferMappingTokenOwnership(address mappingToken, address new_owner) internal {
        Ownable(mappingToken).transferOwnership(new_owner);
    }

    /**
     * @notice add mapping-token address by owner
     * @param salt the salt of the mapping token deployed
     * @param originalToken the original token address
     * @param mappingToken the mapping token address
     */
    function _addMappingToken(
        bytes32 salt,
        address originalToken,
        address mappingToken
    ) internal {
        // save the mapping tokens in an array so it can be listed
        allMappingTokens.push(mappingToken);
        // map the originToken to mappingInfo
        salt2MappingToken[salt] = mappingToken;
        // map the mappingToken to origin info
        mappingToken2OriginalToken[mappingToken] = originalToken;
    }

    // internal
    function _deploy(bytes32 salt, bytes memory bytecodeWithInitdata) internal returns (address addr) {
        assembly {
            addr := create2(0, add(bytecodeWithInitdata, 0x20), mload(bytecodeWithInitdata), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function tokenLength() public view returns (uint) {
        return allMappingTokens.length;
    }

    function getMappingToken(address backingAddress, address originalToken) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(backingAddress, originalToken));
        return salt2MappingToken[salt];
    }
}

