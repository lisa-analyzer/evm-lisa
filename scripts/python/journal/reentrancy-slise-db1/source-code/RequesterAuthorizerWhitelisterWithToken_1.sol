// SPDX-License-Identifier: GPL-3.0-only
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}



interface IAccessControlRegistry is IAccessControl {
    event InitializedManager(bytes32 indexed rootRole, address indexed manager);

    event InitializedRole(
        bytes32 indexed role,
        bytes32 indexed adminRole,
        string description,
        address sender
    );

    function initializeManager(address manager) external;

    function initializeRoleAndGrantToSender(
        bytes32 adminRole,
        string calldata description
    ) external returns (bytes32 role);

    function deriveRootRole(address manager)
        external
        pure
        returns (bytes32 rootRole);

    function deriveRole(bytes32 adminRole, string calldata description)
        external
        pure
        returns (bytes32 role);
}


interface IAccessControlRegistryUser {
    function accessControlRegistry() external view returns (address);
}



interface IRegistryRolesWithManager is IAccessControlRegistryAdminned {
    // solhint-disable-next-line func-name-mixedcase
    function REGISTRAR_ROLE_DESCRIPTION() external view returns (string memory);

    function registrarRole() external view returns (bytes32);
}


/// @title Contract that implements the AccessControlRegistry role derivation
/// logic
/// @notice If a contract interfaces with AccessControlRegistry and needs to
/// derive roles, it should inherit this contract instead of re-implementing
/// the logic
contract RoleDeriver {
    /// @notice Derives the root role of the manager
    /// @param manager Manager address
    /// @return rootRole Root role
    function _deriveRootRole(address manager)
        internal
        pure
        returns (bytes32 rootRole)
    {
        rootRole = keccak256(abi.encodePacked(manager));
    }

    /// @notice Derives the role using its admin role and description
    /// @dev This implies that roles adminned by the same role cannot have the
    /// same description
    /// @param adminRole Admin role
    /// @param description Human-readable description of the role
    /// @return role Role
    function _deriveRole(bytes32 adminRole, string memory description)
        internal
        pure
        returns (bytes32 role)
    {
        role = _deriveRole(adminRole, keccak256(abi.encodePacked(description)));
    }

    /// @notice Derives the role using its admin role and description hash
    /// @dev This implies that roles adminned by the same role cannot have the
    /// same description
    /// @param adminRole Admin role
    /// @param descriptionHash Hash of the human-readable description of the
    /// role
    /// @return role Role
    function _deriveRole(bytes32 adminRole, bytes32 descriptionHash)
        internal
        pure
        returns (bytes32 role)
    {
        role = keccak256(abi.encodePacked(adminRole, descriptionHash));
    }
}



/// @title Contract that should be inherited by contracts that will interact
/// with AccessControlRegistry
contract AccessControlRegistryUser is IAccessControlRegistryUser {
    /// @notice AccessControlRegistry contract address
    address public immutable override accessControlRegistry;

    /// @param _accessControlRegistry AccessControlRegistry contract address
    constructor(address _accessControlRegistry) {
        require(_accessControlRegistry != address(0), "ACR address zero");
        accessControlRegistry = _accessControlRegistry;
    }
}



interface IAccessControlRegistryAdminned is IAccessControlRegistryUser {
    function adminRoleDescription() external view returns (string memory);
}



interface IAddressRegistry is IRegistryRolesWithManager {
    function tryReadRegisteredAddress(bytes32 id)
        external
        view
        returns (bool success, address address_);
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}



