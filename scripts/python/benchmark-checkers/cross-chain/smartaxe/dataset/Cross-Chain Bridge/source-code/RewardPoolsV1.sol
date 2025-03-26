// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './token/PoolsInterestBearingToken.sol';
import './token/Bridge.sol';
import './utils/MyPausableUpgradeable.sol';
import 'hardhat/console.sol';
import './interfaces/IBuyBackAndBurn.sol';

interface IBridge is IERC20 {
  function burn(uint256 amount) external;
}

contract RewardPoolsV1 is MyPausableUpgradeable, IPools {
  using SafeERC20 for IERC20;
  using SafeERC20 for IBridge;

  /// contains information about a specific reward pool
  struct RewardPool {
    IERC20 rewardToken; // token the pool is created for
    IERC20 interestBearingToken; // interest token that was created for this reward pool
    uint256 minStakeAmount; // minimum amount that must be staked per account in BRIDGE token
    uint256 maxStakeAmount; // maximum amount that can be staked per account in BRIDGE token
    uint256 maxPoolSize; // max pool size in BRIDGE token
    uint256 totalStakedAmount; // sum of all staked tokens
    uint256 totalRewardAmount; // sum of all rewards ever assigned to this reward pool
    uint256 accRewardPerShare; // the amount of unharvested rewards per share of the staking pool
    uint256 lastRewardAmount; // sum of all rewards in this reward pool from last calculation
    bool exists; // flag to show if this reward pool exists already
  }

  struct StakerInfo {
    uint256 balance; // amount of staked tokens
    uint256 stakeUpdateTime; // timestamp of last update
    uint256 rewardDebt; // a negative reward amount that ensures that harvest cannot be called repeatedly to drain the rewards
    address poolTokenAddress; // the token address of the underlying token of a specific reward pool
  }

  // bridge token that gets distributed by BridgeChef contract
  IBridge private _bridgeToken;

  /// Role for managing this contract
  bytes32 public constant MANAGE_COLLECTED_FEES_ROLE = keccak256('MANAGE_COLLECTED_FEES_ROLE');
  bytes32 public constant MANAGE_REWARD_POOLS_ROLE = keccak256('MANAGE_REWARD_POOLS_ROLE');

  /// stores the reward pool information for each token that is supported by the bridge
  /// tokenAddress to reward pool
  mapping(address => RewardPool) public rewardPools;

  /// Stores current stakings
  /// there is a mapping from user wallet address to StakerInfo for each reward pool
  /// tokenAddress (RewardPool) => Staker wallet address as identifier => StakerInfo
  mapping(address => mapping(address => StakerInfo)) public stakes;

  uint256 public testingUpgradeSafety;

  // Constant that facilitates handling of token fractions
  uint256 private constant _DIV_PRECISION = 1e18;

  /// Contract to receive rewards of pools without stake balance = 0 (for token burns)
  IBuyBackAndBurn public buyBackAndBurnContract;

  /// Default reward pool token withdrawal fee (in ppm: parts per million - 10,000ppm = 1%)
  uint256 public defaultRewardPoolWithdrawalFee;

  /// Individual reward pool withdrawal fees per underlying token (in ppm: parts per million - 10,000ppm = 1%)
  /// tokenAdress => ppm
  mapping(address => uint256) public rewardPoolWithdrawalFees;

  string public constant upgradeSuccessfulDone = 'YES_YES_NO';

  event RewardsAdded(address indexed tokenAddress, uint256 amount);

  event StakeAdded(address indexed accountAddress, address indexed tokenAddress, uint256 amount);

  event StakeWithdrawn(address indexed accountAddress, address indexed tokenAddress, uint256 amount);

  event InterestBearingTokenTransferred(
    address indexed senderAddress,
    address indexed tokenAddress,
    address indexed receiverAddress,
    uint256 amount
  );

  event RewardsHarvested(address indexed staker, address indexed tokenAddress, uint256 amount);

  /**
   * @notice Initializer instead of constructor to have the contract upgradeable
   * @dev can only be called once after deployment of the contract
   */
  function initialize(IBridge bridgeToken, IBuyBackAndBurn _buyBackAndBurnContract) external initializer {
    // call parent initializers
    __MyPausableUpgradeable_init();

    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // initialize required state variables
    _bridgeToken = bridgeToken;
    buyBackAndBurnContract = _buyBackAndBurnContract;
    defaultRewardPoolWithdrawalFee = 300000; // 30%
    require(_bridgeToken.approve(address(buyBackAndBurnContract), type(uint256).max), 'RewardPoolsV1: approval failed');
  }

  /**
   * @notice Sets the default reward pool withdrawal fee (to be paid in Bridge token)
   *
   * @dev can only be called by MANAGE_COLLECTED_FEES_ROLE
   * @param fee the default bridging fee rate provided in ppm: parts per million - 10,000ppm = 1%
   */
  function setDefaultRewardPoolWithdrawalFee(uint256 fee) external {
    require(
      hasRole(MANAGE_COLLECTED_FEES_ROLE, _msgSender()),
      'RewardPoolsV1: must have MANAGE_COLLECTED_FEES_ROLE role to execute this function'
    );
    defaultRewardPoolWithdrawalFee = fee;
  }

  /**
   * @notice Sets an individual reward pool withdrawal fee for the given token
   *
   * @dev can only be called by MANAGE_COLLECTED_FEES_ROLE
   * @param sourceNetworkTokenAddress the address of the underlying token contract
   * @param fee the individual reward pool withdrawal fee rate provided in ppm: parts per million - 10,000ppm = 1%
   */
  function setRewardPoolWithdrawalFee(address sourceNetworkTokenAddress, uint256 fee) external {
    require(
      hasRole(MANAGE_COLLECTED_FEES_ROLE, _msgSender()),
      'RewardPoolsV1: must have MANAGE_COLLECTED_FEES_ROLE role to execute this function'
    );
    require(rewardPools[sourceNetworkTokenAddress].exists, 'RewardPoolsV1: rewardPool does not exist');
    rewardPoolWithdrawalFees[sourceNetworkTokenAddress] = fee;
  }

  /**
   * @notice Sets the minimum stake amount for a specific token
   *
   * @dev can only be called by MANAGE_REWARD_POOLS_ROLE
   * @param tokenAddress the address of the underlying token of the reward pool
   * @param _minStakeAmount the minimum staking amount
   */
  function setMinStakeAmount(address tokenAddress, uint256 _minStakeAmount) external {
    require(
      hasRole(MANAGE_REWARD_POOLS_ROLE, _msgSender()),
      'RewardPoolsV1: must have MANAGE_REWARD_POOLS_ROLE role to execute this function'
    );
    require(rewardPools[tokenAddress].exists, 'RewardPoolsV1: rewardPool does not exist');
    rewardPools[tokenAddress].minStakeAmount = _minStakeAmount;
  }

  /**
   * @notice Sets the maximum stake amount for a specific token
   *
   * @dev can only be called by MANAGE_REWARD_POOLS_ROLE
   * @param tokenAddress the address of the token
   * @param _maxStakeAmount the maximum staking amount
   */
  function setMaxStakeAmount(address tokenAddress, uint256 _maxStakeAmount) external {
    require(
      hasRole(MANAGE_REWARD_POOLS_ROLE, _msgSender()),
      'RewardPoolsV1: must have MANAGE_REWARD_POOLS_ROLE role to execute this function'
    );
    require(rewardPools[tokenAddress].exists, 'RewardPoolsV1: rewardPool does not exist');
    rewardPools[tokenAddress].maxStakeAmount = _maxStakeAmount;
  }

  /**
   * @notice Sets the maximum staking pool size for a specific token
   *
   * @dev can only be called by MANAGE_REWARD_POOLS_ROLE
   * @param tokenAddress the address of the token
   * @param _maxPoolSize the maximum staking pool size
   */
  function setMaxPoolSize(address tokenAddress, uint256 _maxPoolSize) external {
    require(
      hasRole(MANAGE_REWARD_POOLS_ROLE, _msgSender()),
      'RewardPoolsV1: must have MANAGE_REWARD_POOLS_ROLE role to execute this function'
    );
    require(rewardPools[tokenAddress].exists, 'RewardPoolsV1: rewardPool does not exist');
    rewardPools[tokenAddress].maxPoolSize = _maxPoolSize;
  }

  /**
   * @notice Sets the address for the BuyBackAndBurn contract that receives rewards when pools have no stakers
   *
   * @dev can only be called by MANAGE_COLLECTED_FEES_ROLE
   * @param _buyBackAndBurnContract the address of the BuyBackAndBurn contract
   */
  function setBuyBackAndBurnContract(IBuyBackAndBurn _buyBackAndBurnContract) external {
    require(
      hasRole(MANAGE_COLLECTED_FEES_ROLE, _msgSender()),
      'RewardPoolsV1: must have MANAGE_COLLECTED_FEES_ROLE role to execute this function'
    );
    require(
      address(_buyBackAndBurnContract) != address(0),
      'RewardPoolsV1: invalid buyBackAndBurnContract address provided'
    );
    buyBackAndBurnContract = _buyBackAndBurnContract;
    require(_bridgeToken.approve(address(buyBackAndBurnContract), type(uint256).max), 'RewardPoolsV1: approval failed');
  }

  /**
   * @notice Adds new funds (bridge tokens) to the staking pool
   *
   * @param tokenAddress the address of the underlying token of the reward pool
   * @param amount the amount of bridge tokens that should be staked
   * @dev emits event StakeAdded
   */
  function stake(address tokenAddress, uint256 amount) external whenNotPaused nonReentrant {
    // get reward pool for the given token
    RewardPool storage pool = rewardPools[tokenAddress];

    // get info about existing stakings in this token by this user (if any)
    StakerInfo storage staker = stakes[tokenAddress][_msgSender()];

    // check input parameters
    require(amount > 0, 'RewardPoolsV1: staking amount cannot be 0');
    require(rewardPools[tokenAddress].exists, 'RewardPoolsV1: rewardPool does not exist');
    require(amount >= pool.minStakeAmount, 'RewardPoolsV1: staking amount too small');
    require(
      pool.maxStakeAmount == 0 || staker.balance + amount <= pool.maxStakeAmount,
      'RewardPoolsV1: staking amount too high'
    );
    require(
      pool.maxPoolSize == 0 || pool.totalStakedAmount + amount <= pool.maxPoolSize,
      'RewardPoolsV1: max staking pool size exceeded'
    );

    // re-calculate the current rewards and accumulatedRewardsPerShare for this pool
    updateRewards(tokenAddress);

    // check if staking rewards are available for harvesting
    if (staker.balance > 0) {
      _harvest(tokenAddress, _msgSender());
    }

    // Update staker info
    staker.stakeUpdateTime = block.timestamp;
    staker.balance = staker.balance + amount;
    staker.poolTokenAddress = tokenAddress;

    // Assign reward debt in full amount of stake (to prevent that existing rewards can be harvested with the new stake share)
    staker.rewardDebt = (staker.balance * pool.accRewardPerShare) / _DIV_PRECISION;

    // Update total staked amount in reward pool info
    rewardPools[tokenAddress].totalStakedAmount = pool.totalStakedAmount + amount;

    // transfer to-be-staked funds from user to this smart contract
    _bridgeToken.safeTransferFrom(_msgSender(), address(this), amount);

    // Mint interest bearing token to user
    PoolsInterestBearingToken(address(pool.interestBearingToken)).mint(_msgSender(), amount);

    // funds successfully staked - emit new event
    emit StakeAdded(_msgSender(), tokenAddress, amount);
  }

  /**
   * @notice Withdraws staked funds (bridge tokens) from the reward pool after harvesting available rewards, if any
   *
   * @param tokenAddress the address of the underlying token of the reward pool
   * @param amount the amount of bridge tokens that should be unstaked
   * @dev emits event StakeAdded
   */
  function unstake(address tokenAddress, uint256 amount) external whenNotPaused nonReentrant {
    // get reward pool for the given token
    RewardPool storage pool = rewardPools[tokenAddress];

    // get info about existing stakings in this token by this user (if any)
    StakerInfo storage staker = stakes[tokenAddress][_msgSender()];

    // check input parameters
    require(amount > 0, 'RewardPoolsV1: amount to be unstaked cannot be 0');
    require(pool.exists, 'RewardPoolsV1: rewardPool does not exist');
    require(staker.balance >= amount, 'RewardPoolsV1: amount exceeds available balance');
    if (staker.balance - amount != 0) {
      // check if remaining balance is above min stake amount
      require(
        staker.balance - amount >= pool.minStakeAmount,
        'RewardPoolsV1: remaining balance below minimum stake amount'
      );
    }

    // harvest available rewards before unstaking, if any
    _harvest(tokenAddress, _msgSender());

    // Update staker info
    staker.stakeUpdateTime = block.timestamp;
    staker.balance = staker.balance - amount;
    staker.rewardDebt = (staker.balance * pool.accRewardPerShare) / _DIV_PRECISION;

    // // determine the reward pool withdrawal fee (usually the default rate)
    // // if a specific fee rate is stored for this reward pool then we use this rate instead
    uint256 relativeFee = rewardPoolWithdrawalFees[tokenAddress] > 0
      ? rewardPoolWithdrawalFees[tokenAddress]
      : defaultRewardPoolWithdrawalFee;
    uint256 withdrFeeAmount = (amount * relativeFee) / 1000000;

    // burn withdrawal fee
    if (withdrFeeAmount > 0) {
      IBridge(_bridgeToken).burn(withdrFeeAmount);
    }

    // Burn interest bearing token from user
    PoolsInterestBearingToken(address(pool.interestBearingToken)).burn(_msgSender(), amount);

    // transfer bridge tokens back to user
    _bridgeToken.safeTransfer(_msgSender(), amount - withdrFeeAmount);

    // funds successfully unstaked - emit new event
    emit StakeWithdrawn(_msgSender(), tokenAddress, amount - withdrFeeAmount);
  }

  /**
   * @notice Function that is called by the beforeTokenTransfer hook in the PoolsInterestBearingToken to ensure accurate accounting of stakes and rewards
   *
   * @dev can only be called by the PoolsInterestBearingToken contract itself
   * @param tokenAddress the address of the underlying token
   * @param amount the amount of tokens that was transfered
   * @param from the sender of the PoolsInterestBearingToken transfer
   * @param to the recipient of the PoolsInterestBearingToken transfer
   * @dev emits event InterestBearingTokenTransferred
   */
  function transferInterestBearingTokenHandler(
    address tokenAddress,
    uint256 amount,
    address from,
    address to
  ) external override whenNotPaused {
    // check input parameters
    require(
      _msgSender() == address(rewardPools[tokenAddress].interestBearingToken),
      'RewardPoolsV1: function can only be called by PoolsInterestBearingToken'
    );
    require(
      tokenAddress != address(0) && from != address(0) && to != address(0),
      'RewardPoolsV1: invalid address provided'
    );
    require(amount > 0, 'RewardPoolsV1: transfer amount cannot be 0');

    // get reward pool for given token
    RewardPool memory pool = rewardPools[tokenAddress];

    // get staker info for both sender and receiver of the transfer
    StakerInfo storage stakerSender = stakes[tokenAddress][from];
    StakerInfo storage stakerReceiver = stakes[tokenAddress][to];

    // calculate final staking balance of receiver after transfer
    uint256 receiverFinalBalance = stakerReceiver.balance + amount;

    // check reward pool requirements and staker balance
    require(receiverFinalBalance >= pool.minStakeAmount, 'RewardPoolsV1: transfer amount too small');
    require(
      pool.maxStakeAmount == 0 || receiverFinalBalance <= pool.maxStakeAmount,
      'RewardPoolsV1: transfer amount too high'
    );
    require(stakerSender.balance >= amount, 'RewardPoolsV1: insufficient balance for transfer');

    // as preparation for the transfer, any unharvested rewards need to be harvested so that the sender receives his rewards before the transfer
    // update the reward pool calculations (e.g. rewardPerShare)
    updateRewards(tokenAddress);

    // harvest all outstanding rewards for the sender of the token transfer
    _harvest(tokenAddress, from);
    if (stakerReceiver.balance > 0) {
      _harvest(tokenAddress, to);
    }

    // update the time stamps in the staker records
    stakerSender.stakeUpdateTime = block.timestamp;
    stakerReceiver.stakeUpdateTime = block.timestamp;

    // update balances in staker info
    stakerSender.balance = stakerSender.balance - amount;
    stakerReceiver.balance = receiverFinalBalance;

    // calculate the new reward debt for both sender and receiver
    stakerSender.rewardDebt = (stakerSender.balance * pool.accRewardPerShare) / _DIV_PRECISION;
    stakerReceiver.rewardDebt = (receiverFinalBalance * pool.accRewardPerShare) / _DIV_PRECISION;

    emit InterestBearingTokenTransferred(from, tokenAddress, to, amount);
  }

  /**
   * @notice Updates the reward calculations for the given reward pool  (e.g. rewardPerShare)
   *
   * @param tokenAddress the address of the underlying token
   */
  function updateRewards(address tokenAddress) public whenNotPaused {
    // check if amount of unharvested rewards is bigger than last reward amount
    if (rewardPools[tokenAddress].totalRewardAmount > rewardPools[tokenAddress].lastRewardAmount) {
      // check if reward pool has any staked funds
      if (rewardPools[tokenAddress].totalStakedAmount > 0) {
        // calculate new accumulated reward per share
        // new acc. reward per share = current acc. reward per share + (newly accumulated rewards / totalStakedAmount)
        rewardPools[tokenAddress].accRewardPerShare =
          rewardPools[tokenAddress].accRewardPerShare +
          ((rewardPools[tokenAddress].totalRewardAmount - rewardPools[tokenAddress].lastRewardAmount) *
            _DIV_PRECISION) /
          rewardPools[tokenAddress].totalStakedAmount;
      }
      // update last reward amount in reward pool
      rewardPools[tokenAddress].lastRewardAmount = rewardPools[tokenAddress].totalRewardAmount;
    }
  }

  /**
   * @notice Adds additional rewards to a reward pool (e.g. as additional incentive to provide liquidity to this pool)
   *
   * @param token the address of the underlying token of the reward pool (must be an IERC20 contract)
   * @param amount the amount of additional rewards (in the underlying token)
   * @dev emits event RewardsAdded
   */
  function addRewards(IERC20 token, uint256 amount) external whenNotPaused nonReentrant {
    // check input parameters
    require(address(token) != address(0), 'RewardPoolsV1: invalid address provided');

    // check if reward pool for given token exists
    if (!rewardPools[address(token)].exists) {
      // reward pool does not yet exist - create new reward pool
      rewardPools[address(token)] = RewardPool({
        rewardToken: token,
        interestBearingToken: new PoolsInterestBearingToken('Cross-Chain Bridge RP LPs', 'BRIDGE-RP', address(token)),
        minStakeAmount: 1,
        maxStakeAmount: 0,
        maxPoolSize: 0,
        totalStakedAmount: 0,
        totalRewardAmount: 0,
        accRewardPerShare: 0,
        lastRewardAmount: 0,
        exists: true
      });

      // call setRewardPools in PoolsInterestBearingToken to enable the _beforeTokenTransfer hook to work
      PoolsInterestBearingToken(address(rewardPools[address(token)].interestBearingToken)).setPoolsContract(
        address(this)
      );
    }

    // transfer the additional rewards from the sender to this contract
    token.safeTransferFrom(_msgSender(), address(this), amount);

    // Funds that are added to reward pools with totalStakedAmount=0 will be locked forever (as there is no staker to distribute them to)
    // To avoid "lost" funds we will send these funds to our BuyBackAndBurn contract to burn them instead
    // As soon as there is one staker in the pool, funds will be distributed across stakers again
    if (rewardPools[address(token)].totalStakedAmount == 0) {
      // no stakers - send money to buyBackAndBurnContract to burn
      require(token.approve(address(buyBackAndBurnContract), amount), 'RewardPoolsV1: approval failed');
      buyBackAndBurnContract.depositERC20(token, amount);
    } else {
      // update the total reward amount for this reward pool (add the new rewards)
      rewardPools[address(token)].totalRewardAmount = rewardPools[address(token)].totalRewardAmount + amount;
    }

    // additional rewards added successfully, emit event
    emit RewardsAdded(address(token), amount);
  }

  /**
   * @notice Distributes unharvested staking rewards
   *
   * @param tokenAddress the address of the underlying token of the reward pool
   * @param stakerAddress the address for which the unharvested rewards should be distributed
   * @dev emits event RewardsHarvested
   */
  function harvest(address tokenAddress, address stakerAddress) external whenNotPaused nonReentrant {
    _harvest(tokenAddress, stakerAddress);
  }

  /**
   * @notice Private function that allows calls from other functions despite nonReentrant modifier
   * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
   */
  function _harvest(address tokenAddress, address stakerAddress) private whenNotPaused {
    // get staker info and check if such a record exists
    StakerInfo storage staker = stakes[tokenAddress][stakerAddress];
    require(staker.balance > 0, 'RewardPoolsV1: Staker has a balance of 0');

    // update the reward pool calculations (e.g. rewardPerShare)
    updateRewards(tokenAddress);

    // calculate reward amount
    uint256 accumulated = (staker.balance * rewardPools[staker.poolTokenAddress].accRewardPerShare) / _DIV_PRECISION;
    uint256 rewardAmount = uint256(accumulated - staker.rewardDebt);

    // Save the current share of the pool as reward debt to prevent a staker from harvesting again (similar to re-entry attack)
    staker.rewardDebt = accumulated;

    if (rewardAmount > 0) {
      // safely transfer the reward amount to the staker address
      rewardPools[tokenAddress].rewardToken.safeTransfer(stakerAddress, rewardAmount);

      // successfully harvested, emit event
      emit RewardsHarvested(stakerAddress, tokenAddress, rewardAmount);
    }
  }

  /**
   * @notice Provides information about how much unharvested reward is available for a specific stake(r) in a reward pool
   *
   * @dev we recommend to call function updateRewards(address tokenAddress) first to update the reward calculations
   * @param tokenAddress the address of the underlying token of the reward pool
   * @param stakerAddress the address of the staker for which pending rewards should be returned
   * @return the unharvested reward amount
   */
  function pendingReward(address tokenAddress, address stakerAddress) external view returns (uint256) {
    // get reward pool to check rewards for
    RewardPool memory pool = rewardPools[tokenAddress];
    // get staker info and check if such a record exists
    StakerInfo memory staker = stakes[tokenAddress][stakerAddress];
    if (staker.balance == 0) {
      return 0;
    }

    uint256 accRewardPerShare = pool.accRewardPerShare +
      ((pool.totalRewardAmount - pool.lastRewardAmount) * _DIV_PRECISION) /
      pool.totalStakedAmount;

    // calculate the amount of rewards that the sender is eligible for through his/her stake
    uint256 accumulated = (staker.balance * accRewardPerShare) / _DIV_PRECISION;

    return uint256(accumulated - staker.rewardDebt);
  }
}