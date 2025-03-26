// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "./StrudelToken.sol";

// The torchship has brought them to Ganymede, where they have to pulverize boulders and lava flows, and seed the resulting dust with carefully formulated organic material.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once STRDLS is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract TorchShip is Initializable, ContextUpgradeSafe, OwnableUpgradeSafe {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Events
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of STRDLs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accStrudelPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accStrudelPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. STRDLs to distribute per block.
    uint256 lastRewardBlock; // Last block number that STRDLs distribution occurs.
    uint256 accStrudelPerShare; // Accumulated STRDLs per share, times 1e12. See below.
  }

  // immutable
  StrudelToken private strudel;

  // governance params
  // Dev fund
  uint256 public devFundDivRate;
  // last time when total supply of reference token observed
  // formerly bonusEndBlock: Block number when bonus STRDL period ends.
  uint256 public lastBlockHeight;
  // STRDL tokens created per block.
  uint256 public strudelPerBlock;
  // the window size for variance calculation
  // formerly bonusMultiplier: Bonus muliplier for early strudel makers.
  uint256 public windowSize;
  // The block number when STRDL mining starts.
  uint256 public startBlock;

  // working memory
  // Info of each pool.
  PoolInfo[] public poolInfo;
  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  // Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;

  // new since farming 2.0
  address private referenceToken;
  // the number of observations stored during the window
  // immutable
  uint8 public granularity;
  // list of observations as ringbuffer
  uint256[] public observations;
  // position
  uint8 public latestPos;

  function initialize(
    address _strudel,
    uint256 _strudelPerBlock,
    uint256 _startBlock,
    uint256 _lastBlockHeight,
    uint256 _windowSize
  ) public initializer {
    __Ownable_init();
    strudel = StrudelToken(_strudel);
    require(_strudelPerBlock >= 10**15, "forgot the decimals for $TRDL?");
    strudelPerBlock = _strudelPerBlock;
    lastBlockHeight = _lastBlockHeight;
    startBlock = _startBlock;
    windowSize = _windowSize;
    totalAllocPoint = 0;
    devFundDivRate = 17;
  }

  // Safe strudel transfer function, just in case if rounding error causes pool to not have enough STRDLs.
  function safeStrudelTransfer(address _to, uint256 _amount) internal {
    uint256 strudelBal = strudel.balanceOf(address(this));
    if (_amount > strudelBal) {
      strudel.transfer(_to, strudelBal);
    } else {
      strudel.transfer(_to, _amount);
    }
  }

  // update the totalSupply for the observation at the current timestamp. each observation is updated at most
  // once per epoch period.
  function updateVariance() public {
    if (referenceToken == address(0)) {
      return;
    }

    uint256 currentTotal = IERC20(referenceToken).totalSupply();

    // populate the array with empty observations (first call only)
    for (uint256 i = observations.length; i < granularity; i++) {
      observations.push(currentTotal);
    }

    if (block.number.sub(lastBlockHeight) >= windowSize.div(granularity)) {
      uint8 nextPos = (latestPos >= granularity - 1) ? 0 : latestPos + 1;
      observations[nextPos] = currentTotal;
      lastBlockHeight = block.number;
      latestPos = nextPos;
    }
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  // Return reward multiplier over the given _from to _to block.
  function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
    // fallback before not initialized
    if (referenceToken == address(0)) {
      if (_to <= lastBlockHeight) {
        return _to.sub(_from).mul(windowSize).mul(1e18);
      } else if (_from >= lastBlockHeight) {
        return _to.sub(_from).mul(1e18);
      } else {
        return lastBlockHeight.sub(_from).mul(windowSize).add(_to.sub(lastBlockHeight)).mul(1e18);
      }
    }

    uint256 average = 0;
    for (uint256 i = 0; i < granularity; i++) {
      average += observations[i];
    }
    average = average.div(granularity);
    uint256 latestSupply = observations[latestPos];

    // get the variance, normalize over supply
    uint256 variance = latestSupply.sub(average).mul(1e19).div(latestSupply).add(1e18);
    return _to.sub(_from).mul(variance);
  }

  // View function to see pending STRDLs on frontend.
  function pendingStrudel(uint256 _pid, address _user) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accStrudelPerShare = pool.accStrudelPerShare;
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 strudelReward = multiplier
        .mul(strudelPerBlock)
        .mul(pool.allocPoint)
        .div(totalAllocPoint)
        .div(1e18);
      accStrudelPerShare = accStrudelPerShare.add(strudelReward.mul(1e12).div(lpSupply));
    }
    return user.amount.mul(accStrudelPerShare).div(1e12).sub(user.rewardDebt);
  }

  // Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 strudelReward = multiplier
      .mul(strudelPerBlock)
      .mul(pool.allocPoint)
      .div(totalAllocPoint)
      .div(1e18);
    strudel.mint(owner(), strudelReward.div(devFundDivRate));
    strudel.mint(address(this), strudelReward);
    pool.accStrudelPerShare = pool.accStrudelPerShare.add(strudelReward.mul(1e12).div(lpSupply));
    pool.lastRewardBlock = block.number;
  }

  // Deposit LP tokens to TorchShip for STRDL allocation.
  function deposit(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updateVariance();
    updatePool(_pid);
    if (user.amount > 0) {
      uint256 pending = user.amount.mul(pool.accStrudelPerShare).div(1e12).sub(user.rewardDebt);
      safeStrudelTransfer(msg.sender, pending);
    }
    pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.amount.mul(pool.accStrudelPerShare).div(1e12);
    emit Deposit(msg.sender, _pid, _amount);
  }

  // Withdraw LP tokens from TorchShip.
  function withdraw(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "withdraw: not good");
    updateVariance();
    updatePool(_pid);
    uint256 pending = user.amount.mul(pool.accStrudelPerShare).div(1e12).sub(user.rewardDebt);
    safeStrudelTransfer(msg.sender, pending);
    user.amount = user.amount.sub(_amount);
    user.rewardDebt = user.amount.mul(pool.accStrudelPerShare).div(1e12);
    pool.lpToken.safeTransfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    pool.lpToken.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  // governance functions:

  // Add a new lp to the pool. Can only be called by the owner.
  // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  function add(
    uint256 _allocPoint,
    IERC20 _lpToken,
    bool _withUpdate
  ) external onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    poolInfo.push(
      PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accStrudelPerShare: 0
      })
    );
  }

  // Update the given pool's STRDL allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) external onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    poolInfo[_pid].allocPoint = _allocPoint;
  }

  function setDevFundDivRate(uint256 _devFundDivRate) external onlyOwner {
    require(_devFundDivRate > 0, "!devFundDivRate-0");
    devFundDivRate = _devFundDivRate;
  }

  function setStrudelPerBlock(uint256 _strudelPerBlock) external onlyOwner {
    require(_strudelPerBlock > 0, "!strudelPerBlock-0");
    strudelPerBlock = _strudelPerBlock;
  }

  function initVariance(
    address token_,
    uint256 windowSize_,
    uint8 granularity_
  ) external {
    require(referenceToken == address(0), "already initialized");
    require(granularity_ > 1, "TorchShip: GRANULARITY");
    require(windowSize_ % granularity_ == 0, "TorchShip: WINDOW_NOT_EVENLY_DIVISIBLE");
    massUpdatePools();
    referenceToken = token_;
    windowSize = windowSize_;
    granularity = granularity_;
    lastBlockHeight = block.number - (windowSize_ / granularity_);
    updateVariance();
  }
}