/// @title Contract that should be inherited by contracts whose adminship
/// functionality will be implemented using AccessControlRegistry
contract AccessControlRegistryAdminned is
    RoleDeriver,
    AccessControlRegistryUser,
    IAccessControlRegistryAdminned
{
    /// @notice Admin role description
    string public override adminRoleDescription;

    bytes32 internal immutable adminRoleDescriptionHash;

    /// @dev Contracts deployed with the same admin role descriptions will have
    /// the same roles, meaning that granting an account a role will authorize
    /// it in multiple contracts. Unless you want your deployed contract to
    /// share the role configuration of another contract, use a unique admin
    /// role description.
    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription
    ) AccessControlRegistryUser(_accessControlRegistry) {
        require(
            bytes(_adminRoleDescription).length > 0,
            "Admin role description empty"
        );
        adminRoleDescription = _adminRoleDescription;
        adminRoleDescriptionHash = keccak256(
            abi.encodePacked(_adminRoleDescription)
        );
    }

    /// @notice Derives the admin role for the specific manager address
    /// @param manager Manager address
    /// @return adminRole Admin role
    function _deriveAdminRole(address manager)
        internal
        view
        returns (bytes32 adminRole)
    {
        adminRole = _deriveRole(
            _deriveRootRole(manager),
            adminRoleDescriptionHash
        );
    }
}


interface IAirnodeEndpointPriceRegistry {
    event RegisterDefaultPrice(uint256 price, address sender);

    event RegisterDefaultChainPrice(
        uint256 chainId,
        uint256 price,
        address sender
    );

    event RegisterAirnodePrice(address airnode, uint256 price, address sender);

    event RegisterAirnodeChainPrice(
        address airnode,
        uint256 chainId,
        uint256 price,
        address sender
    );

    event RegisterAirnodeEndpointPrice(
        address airnode,
        bytes32 endpointId,
        uint256 price,
        address sender
    );

    event RegisterAirnodeChainEndpointPrice(
        address airnode,
        uint256 chainId,
        bytes32 endpointId,
        uint256 price,
        address sender
    );

    event SetEndpointAndChainPricePriority(
        address indexed airnode,
        bool status,
        address sender
    );

    function registerDefaultPrice(uint256 price) external;

    function registerDefaultChainPrice(uint256 chainId, uint256 price) external;

    function registerAirnodePrice(address airnode, uint256 price) external;

    function registerAirnodeChainPrice(
        address airnode,
        uint256 chainId,
        uint256 price
    ) external;

    function registerAirnodeEndpointPrice(
        address airnode,
        bytes32 endpointId,
        uint256 price
    ) external;

    function registerAirnodeChainEndpointPrice(
        address airnode,
        uint256 chainId,
        bytes32 endpointId,
        uint256 price
    ) external;

    function setEndpointAndChainPricePriority(address airnode, bool status)
        external;

    function tryReadDefaultPrice()
        external
        view
        returns (bool success, uint256 price);

    function tryReadDefaultChainPrice(uint256 chainId)
        external
        view
        returns (bool success, uint256 price);

    function tryReadAirnodePrice(address airnode)
        external
        view
        returns (bool success, uint256 price);

    function tryReadAirnodeChainPrice(address airnode, uint256 chainId)
        external
        view
        returns (bool success, uint256 price);

    function tryReadAirnodeEndpointPrice(address airnode, bytes32 endpointId)
        external
        view
        returns (bool success, uint256 price);

    function tryReadAirnodeChainEndpointPrice(
        address airnode,
        uint256 chainId,
        bytes32 endpointId
    ) external view returns (bool success, uint256 price);

    function getPrice(
        address airnode,
        uint256 chainId,
        bytes32 endpointId
    ) external view returns (uint256 price);

    function prioritizeEndpointPriceOverChainPrice(address airnode)
        external
        view
        returns (bool);

    // solhint-disable-next-line func-name-mixedcase
    function DENOMINATION() external view returns (string memory);

    // solhint-disable-next-line func-name-mixedcase
    function DECIMALS() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function PRICING_INTERVAL() external view returns (uint256);
}



interface IRequesterAuthorizerRegistry is IAddressRegistry {
    event RegisteredChainRequesterAuthorizer(
        uint256 chainId,
        address requesterAuthorizer,
        address sender
    );

    function registerChainRequesterAuthorizer(
        uint256 chainId,
        address requesterAuthorizer
    ) external;

