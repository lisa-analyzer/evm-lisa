// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import './interfaces/IBuyBackAndBurn.sol';
import './interfaces/ICrossChainBridgeERC20LiquidityManager.sol';
import './interfaces/ICrossChainBridgeERC20.sol';
import './interfaces/IMultiSignatureOracle.sol';
import './interfaces/INativeToken.sol';
import './token/MintableERC20.sol';
import './utils/MyPausableUpgradeable.sol';
import 'hardhat/console.sol';

/**
 * @title CrossChainBridgeERC20LiquidityManager
 * Handles everything related to providing and removing liquidity for the ERC20 bridge
 */
contract CrossChainBridgeERC20LiquidityManager is MyPausableUpgradeable, ICrossChainBridgeERC20LiquidityManager {
  using SafeERC20 for IERC20;

  // Roles
  bytes32 public constant MANAGE_MAX_POOL_SIZE_ROLE = keccak256('MANAGE_MAX_POOL_SIZE_ROLE');
  bytes32 public constant MANAGE_COLLECTED_FEES_ROLE = keccak256('MANAGE_COLLECTED_FEES_ROLE');
  bytes32 public constant MANAGE_FEES_ROLE = keccak256('MANAGE_FEES_ROLE');
  bytes32 public constant MANAGE_CONNECTIONS_ROLE = keccak256('MANAGE_CONNECTIONS_ROLE');
  bytes32 public constant MANAGE_TOKEN_ROLE = keccak256('MANAGE_TOKEN_ROLE');

  event LiquidityPoolCreated(address indexed sourceNetworkTokenAddress, address indexed lpTokenAddress);

  event LiquidityAdded(address indexed sourceNetworkTokenAddress, uint256 amount, address indexed lpTokenAddress);

  event LiquidityRemoved(address indexed sourceNetworkTokenAddress, uint256 amount);

  event MaxPoolSizeUpdated(address indexed tokenAddress, uint256 maxSize);

  struct LPToken {
    bool exists;
    IERC20 token;
  }

  /// Default liquidity withdrawal fee (in ppm: parts per million - 10,000ppm = 1%)
  uint256 public override defaultLiquidityWithdrawalFee;

  /// Individual liquidity withdrawal fees per supported token (in ppm: parts per million - 10,000ppm = 1%)
  /// tokenAddress => ppm
  mapping(address => uint256) public override liquidityWithdrawalFees;

  /// A mapping from token address in source network to lpToken
  /// sourceNetworkTokenAddress => lpToken
  mapping(address => LPToken) public override lpTokens;

  /// Individual max pool size per supported token
  /// tokenAddressInThisNetwork => max pool size
  mapping(address => uint256) public maxPoolSize;

  /// the contract address of the wrapped native token in the network this contract is deployed in (e.g. WETH, WBNB)
  INativeToken public wrappedNative;

  /// wallet to collect funds for further development of the cross-chain bridge
  address public devAddr;

  /// address of the ERC20 cross-chain bridge contract
  ICrossChainBridgeERC20 public bridgeERC20;

  /**
   * @notice Initializer instead of constructor to have the contract upgradable
   *
   * @param _bridgeERC20 the address of the ERC20 cross chain bridge
   * @param _wrappedNative the address of a/the wrapped native token in this network
   * @dev can only be called once after deployment of the contract
   */
  function initialize(ICrossChainBridgeERC20 _bridgeERC20, INativeToken _wrappedNative) external initializer {
    // call parent initializers
    __MyPausableUpgradeable_init();

    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // initialize required state variables
    defaultLiquidityWithdrawalFee = 2000; // 0.2%
    bridgeERC20 = _bridgeERC20;
    wrappedNative = _wrappedNative;
  }

  /**
   * @notice Adds native liquidity to an existing pool or creates a new one, if it does not exist yet
   *
   * @param amount the amount of native tokens to be added
   * @dev emits event LiquidityPoolCreated (only if a new pool is created)
   * @dev emits event LiquidityAdded after successful deposit
   */
  function addLiquidityNative(uint256 amount) external payable override nonReentrant {
    // check input parameters
    require(amount == msg.value, 'LiquidityManager: msg.value did not match amount');

    // check native token balance before call
    uint256 contractBalance = wrappedNative.balanceOf(address(this));

    // swap native to wrapped native ERC20 token
    wrappedNative.deposit{value: msg.value}();

    // check if wrapped native token balance has increased by deposit amount
    require(
      wrappedNative.balanceOf(address(this)) == contractBalance + amount,
      'LiquidityManager: error while wrapping native tokens'
    );

    // Transfer ERC20 tokens from this contract to ERC20bridge
    IERC20(wrappedNative).safeTransfer(address(bridgeERC20), amount);

    // call addLiquidityERC20 function with wrapped native token
    _addLiquidityERC20(wrappedNative, amount);

    // transfer LP tokens from this contract to msg.sender to complete the transaction
    lpTokens[address(wrappedNative)].token.safeTransfer(_msgSender(), amount);
  }

  /**
   * @notice Adds ERC20 liquidity to an existing pool or creates a new one, if none exists for the provided token
   *         Public interface to this function including reentrancy guard
   *
   * @param token the token for which liquidity should be added
   * @param amount the amount of tokens to be added
   * @dev emits event LiquidityPoolCreated (only if a new pool is created)
   * @dev emits event LiquidityAdded after successful deposit
   */
  function addLiquidityERC20(IERC20 token, uint256 amount) external override nonReentrant {
    // check ERC20 bridge token balance before deposit
    uint256 balanceBefore = token.balanceOf(address(bridgeERC20));

    // Transfer token amount from sender to ERC20bridge
    token.safeTransferFrom(_msgSender(), address(bridgeERC20), amount);

    // check if ERC20 bridge token balance has increased by amount (>> effectively preventing deflationary tokens to be added for now)
    require(
      token.balanceOf(address(bridgeERC20)) == balanceBefore + amount,
      'LiquidityManager: deposited token amount incorrect'
    );

    // call internal function to mint LP tokens and emit event
    _addLiquidityERC20(token, amount);

    // forward the minted LP tokens to msg_sender()
    IERC20(address(lpTokens[address(token)].token)).safeTransfer(_msgSender(), amount);
  }

  /**
   * @notice Adds ERC20 liquidity to an existing pool or creates a new one, if none exists for the provided token
   *         Private interface to this function without reentrancy guard
   *
   * @param token the token for which liquidity should be added
   * @param amount the amount of tokens to be added
   * @dev emits event LiquidityPoolCreated (only if a new pool is created)
   * @dev emits event LiquidityAdded after successful deposit
   */
  function _addLiquidityERC20(IERC20 token, uint256 amount) private whenNotPaused {
    require(amount > 0, 'LiquidityManager: amount cannot be 0');

    // create liquidity pool and LP token, if not existing already
    if (!lpTokens[address(token)].exists) {
      // LP token does not exist yet and needs to be created
      _createPool(address(token));
    }

    // check if existing + new liquidity is within maxPoolSize limit
    require(
      maxPoolSize[address(token)] == 0 || token.balanceOf(address(bridgeERC20)) <= maxPoolSize[address(token)],
      'LiquidityManager: max pool size reached'
    );

    // mint LP tokens in the amount of tokens that were supplied as liquidity to this contract
    MintableERC20(address(lpTokens[address(token)].token)).mint(address(this), amount);

    emit LiquidityAdded(address(token), amount, address(lpTokens[address(token)].token));
  }

  /**
   * @notice Removes native liquidity from a pool (i.e. in the network-native token)
   *
   * @param withdrawalAmount the amount of liquidity to be removed
   * @dev emits event LiquidityRemoved
   */
  function withdrawLiquidityNative(uint256 withdrawalAmount) external override nonReentrant {
    // check if liquidity is sufficient
    require(
      wrappedNative.balanceOf(address(bridgeERC20)) >= withdrawalAmount,
      'LiquidityManager: not enough liquidity'
    );

    // transfer LP tokens from msgSender to this contract
    lpTokens[address(wrappedNative)].token.safeTransferFrom(_msgSender(), address(this), withdrawalAmount);

    // check wrapped native token balance before ERC20 withdrawal
    uint256 contractBalance = wrappedNative.balanceOf(address(this));

    // withdraw ERC20 liquidity from bridge
    uint256 withdrawalAmountAfterFees = _withdrawLiquidityERC20(wrappedNative, withdrawalAmount);

    // transfer ERC20 tokens (minus fees) from bridge to this contract
    IERC20(wrappedNative).safeTransferFrom(address(bridgeERC20), address(this), withdrawalAmountAfterFees);

    // check wrapped native token balance after ERC20 withdrawal
    require(
      wrappedNative.balanceOf(address(this)) == contractBalance + withdrawalAmountAfterFees,
      'LiquidityManager error while withdrawing ERC20 tokens'
    );

    // check native token balance before call
    contractBalance = address(this).balance;

    // swap wrapped native ERC20 token back to native token
    wrappedNative.withdraw(withdrawalAmountAfterFees);

    // check if native token balance has increased by withdraw amount
    require(
      address(this).balance == contractBalance + withdrawalAmountAfterFees,
      'LiquidityManager: error while unwrapping native tokens'
    );

    // send native token back to user
    payable(_msgSender()).transfer(withdrawalAmountAfterFees);
  }

  /**
     * @notice Removes ERC20 liquidity from a pool
               Public interface to this function with reentrancy guard
     *
     * @param token the token for which liquidity should be removed from this pool
     * @dev emits event LiquidityRemoved
     */
  function withdrawLiquidityERC20(IERC20 token, uint256 amount) external override nonReentrant {
    // burn LP token in the amount of liquidity that should be removed
    ERC20Burnable(address(lpTokens[address(token)].token)).burnFrom(_msgSender(), amount);
    // call internal function to calculate fee and emit event
    uint256 withdrawalAmount = _withdrawLiquidityERC20(token, amount);

    // safely transfer token amount minus fees to the sender
    token.safeTransferFrom(address(bridgeERC20), _msgSender(), withdrawalAmount);
  }

  /**
   * @notice Removes ERC20 liquidity from a pool
   *         Private interface to this function which allows internal calls from reentrancy guard protected functions
   *
   * @param token the token for which liquidity should be removed from this pool
   * @param amount the amount of liquidity to be removed
   * @dev emits event LiquidityRemoved
   */
  function _withdrawLiquidityERC20(IERC20 token, uint256 amount)
    private
    whenNotPaused
    returns (uint256 withdrawalAmount)
  {
    require(amount > 0, 'LiquidityManager: amount cannot be 0');

    // check if liquidity is sufficient for withdrawal
    require(token.balanceOf(address(bridgeERC20)) >= amount, 'LiquidityManager: not enough liquidity in bridge');

    // determine the fee rate to be used for this transaction (usually default liquidity withdrawal fee)
    uint256 liquidityWithdrawalFee = defaultLiquidityWithdrawalFee;
    // if a specific fee rate is stored for this particular release token then we use this rate instead
    if (liquidityWithdrawalFees[address(token)] > 0) {
      liquidityWithdrawalFee = liquidityWithdrawalFees[address(token)];
    }

    // calculate the fee amounts (dividing by 1.000.000 since the fee rate is provided as parts per million [ppm])
    // calculate the total fee amount for this transaction
    uint256 withdrawalFeeAmount = (amount * liquidityWithdrawalFee) / 1000000;
    // calculate the remaining amount that will be released to the user
    withdrawalAmount = amount - withdrawalFeeAmount;

    // transfer developer account fee, if applicable
    if (devAddr != address(0) && withdrawalFeeAmount > 0) {
      token.safeTransferFrom(address(bridgeERC20), devAddr, withdrawalFeeAmount);
    }

    emit LiquidityRemoved(address(token), withdrawalAmount);
  }

  /**
   * @notice Sets the default liquidity withdrawal fee
   *
   * @dev can only be called by MANAGE_FEES_ROLE
   * @param fee the default bridging fee rate provided in ppm: parts per million - 10,000ppm = 1%
   */
  function setDefaultLiquidityWithdrawalFee(uint256 fee) external {
    require(
      hasRole(MANAGE_FEES_ROLE, _msgSender()),
      'LiquidityManager: must have MANAGE_FEES_ROLE to execute this function'
    );
    defaultLiquidityWithdrawalFee = fee;
  }

  /**
   * @notice Sets an individual liquidity withdrawal fee for the provided token
   *
   * @dev can only be called by MANAGE_FEES_ROLE
   * @param sourceNetworkTokenAddress the address of the token contract
   * @param fee the individual liquidity withdrawal fee rate provided in ppm: parts per million - 10,000ppm = 1%
   */
  function setLiquidityWithdrawalFee(address sourceNetworkTokenAddress, uint256 fee) external {
    require(
      hasRole(MANAGE_FEES_ROLE, _msgSender()),
      'LiquidityManager: must have MANAGE_FEES_ROLE to execute this function'
    );
    liquidityWithdrawalFees[sourceNetworkTokenAddress] = fee;
  }

  /**
   * @notice Sets the max pool size of a liquidity pool for the provided token
   *
   * @dev can only be called by MANAGE_MAX_POOL_SIZE_ROLE
   * @param tokenAddress the address of the token contract
   * @param maxSize the max size of a liqui pool for a specific token
   * @dev emits event MaxPoolSizeUpdated
   */
  function setMaxPoolSize(address tokenAddress, uint256 maxSize) external {
    require(
      hasRole(MANAGE_MAX_POOL_SIZE_ROLE, _msgSender()),
      'LiquidityManager: must have MANAGE_MAX_POOL_SIZE_ROLE to execute this function'
    );
    maxPoolSize[tokenAddress] = maxSize;
    emit MaxPoolSizeUpdated(tokenAddress, maxSize);
  }

  /**
   * @notice Sets the wallet address to receive funds for further development of this bridge
   *
   * @dev can only be called by MANAGE_COLLECTED_FEES_ROLE
   * @param devAddress the address of the developer wallet
   */
  function setDevAddress(address devAddress) external {
    require(
      hasRole(MANAGE_COLLECTED_FEES_ROLE, _msgSender()),
      'LiquidityManager: must have MANAGE_COLLECTED_FEES_ROLE to execute this function'
    );
    require(devAddress != address(0), 'LiquidityManager: invalid developer address provided');
    devAddr = devAddress;
  }

  /**
   * @notice Sets the contract address for the ERC20 cross-chain bridge
   *
   * @dev can only be called by MANAGE_CONNECTIONS_ROLE
   * @param contractAddress the address of the ERC20 cross chain bridge contract
   */
  function setCrossChainBridgeERC20(ICrossChainBridgeERC20 contractAddress) external {
    require(
      hasRole(MANAGE_CONNECTIONS_ROLE, _msgSender()),
      'LiquidityManager: must have MANAGE_CONNECTIONS_ROLE to execute this function'
    );
    require(address(contractAddress) != address(0), 'LiquidityManager: invalid developer address provided');
    bridgeERC20 = contractAddress;
  }

  /**
     * @notice Creates a new pool and LP token for a given original token address
               Public interface to this function including access control check
     *
     * @param tokenAddress address of the token for which liquidity is being provided in this pool
     * @dev emits event LiquidityPoolCreated
     */
  function createPool(address tokenAddress) external override returns (bool) {
    require(
      _msgSender() == address(bridgeERC20),
      'LiquidityManager: this function can only be called by the ERC20 bridge'
    );
    return _createPool(tokenAddress);
  }

  /**
     * @notice Creates a new pool and LP token for a given original token address
               Private interface to this function without access control check
     *
     * @param tokenAddress address of the token for which liquidity is being provided in this pool
     * @dev emits event LiquidityPoolCreated
     */
  function _createPool(address tokenAddress) private whenNotPaused returns (bool) {
    require(!lpTokens[tokenAddress].exists, 'LiquidityManager: a pool already exists for this token');

    // Create the LP token
    lpTokens[tokenAddress] = LPToken({exists: true, token: new MintableERC20('Cross-Chain Bridge LPs', 'Bridge-LP')});

    // Register token approvals for ERC20 bridge
    require(
      bridgeERC20.registerTokenTransferApprovals(tokenAddress),
      'LiquidityManager: error while registering approvals'
    );

    emit LiquidityPoolCreated(tokenAddress, address(lpTokens[tokenAddress].token));
    return true;
  }

  /**
   * @notice Updates name and symbol of the given LP token
   * must be called through this contract as this contract is the owner of the LP token contract
   *
   * @dev can only be called by MANAGE_TOKEN_ROLE
   * @param contractAddress the address of the LP token contract
   * @param newName the new name of the token
   * @param newSymbol the new symbol of the token
   * @param newDecimals the new number of decimals of the token
   */
  function setNameAndSymbolAndDecimalsOfLpToken(
    MintableERC20 contractAddress,
    string memory newName,
    string memory newSymbol,
    uint8 newDecimals
  ) external override {
    require(
      hasRole(MANAGE_TOKEN_ROLE, _msgSender()),
      'LiquidityManager: must have MANAGE_TOKEN_ROLE to execute this function'
    );
    contractAddress.setNameAndSymbolAndDecimals(newName, newSymbol, newDecimals);
  }

  /**
   * @notice Receive function that enables the contract to receive native tokens in transactions
   *         Required by ERC20<->nativeToken swaps with a wrapped native token contract
   */
  receive() external payable {}
}