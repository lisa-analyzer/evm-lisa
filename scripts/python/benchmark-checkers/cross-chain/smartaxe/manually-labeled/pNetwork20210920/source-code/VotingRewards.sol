pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/os/contracts/common/SafeERC20.sol";
import "@aragon/os/contracts/lib/token/ERC20.sol";
import "@1hive/apps-dandelion-voting/contracts/DandelionVoting.sol";
import "@aragon/apps-vault/contracts/Vault.sol";
import "@aragon/os/contracts/lib/math/SafeMath.sol";
import "@aragon/os/contracts/lib/math/SafeMath64.sol";
import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";


contract VotingRewards is AragonApp {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using SafeMath64 for uint64;

    bytes32 public constant CHANGE_EPOCH_DURATION_ROLE = keccak256("CHANGE_EPOCH_DURATION_ROLE");
    bytes32 public constant CHANGE_LOCK_TIME_ROLE = keccak256("CHANGE_LOCK_TIME_ROLE");
    bytes32 public constant CHANGE_MISSING_VOTES_THRESHOLD_ROLE = keccak256("CHANGE_MISSING_VOTES_THRESHOLD_ROLE");
    bytes32 public constant OPEN_REWARDS_DISTRIBUTION_ROLE = keccak256("OPEN_REWARDS_DISTRIBUTION_ROLE");
    bytes32 public constant CLOSE_REWARDS_DISTRIBUTION_ROLE = keccak256("CLOSE_REWARDS_DISTRIBUTION_ROLE");
    bytes32 public constant DISTRIBUTE_REWARDS_ROLE = keccak256("DISTRIBUTE_REWARDS_ROLE");
    bytes32 public constant CHANGE_PERCENTAGE_REWARDS_ROLE = keccak256("CHANGE_PERCENTAGE_REWARDS_ROLE");
    bytes32 public constant CHANGE_VAULT_ROLE = keccak256("CHANGE_VAULT_ROLE");
    bytes32 public constant CHANGE_REWARDS_TOKEN_ROLE = keccak256("CHANGE_REWARDS_TOKEN_ROLE");
    bytes32 public constant CHANGE_VOTING_ROLE = keccak256("CHANGE_VOTING_ROLE");
    bytes32 public constant COLLECT_REWARDS_ROLE = keccak256("COLLECT_REWARDS_ROLE");

    uint64 public constant PCT_BASE = 10**18; // 0% = 0; 1% = 10^16; 100% = 10^18

    string private constant ERROR_ADDRESS_NOT_CONTRACT = "VOTING_REWARDS_ADDRESS_NOT_CONTRACT";
    string private constant ERROR_EPOCH = "VOTING_REWARDS_ERROR_EPOCH";
    string private constant ERROR_PERCENTAGE_REWARDS = "VOTING_REWARDS_ERROR_PERCENTAGE_REWARDS";
    // prettier-ignore
    string private constant ERROR_EPOCH_REWARDS_DISTRIBUTION_NOT_OPENED = "VOTING_REWARDS_EPOCH_REWARDS_DISTRIBUTION_NOT_OPENED";
    // prettier-ignore
    string private constant ERROR_EPOCH_REWARDS_DISTRIBUTION_ALREADY_OPENED = "VOTING_REWARDS_EPOCH_REWARDS_DISTRIBUTION_ALREADY_OPENED";
    string private constant ERROR_NO_REWARDS = "VOTING_REWARDS_NO_REWARDS";

    struct Reward {
        uint256 amount;
        uint64 lockBlock;
        uint64 lockTime;
    }

    Vault public baseVault;
    Vault public rewardsVault;
    DandelionVoting public dandelionVoting;

    address public rewardsToken;
    uint256 public percentageRewards;
    uint256 public missingVotesThreshold;

    uint64 public epochDuration;
    uint64 public currentEpoch;
    uint64 public startBlockNumberOfCurrentEpoch;
    uint64 public lockTime;
    uint64 public lastRewardsDistributionBlock;
    uint64 private deployBlock;

    bool public isDistributionOpen;

    // NOTE: previousRewardsDistributionBlockNumber kept even if not used so as not to break the proxy contract storage after an upgrade
    mapping(address => uint64) private previousRewardsDistributionBlockNumber;
    mapping(address => Reward[]) public addressUnlockedRewards;
    mapping(address => Reward[]) public addressWithdrawnRewards; // kept even if not used so as not to break the proxy contract storage after an upgrade

    event BaseVaultChanged(address baseVault);
    event RewardsVaultChanged(address rewardsVault);
    event DandelionVotingChanged(address dandelionVoting);
    event PercentageRewardsChanged(uint256 percentageRewards);
    event RewardDistributed(address indexed beneficiary, uint256 indexed amount, uint64 lockTime);
    event RewardCollected(address indexed beneficiary, uint256 amount, uint64 indexed lockBlock, uint64 lockTime);
    event EpochDurationChanged(uint64 epochDuration);
    event MissingVoteThresholdChanged(uint256 missingVotesThreshold);
    event LockTimeChanged(uint64 lockTime);
    event RewardsDistributionEpochOpened(uint64 startBlock, uint64 endBlock);
    event RewardsDistributionEpochClosed(uint64 rewardDistributionBlock);
    event RewardsTokenChanged(address rewardsToken);

    /**
     * @notice Initialize VotingRewards app contract
     * @param _baseVault Vault address from which token are taken
     * @param _rewardsVault Vault address to which token are put
     * @param _rewardsToken Accepted token address
     * @param _epochDuration number of blocks for which an epoch is opened
     * @param _percentageRewards percentage of a reward expressed as a number between 10^16 and 10^18
     * @param _lockTime number of blocks for which token will be locked after colleting reward
     * @param _missingVotesThreshold number of missing votes allowed in an epoch
     */
    function initialize(
        address _baseVault,
        address _rewardsVault,
        address _dandelionVoting,
        address _rewardsToken,
        uint64 _epochDuration,
        uint256 _percentageRewards,
        uint64 _lockTime,
        uint256 _missingVotesThreshold
    ) external onlyInit {
        require(isContract(_baseVault), ERROR_ADDRESS_NOT_CONTRACT);
        require(isContract(_rewardsVault), ERROR_ADDRESS_NOT_CONTRACT);
        require(isContract(_dandelionVoting), ERROR_ADDRESS_NOT_CONTRACT);
        require(isContract(_rewardsToken), ERROR_ADDRESS_NOT_CONTRACT);
        require(_percentageRewards <= PCT_BASE, ERROR_PERCENTAGE_REWARDS);

        baseVault = Vault(_baseVault);
        rewardsVault = Vault(_rewardsVault);
        dandelionVoting = DandelionVoting(_dandelionVoting);
        rewardsToken = _rewardsToken;
        epochDuration = _epochDuration;
        percentageRewards = _percentageRewards;
        missingVotesThreshold = _missingVotesThreshold;
        lockTime = _lockTime;

        deployBlock = getBlockNumber64();
        lastRewardsDistributionBlock = getBlockNumber64();
        currentEpoch = 0;

        initialized();
    }

    /**
     * @notice Open the distribution for the current epoch from _fromBlock
     * @param _fromBlock block from which starting to look for rewards
     */
    function openRewardsDistributionForEpoch(uint64 _fromBlock) external auth(OPEN_REWARDS_DISTRIBUTION_ROLE) {
        require(!isDistributionOpen, ERROR_EPOCH_REWARDS_DISTRIBUTION_ALREADY_OPENED);
        require(_fromBlock > lastRewardsDistributionBlock, ERROR_EPOCH);
        require(getBlockNumber64() - lastRewardsDistributionBlock > epochDuration, ERROR_EPOCH);

        startBlockNumberOfCurrentEpoch = _fromBlock;
        isDistributionOpen = true;

        emit RewardsDistributionEpochOpened(_fromBlock, _fromBlock + epochDuration);
    }

    /**
     * @notice close distribution for thee current epoch if it's opened and starts a new one
     */
    function closeRewardsDistributionForCurrentEpoch() external auth(CLOSE_REWARDS_DISTRIBUTION_ROLE) {
        require(isDistributionOpen == true, ERROR_EPOCH_REWARDS_DISTRIBUTION_NOT_OPENED);
        isDistributionOpen = false;
        currentEpoch = currentEpoch.add(1);
        lastRewardsDistributionBlock = getBlockNumber64();
        emit RewardsDistributionEpochClosed(lastRewardsDistributionBlock);
    }

    /**
     * @notice Distribute rewards to _beneficiary
     * @param _beneficiary address to which the deposit will be transferred if successful
     * @param _amount corresponding amount for each address
     * @dev baseVault should have TRANSFER_ROLE permission
     */
    function distributeRewardsTo(address _beneficiary, uint256 _amount)
        external
        auth(DISTRIBUTE_REWARDS_ROLE)
        returns (bool)
    {
        require(isDistributionOpen, ERROR_EPOCH_REWARDS_DISTRIBUTION_NOT_OPENED);
        _distributeRewardsTo(_beneficiary, _amount, lockTime);
        return true;
    }

    /**
     * @notice distribute rewards for a list of address. Tokens are locked for lockTime in rewardsVault
     * @param _beneficiaries address that are looking for reward
     * @param _amounts corresponding amount for each address
     * @dev this function should be called from outside each _epochDuration seconds
     */
    function distributeRewardsToMany(address[] _beneficiaries, uint256[] _amounts)
        external
        auth(DISTRIBUTE_REWARDS_ROLE)
        returns (bool)
    {
        require(isDistributionOpen, ERROR_EPOCH_REWARDS_DISTRIBUTION_NOT_OPENED);
        _distributeRewardsToMany(_beneficiaries, _amounts, lockTime);
        return true;
    }

    /**
     * @notice force reward distribution to a _beneficiary
     * @param _beneficiary address to which the deposit will be transferred if successful
     * @param _amount corresponding amount for each address
     * @param _lockTime lockTime
     */
    function forceDistributeRewardsTo(
        address _beneficiary,
        uint256 _amount,
        uint64 _lockTime
    ) external auth(DISTRIBUTE_REWARDS_ROLE) returns (bool) {
        _distributeRewardsTo(_beneficiary, _amount, _lockTime);
        return true;
    }

    /**
     * @notice force rewards distribution for a list of addresses. Tokens are locked for lockTime in rewardsVault
     * @param _beneficiaries address that are looking for reward
     * @param _amounts corresponding amount for each address
     * @param _lockTime lockTime
     */
    function forceDistributeRewardsToMany(
        address[] _beneficiaries,
        uint256[] _amounts,
        uint64 _lockTime
    ) external auth(DISTRIBUTE_REWARDS_ROLE) returns (bool) {
        _distributeRewardsToMany(_beneficiaries, _amounts, _lockTime);
        return true;
    }

    /**
     * @notice collect rewards for msg.sender
     */
    function collectRewards() external {
        _collectRewardsFor(msg.sender, msg.sender);
    }

    /**
     * @notice collect rewards for an address
     * @param _beneficiary address that should be fund with rewards
     */
    function collectRewardsFor(address _beneficiary) external {
        _collectRewardsFor(_beneficiary, _beneficiary);
    }

    /**
     * @notice collect rewards for a list of address
     *         if lockTime is passed since when tokens have been distributed
     * @param _beneficiaries addresses that should be fund with rewards
     */
    function collectRewardsForMany(address[] _beneficiaries) external {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _collectRewardsFor(_beneficiaries[i], _beneficiaries[i]);
        }
    }

    /**
     * @notice collect rewards for many addresses specifying the effective receivers
     * @param _beneficiaries addresses that should be fund with rewards
     * @param _receivers who receives the rewards
     */
    function forceCollectRewardsForMany(address[] _beneficiaries, address[] _receivers)
        external
        auth(COLLECT_REWARDS_ROLE)
    {
        uint256 beneficiaresLength = _beneficiaries.length;
        for (uint256 i = 0; i < beneficiaresLength; i++) {
            _collectRewardsFor(_beneficiaries[i], _receivers[i]);
        }
    }

    /**
     * @notice collect rewards for an address specifying the effective receiver
     * @param _beneficiary address that should be fund with rewards
     * @param _receiver who receives the rewards
     */
    function forceCollectRewardsFor(address _beneficiary, address _receiver) external auth(COLLECT_REWARDS_ROLE) {
        _collectRewardsFor(_beneficiary, _receiver);
    }

    /**
     * @notice Change minimum number of seconds to claim dandelionVoting rewards
     * @param _epochDuration number of seconds minimum to claim access to dandelionVoting rewards
     */
    function changeEpochDuration(uint64 _epochDuration) external auth(CHANGE_EPOCH_DURATION_ROLE) {
        require(_epochDuration > 0, ERROR_EPOCH);
        epochDuration = _epochDuration;
        emit EpochDurationChanged(_epochDuration);
    }

    /**
     * @notice Change minimum number of missing votes allowed
     * @param _missingVotesThreshold number of seconds minimum to claim access to voting rewards
     */
    function changeMissingVotesThreshold(uint256 _missingVotesThreshold)
        external
        auth(CHANGE_MISSING_VOTES_THRESHOLD_ROLE)
    {
        missingVotesThreshold = _missingVotesThreshold;
        emit MissingVoteThresholdChanged(_missingVotesThreshold);
    }

    /**
     * @notice Change minimum number of missing votes allowed
     * @param _lockTime number of seconds for which tokens will be locked after distributing reward
     */
    function changeLockTime(uint64 _lockTime) external auth(CHANGE_LOCK_TIME_ROLE) {
        lockTime = _lockTime;
        emit LockTimeChanged(_lockTime);
    }

    /**
     * @notice Change Base Vault
     * @param _baseVault new base vault address
     */
    function changeBaseVaultContractAddress(address _baseVault) external auth(CHANGE_VAULT_ROLE) {
        require(isContract(_baseVault), ERROR_ADDRESS_NOT_CONTRACT);
        baseVault = Vault(_baseVault);
        emit BaseVaultChanged(_baseVault);
    }

    /**
     * @notice Change Reward Vault
     * @param _rewardsVault new reward vault address
     */
    function changeRewardsVaultContractAddress(address _rewardsVault) external auth(CHANGE_VAULT_ROLE) {
        require(isContract(_rewardsVault), ERROR_ADDRESS_NOT_CONTRACT);
        rewardsVault = Vault(_rewardsVault);
        emit RewardsVaultChanged(_rewardsVault);
    }

    /**
     * @notice Change Dandelion Voting contract address
     * @param _dandelionVoting new dandelionVoting address
     */
    function changeDandelionVotingContractAddress(address _dandelionVoting) external auth(CHANGE_VOTING_ROLE) {
        require(isContract(_dandelionVoting), ERROR_ADDRESS_NOT_CONTRACT);
        dandelionVoting = DandelionVoting(_dandelionVoting);
        emit DandelionVotingChanged(_dandelionVoting);
    }

    /**
     * @notice Change percentage rewards
     * @param _percentageRewards new percentage
     * @dev PCT_BASE is the maximun allowed percentage
     */
    function changePercentageRewards(uint256 _percentageRewards) external auth(CHANGE_PERCENTAGE_REWARDS_ROLE) {
        require(_percentageRewards <= PCT_BASE, ERROR_PERCENTAGE_REWARDS);
        percentageRewards = _percentageRewards;
        emit PercentageRewardsChanged(percentageRewards);
    }

    /**
     * @notice Change rewards token
     * @param _rewardsToken new percentage
     */
    function changeRewardsTokenContractAddress(address _rewardsToken) external auth(CHANGE_REWARDS_TOKEN_ROLE) {
        require(isContract(_rewardsToken), ERROR_ADDRESS_NOT_CONTRACT);
        rewardsToken = _rewardsToken;
        emit RewardsTokenChanged(rewardsToken);
    }

    /**
     * @notice Returns all unlocked rewards given an address
     * @param _beneficiary address of which we want to get all rewards
     */
    function getUnlockedRewardsInfo(address _beneficiary) external view returns (Reward[]) {
        Reward[] storage rewards = addressUnlockedRewards[_beneficiary];
        return rewards;
    }

    /**
     * @notice Returns all withdrawan rewards given an address
     * @param _beneficiary address of which we want to get all rewards
     */
    function getWithdrawnRewardsInfo(address _beneficiary) external view returns (Reward[]) {
        Reward[] storage rewards = addressWithdrawnRewards[_beneficiary];
        return rewards;
    }

    /**
     * @notice collect rewards for an address if lockTime is passed since when tokens have been distributed
     * @param _beneficiary address that should be fund with rewards
     * @param _receiver address that will receive the rewards
     * @dev rewardsVault should have TRANSFER_ROLE permission
     */
    function _collectRewardsFor(address _beneficiary, address _receiver) internal returns (bool) {
        uint64 currentBlockNumber = getBlockNumber64();
        Reward[] storage rewards = addressUnlockedRewards[_beneficiary];

        uint256 rewardsLength = rewards.length;
        require(rewardsLength > 0, ERROR_NO_REWARDS);

        uint256 collectedRewardsAmount = 0;
        for (uint256 i = 0; i < rewardsLength; i++) {
            Reward reward = rewards[i];

            if (currentBlockNumber - reward.lockBlock > reward.lockTime && !_isRewardEmpty(reward)) {
                collectedRewardsAmount = collectedRewardsAmount + reward.amount;
                emit RewardCollected(_receiver, reward.amount, reward.lockBlock, reward.lockTime);
                delete rewards[i];
            }
        }

        rewardsVault.transfer(rewardsToken, _receiver, collectedRewardsAmount);
        return true;
    }

    /**
     * @notice Distribute rewards to _beneficiary
     * @param _beneficiary address to which the deposit will be transferred if successful
     * @param _amount corresponding amount for each address
     * @dev baseVault should have TRANSFER_ROLE permission
     */
    function _distributeRewardsTo(
        address _beneficiary,
        uint256 _amount,
        uint64 _lockTime
    ) internal returns (bool) {
        // NOTE: switching to a semi-trusted solution in order to spend less in gas
        // _assignUnlockedReward(_beneficiary, _amount, _lockTime);
        baseVault.transfer(rewardsToken, rewardsVault, _amount);
        emit RewardDistributed(_beneficiary, _amount, _lockTime);
        return true;
    }

    /**
     * @notice distribute rewards for a list of address. Tokens are locked for lockTime in rewardsVault
     * @param _beneficiaries address that are looking for reward
     * @param _amounts corresponding amount for each address
     * @dev baseVault should have TRANSFER_ROLE permission
     */
    function _distributeRewardsToMany(
        address[] _beneficiaries,
        uint256[] _amounts,
        uint64 _lockTime
    ) internal returns (bool) {
        uint256 totalRewardAmount = 0;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            // NOTE: switching to a semi-trusted solution in order to spend less in gas
            // _assignUnlockedReward(_beneficiaries[i], _amounts[i], _lockTime);
            totalRewardAmount = totalRewardAmount.add(_amounts[i]);
            emit RewardDistributed(_beneficiaries[i], _amounts[i], _lockTime);
        }

        baseVault.transfer(rewardsToken, rewardsVault, totalRewardAmount);
        return true;
    }

    /**
     * @notice Check if msg.sender is able to be rewarded, and in positive case,
     *         he will be funded with the corresponding earned amount of tokens
     * @param _beneficiary address to which the deposit will be transferred if successful
     * @param _amount amount
     */
    function _assignUnlockedReward(
        address _beneficiary,
        uint256 _amount,
        uint64 _lockTime
    ) internal returns (bool) {
        Reward[] storage unlockedRewards = addressUnlockedRewards[_beneficiary];

        uint64 currentBlockNumber = getBlockNumber64();
        // prettier-ignore
        uint64 lastBlockDistributedReward = unlockedRewards.length == 0 ? deployBlock : unlockedRewards[unlockedRewards.length - 1].lockBlock;

        // NOTE: avoid double collecting for the same epoch
        require(currentBlockNumber.sub(lastBlockDistributedReward) > epochDuration, ERROR_EPOCH);
        addressUnlockedRewards[_beneficiary].push(Reward(_amount, currentBlockNumber, _lockTime));
        return true;
    }

    /**
     * @notice Check if a Reward is empty
     * @param _reward reward
     */
    function _isRewardEmpty(Reward memory _reward) internal pure returns (bool) {
        return _reward.amount == 0 && _reward.lockBlock == 0 && _reward.lockTime == 0;
    }
}