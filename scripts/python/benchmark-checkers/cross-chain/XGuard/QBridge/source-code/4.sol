pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlIndexUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the index of the account that have `role`.
     */
    function getRoleMemberIndex(bytes32 role, address account) public view returns (uint256) {
        return _roles[role].members._inner._indexes[bytes32(uint256(account))];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    uint256[49] private __gap;
}



contract QBridge is PausableUpgradeable, AccessControlIndexUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    uint public constant MAX_RELAYERS = 200;

    enum ProposalStatus {Inactive, Active, Passed, Executed, Cancelled}

    struct Proposal {
        ProposalStatus _status;
        uint200 _yesVotes;      // bitmap, 200 maximum votes
        uint8 _yesVotesTotal;
        uint40 _proposedBlock; // 1099511627775 maximum block
    }

    /* ========== STATE VARIABLES ========== */

    uint8 public domainID;
    uint8 public relayerThreshold;
    uint128 public fee;
    uint40 public expiry;

    mapping(uint8 => uint64) public _depositCounts; // destinationDomainID => number of deposits
    mapping(bytes32 => address) public resourceIDToHandlerAddress; // resourceID => handler address
    mapping(uint72 => mapping(bytes32 => Proposal)) private _proposals; // destinationDomainID + depositNonce => dataHash => Proposal

    /* ========== EVENTS ========== */

    event RelayerThresholdChanged(uint256 newThreshold);
    event RelayerAdded(address relayer);
    event RelayerRemoved(address relayer);
    event Deposit(uint8 destinationDomainID, bytes32 resourceID, uint64 depositNonce, address indexed user, bytes data);
    event ProposalEvent(uint8 originDomainID, uint64 depositNonce, ProposalStatus status, bytes data);
    event ProposalVote(uint8 originDomainID, uint64 depositNonce, ProposalStatus status, bytes32 dataHash);
    event FailedHandlerExecution(bytes lowLevelData);

    /* ========== INITIALIZER ========== */

    function initialize(uint8 _domainID, uint8 _relayerThreshold, uint128 _fee, uint40 _expiry) external initializer {
        __PausableUpgradeable_init();
        __AccessControl_init();

        domainID = _domainID;
        relayerThreshold = _relayerThreshold;
        fee = _fee;
        expiry = _expiry;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRelayers() {
        require(hasRole(RELAYER_ROLE, msg.sender), "QBridge: caller is not the relayer");
        _;
    }

    modifier onlyOwnerOrRelayers() {
        require(owner() == msg.sender || hasRole(RELAYER_ROLE, msg.sender), "QBridge: caller is not the owner or relayer");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRelayerThreshold(uint8 newThreshold) external onlyOwner {
        relayerThreshold = newThreshold;
        emit RelayerThresholdChanged(newThreshold);
    }

    function addRelayer(address relayer) external onlyOwner {
        require(!hasRole(RELAYER_ROLE, relayer), "QBridge: duplicated relayer");
        require(totalRelayers() < MAX_RELAYERS, "QBridge: relayers limit reached");
        grantRole(RELAYER_ROLE, relayer);
        emit RelayerAdded(relayer);
    }

    function removeRelayer(address relayer) external onlyOwner {
        require(hasRole(RELAYER_ROLE, relayer), "QBridge: invalid relayer");
        revokeRole(RELAYER_ROLE, relayer);
        emit RelayerRemoved(relayer);
    }

    function setResource(address handlerAddress, bytes32 resourceID, address tokenAddress) external onlyOwner {
        resourceIDToHandlerAddress[resourceID] = handlerAddress;
        IQBridgeHandler(handlerAddress).setResource(resourceID, tokenAddress);
    }

    function setBurnable(address handlerAddress, address tokenAddress) external onlyOwner {
        IQBridgeHandler(handlerAddress).setBurnable(tokenAddress);
    }

    function setDepositNonce(uint8 _domainID, uint64 nonce) external onlyOwner {
        require(nonce > _depositCounts[_domainID], "QBridge: decrements not allowed");
        _depositCounts[_domainID] = nonce;
    }

    function setFee(uint128 newFee) external onlyOwner {
        fee = newFee;
    }

    function manualRelease(address handlerAddress, address tokenAddress, address recipient, uint amount) external onlyOwner {
        IQBridgeHandler(handlerAddress).withdraw(tokenAddress, recipient, amount);
    }

    function sweep() external onlyOwner {
        SafeToken.safeTransferETH(msg.sender, address(this).balance);
    }

    /* ========== VIEWS ========== */

    function isRelayer(address relayer) external view returns (bool) {
        return hasRole(RELAYER_ROLE, relayer);
    }

    function totalRelayers() public view returns (uint) {
        return AccessControlIndexUpgradeable.getRoleMemberCount(RELAYER_ROLE);
    }

    /**
        @notice Returns a proposalID.
        @param _domainID Chain ID.
        @param nonce ID of proposal generated by proposal's origin Bridge contract.
     */
    function combinedProposalId(uint8 _domainID, uint64 nonce) public pure returns (uint72 proposalID) {
        proposalID = (uint72(nonce) << 8) | uint72(_domainID);
    }

    /**
        @notice Returns a proposal.
        @param originDomainID Chain ID deposit originated from.
        @param depositNonce ID of proposal generated by proposal's origin Bridge contract.
        @param dataHash Hash of data to be provided when deposit proposal is executed.
     */
    function getProposal(uint8 originDomainID, uint64 depositNonce, bytes32 dataHash, address relayer) external view returns (Proposal memory proposal, bool hasVoted) {
        uint72 proposalID = combinedProposalId(originDomainID, depositNonce);
        proposal = _proposals[proposalID][dataHash];
        hasVoted = _hasVoted(proposal, relayer);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
        @notice Initiates a transfer using a specified handler contract.
        @notice Only callable when Bridge is not paused.
        @param destinationDomainID ID of chain deposit will be bridged to.
        @param resourceID ResourceID used to find address of handler to be used for deposit.
        @param data Additional data to be passed to specified handler.
        @notice Emits {Deposit} event with all necessary parameters
     */
    function deposit(uint8 destinationDomainID, bytes32 resourceID, bytes calldata data) external payable notPaused {
        require(msg.value == fee, "QBridge: invalid fee");

        address handler = resourceIDToHandlerAddress[resourceID];
        require(handler != address(0), "QBridge: invalid resourceID");

        uint64 depositNonce = ++_depositCounts[destinationDomainID];

        IQBridgeHandler(handler).deposit(resourceID, msg.sender, data);
        emit Deposit(destinationDomainID, resourceID, depositNonce, msg.sender, data);
    }

    function depositETH(uint8 destinationDomainID, bytes32 resourceID, bytes calldata data) external payable notPaused {
        uint option;
        uint amount;
        (option, amount) = abi.decode(data, (uint, uint));


        address handler = resourceIDToHandlerAddress[resourceID];
        require(handler != address(0), "QBridge: invalid resourceID");

        uint64 depositNonce = ++_depositCounts[destinationDomainID];

        IQBridgeHandler(handler).depositETH{value:amount}(resourceID, msg.sender, data);
        emit Deposit(destinationDomainID, resourceID, _depositCounts[destinationDomainID], msg.sender, data);
    }

    /**
        @notice When called, {msg.sender} will be marked as voting in favor of proposal.
        @notice Only callable by relayers when Bridge is not paused.
        @param originDomainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param data Data originally provided when deposit was made.
        @notice Proposal must not have already been passed or executed.
        @notice {msg.sender} must not have already voted on proposal.
        @notice Emits {ProposalEvent} event with status indicating the proposal status.
        @notice Emits {ProposalVote} event.
     */
    function voteProposal(uint8 originDomainID, uint64 depositNonce, bytes32 resourceID, bytes calldata data) external onlyRelayers notPaused {
        address handlerAddress = resourceIDToHandlerAddress[resourceID];
        require(handlerAddress != address(0), "QBridge: invalid handler");

        uint72 proposalID = combinedProposalId(originDomainID, depositNonce);
        bytes32 dataHash = keccak256(abi.encodePacked(handlerAddress, data));
        Proposal memory proposal = _proposals[proposalID][dataHash];

        if (proposal._status == ProposalStatus.Passed) {
            executeProposal(originDomainID, depositNonce, resourceID, data, true);
            return;
        }

        require(uint(proposal._status) <= 1, "QBridge: proposal already executed/cancelled");
        require(!_hasVoted(proposal, msg.sender), "QBridge: relayer already voted");

        if (proposal._status == ProposalStatus.Inactive) {
            proposal = Proposal({_status : ProposalStatus.Active, _yesVotes : 0, _yesVotesTotal : 0, _proposedBlock : uint40(block.number)});
            emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Active, data);
        }
//        else if (uint40(block.number.sub(proposal._proposedBlock)) > expiry) {
//            proposal._status = ProposalStatus.Cancelled;
//            emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Cancelled, dataHash);
//        }

        if (proposal._status != ProposalStatus.Cancelled) {
            proposal._yesVotes = _bitmap(proposal._yesVotes, _relayerBit(msg.sender));
            proposal._yesVotesTotal++;
            emit ProposalVote(originDomainID, depositNonce, proposal._status, dataHash);

            if (proposal._yesVotesTotal >= relayerThreshold) {
                proposal._status = ProposalStatus.Passed;
                emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Passed, data);
            }
        }
        _proposals[proposalID][dataHash] = proposal;

        if (proposal._status == ProposalStatus.Passed) {
            executeProposal(originDomainID, depositNonce, resourceID, data, false);
        }
    }

    /**
        @notice Executes a deposit proposal that is considered passed using a specified handler contract.
        @notice Only callable by relayers when Bridge is not paused.
        @param originDomainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param resourceID ResourceID to be used when making deposits.
        @param data Data originally provided when deposit was made.
        @param revertOnFail Decision if the transaction should be reverted in case of handler's executeProposal is reverted or not.
        @notice Proposal must have Passed status.
        @notice Hash of {data} must equal proposal's {dataHash}.
        @notice Emits {ProposalEvent} event with status {Executed}.
        @notice Emits {FailedExecution} event with the failed reason.
     */
    function executeProposal(uint8 originDomainID, uint64 depositNonce, bytes32 resourceID, bytes calldata data, bool revertOnFail) public onlyRelayers notPaused {
        address handlerAddress = resourceIDToHandlerAddress[resourceID];
        uint72 proposalID = combinedProposalId(originDomainID, depositNonce);
        bytes32 dataHash = keccak256(abi.encodePacked(handlerAddress, data));
        Proposal storage proposal = _proposals[proposalID][dataHash];

        require(proposal._status == ProposalStatus.Passed, "QBridge: Proposal must have Passed status");

        proposal._status = ProposalStatus.Executed;
        IQBridgeHandler handler = IQBridgeHandler(handlerAddress);

        if (revertOnFail) {
            handler.executeProposal(resourceID, data);
        } else {
            try handler.executeProposal(resourceID, data) {
            } catch (bytes memory lowLevelData) {
                proposal._status = ProposalStatus.Passed;
                emit FailedHandlerExecution(lowLevelData);
                return;
            }
        }
        emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Executed, data);
    }

    /**
        @notice Cancels a deposit proposal that has not been executed yet.
        @notice Only callable by relayers when Bridge is not paused.
        @param originDomainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param resourceID ResourceID to be used when making deposits.
        @param data Data originally provided when deposit was made.
        @notice Proposal must be past expiry threshold.
        @notice Emits {ProposalEvent} event with status {Cancelled}.
     */
    function cancelProposal(uint8 originDomainID, uint64 depositNonce, bytes32 resourceID, bytes calldata data) public onlyOwnerOrRelayers {
        address handlerAddress = resourceIDToHandlerAddress[resourceID];
        uint72 proposalID = combinedProposalId(originDomainID, depositNonce);
        bytes32 dataHash = keccak256(abi.encodePacked(handlerAddress, data));
        Proposal memory proposal = _proposals[proposalID][dataHash];
        ProposalStatus currentStatus = proposal._status;

        require(currentStatus == ProposalStatus.Active || currentStatus == ProposalStatus.Passed, "QBridge: cannot be cancelled");
        require(uint40(block.number.sub(proposal._proposedBlock)) > expiry, "QBridge: not at expiry threshold");

        proposal._status = ProposalStatus.Cancelled;
        _proposals[proposalID][dataHash] = proposal;
        emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Cancelled, data);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _relayerBit(address relayer) private view returns (uint) {
        if (relayer == address(0)) return 0;
        return uint(1) << AccessControlIndexUpgradeable.getRoleMemberIndex(RELAYER_ROLE, relayer).sub(1);
    }

    function _hasVoted(Proposal memory proposal, address relayer) private view returns (bool) {
        return (_relayerBit(relayer) & uint(proposal._yesVotes)) > 0;
    }

    function _bitmap(uint200 source, uint bit) internal pure returns (uint200) {
        uint value = source | bit;
        require(value < 2 ** 200, "QBridge: value does not fit in 200 bits");
        return uint200(value);
    }
}