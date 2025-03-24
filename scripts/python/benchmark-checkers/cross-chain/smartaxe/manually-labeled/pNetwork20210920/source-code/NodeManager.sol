pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/apps-vault/contracts/Vault.sol";
import "@aragon/os/contracts/lib/math/SafeMath.sol";
import "@aragon/os/contracts/lib/math/SafeMath64.sol";
import "@pnetwork/staking-manager/contracts/StakingManager.sol";
import "./SigUtils.sol";


contract NodeManager is AragonApp {
    using SafeMath for uint256;
    using SafeMath64 for uint64;

    bytes32 public constant CHANGE_MIN_STAKED_TOKENS_ROLE = keccak256("CHANGE_MIN_STAKED_TOKENS_ROLE");
    bytes32 public constant CHANGE_MIN_LOCK_TIME_ROLE = keccak256("CHANGE_MIN_LOCK_TIME_ROLE");
    bytes32 public constant CHANGE_MAX_NODES_PER_ADDRESS = keccak256("CHANGE_MAX_NODES_PER_ADDRESS");

    string private constant ERROR_ADDRESS_NOT_CONTRACT = "NODE_REGISTRATOR_ADDRESS_NOT_CONTRACT";
    string private constant ERROR_CANNOT_UPDATE_REGISTRATION = "NODE_REGISTRATOR_CANNOT_UPDATE_REGISTRATION";

    struct Registration {
        address node;
        uint64 date;
    }

    StakingManager public stakingManager;

    uint256 public minStakedTokens;
    uint64 public minLockTime;
    uint64 public maxNodesPerAddress;
    mapping(address => address) public nodeOwners;
    mapping(address => Registration[]) public ownerRegistrations;

    event RegistrationUpdated(address owner, address node);
    event MinStakedTokensChanged(uint256 minStakedTokens);
    event MinLockTimeChanged(uint64 minLockTime);
    event MaxNodePerAddressChanged(uint64 maxNodesPerAddress);

    /**
     * @notice Initialize NodeManager app contract. If we use precise _minLockTime, a user could lock tokens
     *         for _minLockTime from the staking manager and then registering a node with the same _minLockTime,
     *         which will lead to a reverted tx during the node registration because the stake
     *         time will be less than _minLockTime (time passed between first and second tx).
     *         Please use something like _minLockTime - ONE_DAY as _minLockTime
     * @param _stakingManager Staking Manager address
     * @param _minStakedTokens Vault address in which token are put
     * @param _minLockTime minimum number of seconds for which tokens must be staked in order to be able to register a node
     * @param _maxNodesPerAddress maximimum number of nodes per address
     */
    function initialize(
        address _stakingManager,
        uint256 _minStakedTokens,
        uint64 _minLockTime,
        uint64 _maxNodesPerAddress
    ) external onlyInit {
        require(isContract(_stakingManager), ERROR_ADDRESS_NOT_CONTRACT);
        stakingManager = StakingManager(_stakingManager);
        minStakedTokens = _minStakedTokens;
        minLockTime = _minLockTime;
        maxNodesPerAddress = _maxNodesPerAddress;
        initialized();
    }

    /**
     * @notice Change number of minimum number of tokens that must be staked to be able to register a node
     * @param _minStakedTokens number of tokens
     */
    function changeMinStakedTokens(uint256 _minStakedTokens) external auth(CHANGE_MIN_STAKED_TOKENS_ROLE) {
        minStakedTokens = _minStakedTokens;
        emit MinStakedTokensChanged(minStakedTokens);
    }

    /**
     * @notice Change number of seconds for which tokens must be staked in order to be able to register a node
     * @param _minLockTime Lock time
     */
    function changeMinLockTime(uint64 _minLockTime) external auth(CHANGE_MIN_LOCK_TIME_ROLE) {
        minLockTime = _minLockTime;
        emit MinLockTimeChanged(minLockTime);
    }

    /**
     * @notice Change maximimum number of nodes per address
     * @param _maxNodePerAddress maximimum number of nodes per address
     */
    function changeMaxNodesPerAddress(uint64 _maxNodePerAddress) external auth(CHANGE_MAX_NODES_PER_ADDRESS) {
        maxNodesPerAddress = _maxNodePerAddress;
        emit MaxNodePerAddressChanged(maxNodesPerAddress);
    }

    /**
     * @notice Create a link between an user and his node
     * @param _signature signature made by a node. The signed message must correspond to msg.sender
     */
    function updateRegistration(bytes _signature) external returns (bool) {
        uint64 currentTimestamp = getTimestamp64();
        require(canUpdateRegistration(msg.sender, currentTimestamp), ERROR_CANNOT_UPDATE_REGISTRATION);
        bytes32 message = SigUtils.prefixed(keccak256(abi.encodePacked(msg.sender)));
        address node = SigUtils.recoverSigner(message, _signature);
        nodeOwners[node] = msg.sender;
        // NOTE: at the moment it's possible only having just 1 node
        if (ownerRegistrations[msg.sender].length > 0)
            ownerRegistrations[msg.sender][0] = Registration(node, currentTimestamp);
        else ownerRegistrations[msg.sender].push(Registration(node, currentTimestamp));
        emit RegistrationUpdated(msg.sender, node);
        return true;
    }

    /**
     * @notice Check if a given _owner can update his node registration at a given _timestamp
     * @param _owner owner address
     */
    function canUpdateRegistration(address _owner, uint64 _timestamp) public view returns (bool) {
        uint256 totalValidStakedTokens = 0;
        for (uint64 i = 0; i < stakingManager.getNumberOfStakedLocks(_owner); i++) {
            (uint64 lockDate, uint64 duration, uint256 amount) = stakingManager.addressStakeLocks(_owner, i);
            // // NOTE: there could be empty locks (deleted ones) but in that case the condition below would never be met
            if (lockDate.add(duration) > _timestamp.add(minLockTime)) {
                totalValidStakedTokens = totalValidStakedTokens.add(amount);
            }
        }
        return totalValidStakedTokens >= minStakedTokens && ownerRegistrations[_owner].length < maxNodesPerAddress;
    }

    /**
     * @notice Return all node registrations given an _owner
     * @param _owner owner address
     */
    function getOwnerRegistrations(address _owner) public view returns (Registration[]) {
        return ownerRegistrations[_owner];
    }
}