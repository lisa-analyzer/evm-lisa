// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './token/PoolsInterestBearingToken.sol';
import './interfaces/ICrossChainBridgeERC20.sol';
import './interfaces/IBuyBackAndBurn.sol';
import './utils/MyPausableUpgradeable.sol';
import './interfaces/ICrossChainBridgeERC20LiquidityManager.sol';
import 'hardhat/console.sol';

contract LiquidityMiningPoolsV1 is MyPausableUpgradeable, IPools {
  using SafeERC20 for IERC20;

  /// contains information about a specific liquidity mining pool
  struct LiquidityMiningPool {
    IERC20 baseLpToken; // base token the pool is created for (stake this token)
    IERC20 rewardToken; // reward token the pool is created for (get this token)
    IERC20 interestBearingToken; // interest token that was created for this liquidity mining pool (your receipt)
    uint256 minStakeAmount; // minimum amount that must be staked per account in BRIDGE token
    uint256 maxStakeAmount; // maximum amount that can be staked per account in BRIDGE token
    uint256 maxPoolSize; // max pool size in Base LP token
    uint256 totalStakedAmount; // sum of all staked tokens
    uint256 totalRewardAmount; // sum of all rewards ever assigned to this liquidity mining pool
    uint256 accRewardPerShare; // the amount of unharvested rewards per share of the staking pool
    uint256 lastRewardAmount; // sum of all rewards in this liquidity mining pool from last calculation
    bool exists; // flag to show if this liquidity mining pool exists already
  }

  struct StakerInfo {
    uint256 balance; // amount of staked tokens
    uint256 stakeUpdateTime; // timestamp of last update
    uint256 rewardDebt; // a negative reward amount that ensures that harvest cannot be called repeatedly to drain the rewards
    address poolTokenAddress; // the token address of the underlying token of a specific liquidity mining pool
  }

  // Role for managing this contract
  bytes32 public constant MANAGE_COLLECTED_FEES_ROLE = keccak256('MANAGE_COLLECTED_FEES_ROLE');
  bytes32 public constant MANAGE_MINING_POOLS_ROLE = keccak256('MANAGE_MINING_POOLS_ROLE');
  bytes32 public constant MANAGE_CONTRACTS_ROLE = keccak256('MANAGE_CONTRACTS_ROLE');
  bytes32 public constant MANAGE_LIQUIDITY_MANAGER_ROLE = keccak256('MANAGE_LIQUIDITY_MANAGER_ROLE');

  // stores the liquidity mining pool information for each token that is supported by the bridge
  // tokenAddress to liquidity mining pool
  mapping(address => LiquidityMiningPool) public liquidityMiningPools;

  // Stores current stakings
  // there is a mapping from user wallet address to StakerInfo for each liquidity mining pool
  // tokenAddress (LiquidityMiningPool) => Staker wallet address as identifier => StakerInfo
  mapping(address => mapping(address => StakerInfo)) public stakes;

  uint256 private constant _DIV_PRECISION = 1e18;

  // Contract to receive rewards of pools without stake balance = 0 (for token burns)
  IBuyBackAndBurn public buyBackAndBurnContract;

  /// address of the contract that manages liquidity for the ERC20 bridge
  ICrossChainBridgeERC20LiquidityManager public liquidityManager;

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
  function initialize(IBuyBackAndBurn _buyBackAndBurnContract) external initializer {
    // call parent initializers
    __MyPausableUpgradeable_init();

    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // initialize required state variables
    buyBackAndBurnContract = _buyBackAndBurnContract;
  }

  /**
   * @notice Sets the contract address for the ERC20 bridge liquidity manager
   *
   * @dev can only be called by MANAGE_LIQUIDITY_MANAGER_ROLE
   * @param contractAddress the address of the liquidity manager contract
   */
  function setCrossChainBridgeERC20LiquidityManager(ICrossChainBridgeERC20LiquidityManager contractAddress) external {
    require(
      hasRole(MANAGE_LIQUIDITY_MANAGER_ROLE, _msgSender()),
      'LiquidityMiningPoolsV1: must have MANAGE_LIQUIDITY_MANAGER_ROLE role to execute this function'
    );
    require(address(contractAddress) != address(0), 'RewardPoolsV1: invalid address provided');
    liquidityManager = contractAddress;
  }

  /**
   * @notice Sets the minimum stake amount for a specific token
   *
   * @dev can only be called by MANAGE_MINING_POOLS_ROLE
   * @param tokenAddress the address of the underlying token of the liquidity mining pool
   * @param _minStakeAmount the minimum staking amount
   */
  function setMinStakeAmount(address tokenAddress, uint256 _minStakeAmount) external {
    require(
      hasRole(MANAGE_MINING_POOLS_ROLE, _msgSender()),
      'LiquidityMiningPoolsV1: must have MANAGE_MINING_POOLS_ROLE role to execute this function'
    );
    require(liquidityMiningPools[tokenAddress].exists, 'LiquidityMiningPoolsV1: liquidityMiningPool does not exist');
    liquidityMiningPools[tokenAddress].minStakeAmount = _minStakeAmount;
  }

  /**
   * @notice Sets the maximum stake amount for a specific token
   *
   * @dev can only be called by MANAGE_MINING_POOLS_ROLE
   * @param tokenAddress the address of the token
   * @param _maxStakeAmount the maximum staking amount
   */
  function setMaxStakeAmount(address tokenAddress, uint256 _maxStakeAmount) external {
    require(
      hasRole(MANAGE_MINING_POOLS_ROLE, _msgSender()),
      'LiquidityMiningPoolsV1: must have MANAGE_MINING_POOLS_ROLE role to execute this function'
    );
    require(liquidityMiningPools[tokenAddress].exists, 'LiquidityMiningPoolsV1: liquidityMiningPool does not exist');
    liquidityMiningPools[tokenAddress].maxStakeAmount = _maxStakeAmount;
  }

  /**
   * @notice Sets the maximum staking pool size for a specific token
   *
   * @dev can only be called by MANAGE_MINING_POOLS_ROLE
   * @param tokenAddress the address of the token
   * @param _maxPoolSize the maximum staking pool size
   */
  function setMaxPoolSize(address tokenAddress, uint256 _maxPoolSize) external {
    require(
      hasRole(MANAGE_MINING_POOLS_ROLE, _msgSender()),
      'LiquidityMiningPoolsV1: must have MANAGE_MINING_POOLS_ROLE role to execute this function'
    );
    require(liquidityMiningPools[tokenAddress].exists, 'LiquidityMiningPoolsV1: liquidityMiningPool does not exist');
    liquidityMiningPools[tokenAddress].maxPoolSize = _maxPoolSize;
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
      'LiquidityMiningPoolsV1: must have MANAGE_COLLECTED_FEES_ROLE role to execute this function'
    );
    require(
      address(_buyBackAndBurnContract) != address(0),
      'RewardPoolsV1: invalid buyBackAndBurnContract address provided'
    );
    buyBackAndBurnContract = _buyBackAndBurnContract;
  }

  /**
   * @notice Adds new funds (LP tokens) to the liquidity mining pool of the given token
   *
   * @param tokenAddress the address of the underlying token of the pool
   * @param amount the amount of LP tokens that should be staked
   * @dev emits event StakeAdded
   */
  function stake(address tokenAddress, uint256 amount) external whenNotPaused nonReentrant {
    // get liquidity mining pool for the given token
    LiquidityMiningPool storage pool = liquidityMiningPools[tokenAddress];

    // get info about existing stakings in this token by this user (if any)
    StakerInfo storage staker = stakes[tokenAddress][_msgSender()];

    // check input parameters
    require(amount > 0, 'LiquidityMiningPoolsV1: staking amount cannot be 0');
    require(liquidityMiningPools[tokenAddress].exists, 'LiquidityMiningPoolsV1: liquidityMiningPool does not exist');
    require(amount >= pool.minStakeAmount, 'LiquidityMiningPoolsV1: staking amount too small');
    require(
      pool.maxStakeAmount == 0 || staker.balance + amount <= pool.maxStakeAmount,
      'LiquidityMiningPoolsV1: staking amount too high'
    );
    require(
      pool.maxPoolSize == 0 || pool.totalStakedAmount + amount <= pool.maxPoolSize,
      'LiquidityMiningPoolsV1: max staking pool size exceeded'
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

    // Update total staked amount in liquidity mining pool info
    liquidityMiningPools[tokenAddress].totalStakedAmount = pool.totalStakedAmount + amount;

    // transfer to-be-staked funds from user to this smart contract
    pool.baseLpToken.safeTransferFrom(_msgSender(), address(this), amount);

    // Mint interest bearing token to user
    PoolsInterestBearingToken(address(pool.interestBearingToken)).mint(_msgSender(), amount);

    // funds successfully staked - emit new event
    emit StakeAdded(_msgSender(), tokenAddress, amount);
  }

  /**
   * @notice Withdraws staked funds (LP tokens) from the liquidity mining pool after harvesting available rewards, if any
   *
   * @param tokenAddress the address of the underlying token of the liquidity mining pool
   * @param amount the amount of bridge tokens that should be unstaked
   * @dev emits event StakeAdded
   */
  function unstake(address tokenAddress, uint256 amount) external whenNotPaused nonReentrant {
    // get liquidity mining pool for the given token
    LiquidityMiningPool storage pool = liquidityMiningPools[tokenAddress];

    // get info about existing stakings in this token by this user (if any)
    StakerInfo storage staker = stakes[tokenAddress][_msgSender()];

    // check input parameters
    require(amount > 0, 'LiquidityMiningPoolsV1: amount to be unstaked cannot be 0');
    require(pool.exists, 'LiquidityMiningPoolsV1: liquidityMiningPool does not exist');
    require(staker.balance >= amount, 'LiquidityMiningPoolsV1: amount exceeds available balance');
    if (staker.balance - amount != 0) {
      // check if remaining balance is above min stake amount
      require(
        staker.balance - amount >= pool.minStakeAmount,
        'LiquidityMiningPoolsV1: remaining balance below minimum stake amount'
      );
    }

    // harvest available rewards before unstaking, if any
    _harvest(tokenAddress, _msgSender());

    // Update staker info
    staker.stakeUpdateTime = block.timestamp;
    staker.balance = staker.balance - amount;
    staker.rewardDebt = (staker.balance * pool.accRewardPerShare) / _DIV_PRECISION;

    // Burn interest bearing token from user
    PoolsInterestBearingToken(address(pool.interestBearingToken)).burn(_msgSender(), amount);

    // transfer LP tokens back to user
    pool.baseLpToken.safeTransfer(_msgSender(), amount);

    // funds successfully unstaked - emit new event
    emit StakeWithdrawn(_msgSender(), tokenAddress, amount);
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
      _msgSender() == address(liquidityMiningPools[tokenAddress].interestBearingToken),
      'LiquidityMiningPoolsV1: function can only be called by PoolsInterestBearingToken'
    );
    require(
      tokenAddress != address(0) && from != address(0) && to != address(0),
      'LiquidityMiningPoolsV1: invalid address provided'
    );
    require(amount > 0, 'LiquidityMiningPoolsV1: transfer amount cannot be 0');

    // get liquidity mining pool for given token
    LiquidityMiningPool memory pool = liquidityMiningPools[tokenAddress];

    // get staker info for both sender and receiver of the transfer
    StakerInfo storage stakerSender = stakes[tokenAddress][from];
    StakerInfo storage stakerReceiver = stakes[tokenAddress][to];

    // calculate final staking balance of receiver after transfer
    uint256 receiverFinalBalance = stakerReceiver.balance + amount;

    // check liquidity mining pool requirements and staker balance
    require(receiverFinalBalance >= pool.minStakeAmount, 'LiquidityMiningPoolsV1: transfer amount too small');
    require(
      pool.maxStakeAmount == 0 || receiverFinalBalance <= pool.maxStakeAmount,
      'LiquidityMiningPoolsV1: transfer amount too high'
    );
    require(stakerSender.balance >= amount, 'LiquidityMiningPoolsV1: insufficient balance for transfer');

    // as preparation for the transfer, any unharvested rewards need to be harvested so that the sender receives his rewards before the transfer
    // update the liquidity mining pool calculations (e.g. rewardPerShare)
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
   * @notice Updates the reward calculations for the given liquidity mining pool  (e.g. rewardPerShare)
   *
   * @param tokenAddress the address of the underlying token
   */
  function updateRewards(address tokenAddress) public whenNotPaused {
    // check if amount of unharvested rewards is bigger than last reward amount
    if (liquidityMiningPools[tokenAddress].totalRewardAmount > liquidityMiningPools[tokenAddress].lastRewardAmount) {
      // check if liquidity mining pool has any staked funds
      if (liquidityMiningPools[tokenAddress].totalStakedAmount > 0) {
        // calculate new accumulated reward per share
        // new acc. reward per share = current acc. reward per share + (newly accumulated rewards / totalStakedAmount)
        liquidityMiningPools[tokenAddress].accRewardPerShare =
          liquidityMiningPools[tokenAddress].accRewardPerShare +
          ((liquidityMiningPools[tokenAddress].totalRewardAmount -
            liquidityMiningPools[tokenAddress].lastRewardAmount) * _DIV_PRECISION) /
          liquidityMiningPools[tokenAddress].totalStakedAmount;
      }
      // update last reward amount in liquidity mining pool
      liquidityMiningPools[tokenAddress].lastRewardAmount = liquidityMiningPools[tokenAddress].totalRewardAmount;
    }
  }

  /**
   * @notice Adds additional rewards to a liquidity mining pool, or creates it if it does not exist yet
   *
   * @param token the address of the underlying token of the liquidity mining pool (must be an IERC20 contract)
   * @param amount the amount of additional rewards (in the underlying token)
   * @dev emits event RewardsAdded
   */
  function addRewards(IERC20 token, uint256 amount) external whenNotPaused nonReentrant {
    // check input parameters
    require(address(token) != address(0), 'LiquidityMiningPoolsV1: invalid token address provided');

    // get LP token for the given token
    (, IERC20 lpToken) = liquidityManager.lpTokens(address(token));
    require(address(lpToken) != address(0), 'LiquidityMiningPoolsV1: could not find LP token for this token');

    // check if liquidity mining pool for given token exists
    if (!liquidityMiningPools[address(token)].exists) {
      // liquidity mining pool does not yet exist - create new liquidity mining pool
      liquidityMiningPools[address(token)] = LiquidityMiningPool({
        baseLpToken: lpToken,
        rewardToken: token,
        interestBearingToken: new PoolsInterestBearingToken('Cross-Chain Bridge LM LPs', 'Bridge-LM', address(token)),
        minStakeAmount: 1,
        maxStakeAmount: 0,
        maxPoolSize: 0,
        totalStakedAmount: 0,
        totalRewardAmount: 0,
        accRewardPerShare: 0,
        lastRewardAmount: 0,
        exists: true
      });

      // call setPoolsContract in PoolsInterestBearingToken to enable the _beforeTokenTransfer hook to work
      PoolsInterestBearingToken(address(liquidityMiningPools[address(token)].interestBearingToken)).setPoolsContract(
        address(this)
      );
    }

    // transfer the additional rewards from the sender to this contract
    token.safeTransferFrom(_msgSender(), address(this), amount);

    // Funds that are added to liquidity mining pools with totalStakedAmount=0 will be locked forever (as there is no staker to distribute them to)
    // To avoid "lost" funds we will send these funds to our BuyBackAndBurn contract to burn them instead
    // As soon as there is one staker in the pool, funds will be distributed across stakers again
    if (liquidityMiningPools[address(token)].totalStakedAmount == 0) {
      // no stakers - send money to buyBackAndBurnContract to burn
      require(token.approve(address(buyBackAndBurnContract), amount), 'LiquidityMiningPoolsV1: approval failed');
      buyBackAndBurnContract.depositERC20(token, amount);
    } else {
      // update the total reward amount for this liquidity mining pool (add the new rewards)
      liquidityMiningPools[address(token)].totalRewardAmount =
        liquidityMiningPools[address(token)].totalRewardAmount +
        amount;
    }

    // additional rewards added successfully, emit event
    emit RewardsAdded(address(token), amount);
  }

  /**
   * @notice Distributes unharvested staking rewards
   *
   * @param tokenAddress the address of the underlying token of the liquidity mining pool
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
    require(staker.balance > 0, 'LiquidityMiningPoolsV1: Staker has a balance of 0');

    // update the liquidity mining pool calculations (e.g. rewardPerShare)
    updateRewards(tokenAddress);

    // calculate reward amount
    uint256 accumulated = (staker.balance * liquidityMiningPools[staker.poolTokenAddress].accRewardPerShare) /
      _DIV_PRECISION;
    uint256 rewardAmount = uint256(accumulated - staker.rewardDebt);

    // Save the current share of the pool as reward debt to prevent a staker from harvesting again (similar to re-entry attack)
    staker.rewardDebt = accumulated;

    if (rewardAmount > 0) {
      // safely transfer the reward amount to the staker address
      liquidityMiningPools[tokenAddress].rewardToken.safeTransfer(stakerAddress, rewardAmount);

      // successfully harvested, emit event
      emit RewardsHarvested(stakerAddress, tokenAddress, rewardAmount);
    }
  }

  /**
   * @notice Provides information about how much unharvested reward is available for a specific stake(r) in a liquidity mining pool
   *
   * @dev we recommend to call function updateRewards(address tokenAddress) first to update the reward calculations
   * @param tokenAddress the address of the underlying token of the liquidity mining pool
   * @param stakerAddress the address of the staker for which pending rewards should be returned
   * @return the unharvested reward amount
   */
  function pendingReward(address tokenAddress, address stakerAddress) external view returns (uint256) {
    // get liquidity mining pool to check rewards for
    LiquidityMiningPool memory pool = liquidityMiningPools[tokenAddress];
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