// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Libraries/LibBytes.sol";
import "../Libraries/LibUtil.sol";
import "../Libraries/LibDiamond.sol";

interface Home {
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes memory _messageBody
    ) external;
}

/// @notice Cross-chain messaging router implemented using Optics Protocol (https://docs.celo.org/celo-codebase/protocol/optics).
/// @author Li.Finance (https://li.finance)
contract OpticsRouterFacet {
    using LibBytes for bytes;

    /* ========== Storage ========== */

    bytes32 internal constant NAMESPACE = keccak256("com.lifi.facets.optics.router");
    struct Storage {
        /// @dev Routes mapped by domain
        mapping(uint32 => Home) routes;
        /// @dev Approved routers by domain
        mapping(uint32 => bytes32) routers;
    }

    /* ========== Events ========== */

    event RemoteCall(uint32 domain, address indexed callee, address sender);
    event LocalCall(uint32 origin, address indexed callee, address home);

    /* ========== Errors ========== */

    error Unauthorized();
    error NoRemoteRouter();
    error CallError(string reason);

    /* ========== Public Router Functions ========== */

    function remoteCall(
        uint32 domain,
        address callee,
        bytes calldata callData
    ) external {
        Storage storage s = getStorage();
        if (s.routers[domain] == bytes32(0)) revert NoRemoteRouter();
        s.routes[domain].dispatch(domain, s.routers[domain], abi.encodePacked(callee, callData));

        emit RemoteCall(domain, callee, address(s.routes[domain]));
    }

    function handle(
        uint32 origin,
        bytes32 sender,
        bytes memory message
    ) public {
        Storage storage s = getStorage();
        if (s.routers[origin] != sender) revert Unauthorized();

        // The first 20 bytes of the message are the callee address
        address callee = message.toAddress(0);
        // The remaining bytes should be calldata
        bytes memory callData = message.slice(20, message.length - 20);

        // Don't allow any funny business
        if (callee == address(this)) revert Unauthorized();

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory res) = callee.call(callData);
        if (!success) {
            string memory reason = LibUtil.getRevertMsg(res);
            revert CallError(reason);
        }
        emit LocalCall(origin, callee, address(uint160(uint256(sender))));
    }

    // Nomad Implementation Version
    function handle(
        uint32 origin,
        uint32, // nonce
        bytes32 sender,
        bytes memory message
    ) external {
        handle(origin, sender, message);
    }

    /// @notice Register the address of a Router contract on a remote chain
    /// @param domain The domain of the remote xApp Router
    /// @param router The address of the remote xApp Router
    function enrollRemoteRouter(uint32 domain, address router) external {
        LibDiamond.enforceIsContractOwner();
        Storage storage s = getStorage();
        s.routers[domain] = bytes32(uint256(uint160(router)));
    }

    /// @notice Batch registers the addresses of Router contracts on a remote chain
    /// @param domains The domain of the remote xApp Router
    /// @param routers The address of the remote xApp Router
    function batchEnrollRemoteRouters(uint32[] calldata domains, address[] calldata routers) external {
        LibDiamond.enforceIsContractOwner();
        Storage storage s = getStorage();
        for (uint8 i = 0; i < domains.length; i++) {
            s.routers[domains[i]] = bytes32(uint256(uint160(routers[i])));
        }
    }

    /// @notice Set a home address for a specific domain
    /// @param domain The domain of the remote xApp Router
    /// @param home The address of the remote xApp Router
    function setRoute(uint32 domain, Home home) external {
        LibDiamond.enforceIsContractOwner();
        Storage storage s = getStorage();
        s.routes[domain] = home;
    }

    /// @notice Batch sets the home addresses of specific domains
    /// @param domains The domain of the remote xApp Router
    /// @param homes The address of the remote xApp Router
    function batchSetRoutes(uint32[] calldata domains, Home[] calldata homes) external {
        LibDiamond.enforceIsContractOwner();
        Storage storage s = getStorage();
        for (uint8 i = 0; i < domains.length; i++) {
            s.routes[domains[i]] = homes[i];
        }
    }

    /* ========== Getters ========== */

    function routeByDomain(uint32 domain) external view returns (address) {
        return address(getStorage().routes[domain]);
    }

    function routerByDomain(uint32 domain) external view returns (address) {
        return address(uint160(uint256(getStorage().routers[domain])));
    }

    /* ========== Internal Functions ========== */

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 namespace = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}