    function tryReadChainRequesterAuthorizer(uint256 chainId)
        external
        view
        returns (bool success, address requesterAuthorizer);
}



interface IAccessControlRegistryAdminnedWithManager is
    IAccessControlRegistryAdminned
{
    function manager() external view returns (address);

    function adminRole() external view returns (bytes32);
}


interface IAirnodeEndpointPriceRegistryUser {
    function airnodeEndpointPriceRegistry() external view returns (address);
}


interface IRequesterAuthorizerRegistryUser {
    function requesterAuthorizerRegistry() external view returns (address);
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)



/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}



/// @title Contract that should be inherited by contracts with manager whose
/// adminship functionality will be implemented using AccessControlRegistry
/// @notice The manager address here is expected to belong to an
/// AccessControlRegistry user that is a multisig/DAO
contract AccessControlRegistryAdminnedWithManager is
    AccessControlRegistryAdminned,
    IAccessControlRegistryAdminnedWithManager
{
    /// @notice Address of the manager that manages the related
    /// AccessControlRegistry roles
    /// @dev The mutability of the manager role can be implemented by
    /// designating an OwnableCallForwarder contract as the manager. The
    /// ownership of this contract can then be transferred, effectively
    /// transferring managership.
    address public immutable override manager;

    /// @notice Admin role
    /// @dev Since `manager` is immutable, so is `adminRole`
    bytes32 public immutable override adminRole;

    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager
    )
        AccessControlRegistryAdminned(
            _accessControlRegistry,
            _adminRoleDescription
        )
    {
        require(_manager != address(0), "Manager address zero");
        manager = _manager;
        adminRole = _deriveAdminRole(_manager);
    }
}



/// @title Contract that should be inherited by contracts that will interact
/// with AirnodeEndpointPriceRegistry
contract AirnodeEndpointPriceRegistryUser is IAirnodeEndpointPriceRegistryUser {
    /// @notice AirnodeEndpointPriceRegistry contract address
    address public immutable override airnodeEndpointPriceRegistry;

    /// @param _airnodeEndpointPriceRegistry AirnodeEndpointPriceRegistry
    /// contract address
    constructor(address _airnodeEndpointPriceRegistry) {
        require(
            _airnodeEndpointPriceRegistry != address(0),
            "Price registry address zero"
        );
        airnodeEndpointPriceRegistry = _airnodeEndpointPriceRegistry;
    }
}



/// @title Contract that should be inherited by contracts that will interact
/// with RequesterAuthorizerRegistry
contract RequesterAuthorizerRegistryUser is IRequesterAuthorizerRegistryUser {
    /// @notice RequesterAuthorizerRegistry contract address
    address public immutable override requesterAuthorizerRegistry;

    /// @param _requesterAuthorizerRegistry RequesterAuthorizerRegistry contract address
    constructor(address _requesterAuthorizerRegistry) {
        require(
            _requesterAuthorizerRegistry != address(0),
            "Authorizer registry address zero"
        );
        requesterAuthorizerRegistry = _requesterAuthorizerRegistry;
    }
}



interface IRequesterAuthorizerWhitelisterWithToken is
    IAccessControlRegistryAdminnedWithManager,
    IAirnodeEndpointPriceRegistryUser,
    IRequesterAuthorizerRegistryUser
{
    enum AirnodeParticipationStatus {
        Inactive,
        Active,
        OptedOut
    }

    event SetTokenPrice(uint256 tokenPrice, address sender);

    event SetPriceCoefficient(uint256 priceCoefficient, address sender);

    event SetAirnodeParticipationStatus(
        address airnode,
        AirnodeParticipationStatus airnodeParticipationStatus,
        address sender
    );

    event SetProceedsDestination(address proceedsDestination);

    event SetRequesterBlockStatus(
        address requester,
        bool status,
        address sender
    );

    event SetRequesterBlockStatusForAirnode(
        address airnode,
        address requester,
        bool status,
        address sender
    );

    function setTokenPrice(uint256 _tokenPrice) external;

    function setPriceCoefficient(uint256 _priceCoefficient) external;

    function setAirnodeParticipationStatus(
        address airnode,
        AirnodeParticipationStatus airnodeParticipationStatus
    ) external;

    function setProceedsDestination(address _proceedsDestination) external;

    function setRequesterBlockStatus(address requester, bool status) external;

    function setRequesterBlockStatusForAirnode(
        address airnode,
        address requester,
        bool status
    ) external;

    function getTokenAmount(
        address airnode,
        uint256 chainId,
        bytes32 endpointId
    ) external view returns (uint256 amount);

    function token() external view returns (address);

    function tokenPrice() external view returns (uint256);

    function priceCoefficient() external view returns (uint256);

    function proceedsDestination() external view returns (address);

    function airnodeToParticipationStatus(address airnode)
        external
        view
        returns (AirnodeParticipationStatus);

    function requesterToBlockStatus(address requester)
        external
        view
        returns (bool);

    function airnodeToRequesterToBlockStatus(address airnode, address requester)
        external
        view
        returns (bool);

    // solhint-disable-next-line func-name-mixedcase
    function MAINTAINER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    function maintainerRole() external view returns (bytes32);

    // solhint-disable-next-line func-name-mixedcase
    function BLOCKER_ROLE_DESCRIPTION() external view returns (string memory);

    function blockerRole() external view returns (bytes32);
}


interface IRequesterAuthorizer {
    event ExtendedWhitelistExpiration(
        address indexed airnode,
        bytes32 endpointId,
        address indexed requester,
        address indexed sender,
        uint256 expiration
    );

    event SetWhitelistExpiration(
        address indexed airnode,
        bytes32 endpointId,
        address indexed requester,
        address indexed sender,
        uint256 expiration
    );

    event SetIndefiniteWhitelistStatus(
        address indexed airnode,
        bytes32 endpointId,
        address indexed requester,
        address indexed sender,
        bool status,
        uint192 indefiniteWhitelistCount
    );

    event RevokedIndefiniteWhitelistStatus(
        address indexed airnode,
        bytes32 endpointId,
        address indexed requester,
        address indexed setter,
        address sender,
        uint192 indefiniteWhitelistCount
    );

    function extendWhitelistExpiration(
        address airnode,
        bytes32 endpointId,
        address requester,
        uint64 expirationTimestamp
    ) external;

    function setWhitelistExpiration(
        address airnode,
        bytes32 endpointId,
        address requester,
        uint64 expirationTimestamp
    ) external;

    function setIndefiniteWhitelistStatus(
        address airnode,
        bytes32 endpointId,
        address requester,
        bool status
    ) external;

    function revokeIndefiniteWhitelistStatus(
        address airnode,
        bytes32 endpointId,
        address requester,
        address setter
    ) external;

    function airnodeToEndpointIdToRequesterToWhitelistStatus(
        address airnode,
        bytes32 endpointId,
        address requester
    )
        external
        view
        returns (uint64 expirationTimestamp, uint192 indefiniteWhitelistCount);

    function airnodeToEndpointIdToRequesterToSetterToIndefiniteWhitelistStatus(
        address airnode,
        bytes32 endpointId,
        address requester,
        address setter
    ) external view returns (bool indefiniteWhitelistStatus);

    function isAuthorized(
        address airnode,
        bytes32 endpointId,
        address requester
    ) external view returns (bool);
}



/// @title Base contract for RequesterAuthorizer whitelister contracts that
/// will whitelist based on token interaction
contract RequesterAuthorizerWhitelisterWithToken is
    Multicall,
    AccessControlRegistryAdminnedWithManager,
    AirnodeEndpointPriceRegistryUser,
    RequesterAuthorizerRegistryUser,
    IRequesterAuthorizerWhitelisterWithToken
{
    /// @notice Maintainer role description
    string public constant override MAINTAINER_ROLE_DESCRIPTION = "Maintainer";

    /// @notice Blocker role description
    string public constant override BLOCKER_ROLE_DESCRIPTION = "Blocker";

    /// @notice Maintainer role
    /// @dev Maintainers do day-to-day operation such as maintaining price
    /// parameters and Airnode participation statuses
    bytes32 public immutable override maintainerRole;

    /// @notice Blocker role
    /// @dev Blockers deny service to malicious requesters. Since this
    /// functionality can also be used to deny service to regular users, it
    /// should be limited at the blocker contract level (instead of giving this
    /// role to EOAs).
    bytes32 public immutable override blockerRole;

    /// @notice Contract address of the token that will be deposited, paid,
    /// etc.
    address public immutable token;

    /// @notice Token price in USD (times 10^18)
    uint256 public override tokenPrice;

    /// @notice Coefficient that can be used to adjust the amount of tokens
    /// required to interact with the contract
    /// @dev If `token` has 18 decimals, a `priceCoefficient` of 10^18 means
    /// the price registry amount will be used directly, while a
    /// `priceCoefficient` of 10^19 means 10 times the price registry amount
    /// will be used. On the other hand, if `token` has 6 decimals, a
    /// `priceCoefficient` of 10^6 means the price registry amount will be used
    /// directly, etc.
    uint256 public override priceCoefficient;

    /// @notice Address that the funds will be collected at
    address public override proceedsDestination;

    /// @notice If the Airnode is participating in the scheme implemented by
    /// the contract:
    /// Inactive: The Airnode is not participating, but can be made to
    /// participate by a mantainer
    /// Active: The Airnode is participating
    /// OptedOut: The Airnode actively opted out, and cannot be made to
    /// participate unless this is reverted by the Airnode
    mapping(address => AirnodeParticipationStatus)
        public
        override airnodeToParticipationStatus;

    /// @notice If a requester is blocked globally
    mapping(address => bool) public override requesterToBlockStatus;

    /// @notice If a requester is blocked for the specific Airnode
    mapping(address => mapping(address => bool))
        public
        override airnodeToRequesterToBlockStatus;

    /// @dev Reverts if Airnode address is zero
    /// @param airnode Airnode address
    modifier onlyNonZeroAirnode(address airnode) {
        require(airnode != address(0), "Airnode address zero");
        _;
    }

    /// @dev Reverts if Airnode is not active
    /// @param airnode Airnode address
    modifier onlyActiveAirnode(address airnode) {
        require(
            airnodeToParticipationStatus[airnode] ==
                AirnodeParticipationStatus.Active,
            "Airnode not active"
        );
        _;
    }

    /// @dev Reverts if chain ID is zero
    /// @param chainId Chain ID
    modifier onlyNonZeroChainId(uint256 chainId) {
        require(chainId != 0, "Chain ID zero");
        _;
    }

    /// @dev Reverts if requester address is zero
    /// @param requester Requester address
    modifier onlyNonZeroRequester(address requester) {
        require(requester != address(0), "Requester address zero");
        _;
    }

    /// @dev Reverts if requester is blocked
    /// @param airnode Airnode address
    /// @param requester Requester address
    modifier onlyNonBlockedRequester(address airnode, address requester) {
        require(!requesterIsBlocked(airnode, requester), "Requester blocked");
        _;
    }

    /// @dev Reverts if sender does not have the maintainer role and is not the
    /// manager
    modifier onlyMaintainerOrManager() {
        require(
            manager == msg.sender ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    maintainerRole,
                    msg.sender
                ),
            "Sender cannot maintain"
        );
        _;
    }

    /// @dev Reverts if sender does not have the blocker role and is not the
    /// manager
    modifier onlyBlockerOrManager() {
        require(
            manager == msg.sender ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    blockerRole,
                    msg.sender
                ),
            "Sender cannot block"
        );
        _;
    }

    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    /// @param _airnodeEndpointPriceRegistry AirnodeEndpointPriceRegistry
    /// contract address
    /// @param _requesterAuthorizerRegistry RequesterAuthorizerRegistry
    /// contract address
    /// @param _token Token contract address
    /// @param _tokenPrice Token price in USD (times 10^18)
    /// @param _priceCoefficient Price coefficient (has the same number of
    /// decimals as the token)
    /// @param _proceedsDestination Destination of proceeds
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager,
        address _airnodeEndpointPriceRegistry,
        address _requesterAuthorizerRegistry,
        address _token,
        uint256 _tokenPrice,
        uint256 _priceCoefficient,
        address _proceedsDestination
    )
        AccessControlRegistryAdminnedWithManager(
            _accessControlRegistry,
            _adminRoleDescription,
            _manager
        )
        AirnodeEndpointPriceRegistryUser(_airnodeEndpointPriceRegistry)
        RequesterAuthorizerRegistryUser(_requesterAuthorizerRegistry)
    {
        require(_token != address(0), "Token address zero");
        token = _token;
        _setTokenPrice(_tokenPrice);
        _setPriceCoefficient(_priceCoefficient);
        _setProceedsDestination(_proceedsDestination);
        maintainerRole = _deriveRole(
            adminRole,
            keccak256(abi.encodePacked(MAINTAINER_ROLE_DESCRIPTION))
        );
        blockerRole = _deriveRole(
            adminRole,
            keccak256(abi.encodePacked(BLOCKER_ROLE_DESCRIPTION))
        );
        require(
            keccak256(
                abi.encodePacked(
                    IAirnodeEndpointPriceRegistry(airnodeEndpointPriceRegistry)
                        .DENOMINATION()
                )
            ) == keccak256(abi.encodePacked("USD")),
            "Price denomination mismatch"
        );
        require(
            IAirnodeEndpointPriceRegistry(airnodeEndpointPriceRegistry)
                .DECIMALS() == 18,
            "Price decimals mismatch"
        );
    }

    /// @notice Sets token price
    /// @param _tokenPrice Token price in USD (times 10^18)
    function setTokenPrice(uint256 _tokenPrice)
        external
        override
        onlyMaintainerOrManager
    {
        _setTokenPrice(_tokenPrice);
        emit SetTokenPrice(_tokenPrice, msg.sender);
    }

    /// @notice Sets price coefficient
    /// @param _priceCoefficient Price coefficient (has the same number of
    /// decimals as the token)
    function setPriceCoefficient(uint256 _priceCoefficient)
        external
        override
        onlyMaintainerOrManager
    {
        _setPriceCoefficient(_priceCoefficient);
        emit SetPriceCoefficient(_priceCoefficient, msg.sender);
    }

    /// @notice Sets Airnode participation status
    /// @param airnode Airnode address
    /// @param airnodeParticipationStatus Airnode participation status
    function setAirnodeParticipationStatus(
        address airnode,
        AirnodeParticipationStatus airnodeParticipationStatus
    ) external override onlyNonZeroAirnode(airnode) {
        if (msg.sender == airnode) {
            require(
                airnodeParticipationStatus ==
                    AirnodeParticipationStatus.OptedOut,
                "Airnode can only opt out"
            );
        } else {
            require(
                manager == msg.sender ||
                    IAccessControlRegistry(accessControlRegistry).hasRole(
                        maintainerRole,
                        msg.sender
                    ),
                "Sender cannot maintain"
            );
            require(
                airnodeParticipationStatus !=
                    AirnodeParticipationStatus.OptedOut,
                "Only Airnode can opt out"
            );
            require(
                airnodeToParticipationStatus[airnode] !=
                    AirnodeParticipationStatus.OptedOut,
                "Airnode opted out"
            );
        }
        airnodeToParticipationStatus[airnode] = airnodeParticipationStatus;
        emit SetAirnodeParticipationStatus(
            airnode,
            airnodeParticipationStatus,
            msg.sender
        );
    }

    /// @notice Sets destination of proceeds
    /// @param _proceedsDestination Destination of proceeds
    function setProceedsDestination(address _proceedsDestination)
        external
        override
    {
        require(msg.sender == manager, "Sender not manager");
        _setProceedsDestination(_proceedsDestination);
        emit SetProceedsDestination(_proceedsDestination);
    }

    /// @notice Blocks requester globally
    /// @param requester Requester address
    /// @param status Requester block status (`true` represents being blocked)
    // SWC-Transaction Order Dependence: L284-L292
    function setRequesterBlockStatus(address requester, bool status)
        external
        override
        onlyBlockerOrManager
        onlyNonZeroRequester(requester)
    {
        requesterToBlockStatus[requester] = status;
        emit SetRequesterBlockStatus(requester, status, msg.sender);
    }

    /// @notice Blocks requester for the Airnode
    /// @param airnode Airnode address
    /// @param requester Requester address
    /// @param status Requester block status (`true` represents being blocked)
    function setRequesterBlockStatusForAirnode(
        address airnode,
        address requester,
        bool status
    )
        external
        override
        onlyBlockerOrManager
        onlyNonZeroAirnode(airnode)
        onlyNonZeroRequester(requester)
    {
        airnodeToRequesterToBlockStatus[airnode][requester] = status;
        emit SetRequesterBlockStatusForAirnode(
            airnode,
            requester,
            status,
            msg.sender
        );
    }

    /// @notice Amount of tokens needed to be whitelisted for the
    /// Airnode–endpoint pair on the chain
    /// @param airnode Airnode address
    /// @param chainId Chain ID
    /// @param endpointId Endpoint ID
    function getTokenAmount(
        address airnode,
        uint256 chainId,
        bytes32 endpointId
    ) public view override returns (uint256 amount) {
        uint256 endpointPrice = IAirnodeEndpointPriceRegistry(
            airnodeEndpointPriceRegistry
        ).getPrice(airnode, chainId, endpointId);
        amount = (endpointPrice * priceCoefficient) / tokenPrice;
    }

    /// @notice Called internally to check if the requester is blocked
    /// @dev Requesters can be blocked globally or for the specific Airnode
    /// @param airnode Airnode address
    /// @param requester Requester address
    function requesterIsBlocked(address airnode, address requester)
        internal
        view
        returns (bool)
    {
        return
            requesterToBlockStatus[requester] ||
            airnodeToRequesterToBlockStatus[airnode][requester];
    }

    /// @notice Fetches the RequesterAuthorizer address for the chain
    /// @dev Reverts if the contract address has not been registered beforehand
    /// @param chainId Chain ID
    /// @return RequesterAuthorizer address
    function getRequesterAuthorizerAddress(uint256 chainId)
        internal
        view
        returns (address)
    {
        (
            bool success,
            address requesterAuthorizer
        ) = IRequesterAuthorizerRegistry(requesterAuthorizerRegistry)
                .tryReadChainRequesterAuthorizer(chainId);
        require(success, "No Authorizer set for chain");
        return requesterAuthorizer;
    }

    /// @notice Called privately to set the token price
    /// @param _tokenPrice Token price in USD (times 10^18)
    function _setTokenPrice(uint256 _tokenPrice) private {
        require(_tokenPrice != 0, "Token price zero");
        tokenPrice = _tokenPrice;
    }

    /// @notice Called privately to set the price coefficient
    /// @param _priceCoefficient Price coefficient (has the same number of
    /// decimals as the token)
    function _setPriceCoefficient(uint256 _priceCoefficient) private {
        require(_priceCoefficient != 0, "Price coefficient zero");
        priceCoefficient = _priceCoefficient;
    }

    function _setProceedsDestination(address _proceedsDestination) private {
        require(
            _proceedsDestination != address(0),
            "Proceeds destination zero"
        );
        proceedsDestination = _proceedsDestination;
    }
}
