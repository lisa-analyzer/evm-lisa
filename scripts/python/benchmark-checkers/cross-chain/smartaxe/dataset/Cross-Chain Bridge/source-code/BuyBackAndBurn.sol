// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import './utils/MyPausableUpgradeable.sol';
import './interfaces/IRouter.sol';
import './interfaces/ICrossChainBridgeERC20.sol';
import 'hardhat/console.sol';
import './interfaces/IBuyBackAndBurn.sol';
import './token/Bridge.sol';

/**
 * @title BuyBackAndBurnV2
 * This contract collects cross-chain bridge fees and orchestrates token buybacks and burns
 */
contract BuyBackAndBurn is MyPausableUpgradeable, IBuyBackAndBurn {
  using SafeERC20 for IERC20;

  // Roles
  bytes32 public constant MANAGE_CONTRACTS_ROLE = keccak256('MANAGE_CONTRACTS_ROLE');

  event TokensAdded(address indexed tokenAddress, uint256 amount, uint256 collectedAmount);

  event BoughtBackAndBurned(
    address indexed collectedTokenAddress,
    uint256 swapTokenAmount,
    address indexed burnTokenAddress,
    uint256 burnTokenAmount
  );

  /// Address of the token that will get burned by this contract
  IERC20 public burnToken;

  /// Address of the IRouter that connects with a DEX and facilitates token swaps
  IRouter public router;

  /// Amount of native tokens collected
  uint256 public collectedNativeTokenToBurn;

  /// Amount of ERC20 tokens collected per token
  mapping(address => uint256) public collectedERC20ToBurn;

  /// address of the ERC20 cross-chain bridge contract
  ICrossChainBridgeERC20 public bridgeERC20;

  /**
   * @notice Initializer instead of constructor to have the contract upgradeable
   *
   * @dev can only be called once after deployment of the contract
   * @param _burnToken token contract address of the token to be burned (must be an IERC20 contract)
   * @param _router the address of the decentralized exchange (DEX) that is used to swap tokens (must be an IRouter token)
   */
  function initialize(IERC20 _burnToken, IRouter _router) external initializer {
    // call parent initializers
    __MyPausableUpgradeable_init();

    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // initialize required state variables
    burnToken = _burnToken;
    router = _router;
  }

  /**
   * @notice Sets the contract address of the token to be burned
   *
   * @dev can only be called by MANAGE_CONTRACTS_ROLE
   * @param token token contract address of the token to be burned (must be an IERC20 contract)
   */
  function setBurnToken(IERC20 token) external {
    require(
      hasRole(MANAGE_CONTRACTS_ROLE, _msgSender()),
      'BuyBackAndBurnV1: must have MANAGE_CONTRACTS_ROLE role to execute this function'
    );
    require(address(token) != address(0), 'BuyBackAndBurnV1: invalid token address provided');
    burnToken = token;
  }

  /**
   * @notice Sets the contract address of the DEX to be used for token swaps
   *
   * @dev can only be called by MANAGE_CONTRACTS_ROLE
   * @param routerAddress the address of the DEX  (must be an IRouter token)
   */
  function setRouterAddress(address routerAddress) external {
    require(
      hasRole(MANAGE_CONTRACTS_ROLE, _msgSender()),
      'BuyBackAndBurnV1: must have MANAGE_CONTRACTS_ROLE role to execute this function'
    );
    require(routerAddress != address(0), 'BuyBackAndBurnV1: invalid token address provided');

    router = IRouter(routerAddress);
  }

  /**
   * @notice Swaps all collected ERC20 tokens (of the specified type) into burn tokens using an external DEX and burns them
   *
   * @param collectedToken token contract address of the collected ERC20 tokens that should be burned (must be an IERC20 contract)
   * @dev emits event BoughtBackAndBurned()
   */
  function buyBackAndBurnERC20(address collectedToken) external whenNotPaused nonReentrant {
    // check input parameter
    require(collectedToken != address(0), 'BuyBackAndBurnV1: invalid token address');

    // TODO FOR NEXT UPGRADE:   replace sendCollectedTokensToBuyBackAndBurn() with forwardCollectedFees()
    // trigger deposit of uncollected fees from bridgeERC20
    bridgeERC20.sendCollectedTokensToBuyBackAndBurn(IERC20(collectedToken));

    // check how much of the given token is ready for burn
    uint256 amount = collectedERC20ToBurn[collectedToken];
    require(amount > 0, 'BuyBackAndBurnV1: no tokens to burn');

    // register approval for router to spend collectedToken, if not already done
    if (IERC20(collectedToken).allowance(address(this), address(router)) < amount) {
      IERC20(collectedToken).approve(address(router), type(uint256).max);
    }

    // swap collected tokens to burn tokens using external DEX
    uint256 burnAmount = router.tradeERC20(IERC20(collectedToken), burnToken, amount);

    // burn all available burn tokens (swapped and directly collected))
    uint256 balanceBurnToken = burnToken.balanceOf(address(this));
    ERC20Burnable(address(burnToken)).burn(balanceBurnToken);

    // update records - set collected tokens to 0
    collectedERC20ToBurn[collectedToken] = 0;

    // collected tokens successfully swapped and burned => emit event
    emit BoughtBackAndBurned(collectedToken, amount, address(burnToken), balanceBurnToken);
  }

  /**
   * @notice Swaps all collected native tokens into burn tokens using an external DEX and burns them
   *
   * @dev emits event BoughtBackAndBurned()
   */
  function buyBackAndBurnNative() external whenNotPaused nonReentrant {
    // get amount of available native tokens that are ready for burning
    uint256 amount = collectedNativeTokenToBurn;
    require(amount > 0, 'BuyBackAndBurnV1: no tokens to burn');

    // swap native tokens to burn tokens using external DEX
    uint256 burnAmount = router.tradeNativeTokenForERC20{value: amount}(burnToken, amount);

    // burn all available burn tokens (swapped and directly collected))
    uint256 balanceBurnToken = burnToken.balanceOf(address(this));
    ERC20Burnable(address(burnToken)).burn(balanceBurnToken);

    // update records - set collected native tokens to 0
    collectedNativeTokenToBurn = 0;

    // native tokens successfully swapped and burned => emit event
    emit BoughtBackAndBurned(address(0), amount, address(burnToken), balanceBurnToken);
  }

  /**
   * @notice Transfers ERC20 tokens from message sender to this smart contract and updates collectedTokenForBurn counter
   *
   * @param token token contract address of the token to be transferred (must be an IERC20 contract)
   * @param amount amount of ERC20 tokens that should be transfered
   * @dev emits event TokensAdded
   */
  function depositERC20(IERC20 token, uint256 amount) external override whenNotPaused {
    //check input parameter
    require(amount > 0, 'BuyBackAndBurnV1: amount cannot be 0');
    require(address(token) != address(0), 'BuyBackAndBurnV1: invalid token address');

    // transfer the specified amount of given ERC20 tokens from sender to this contract
    token.safeTransferFrom(_msgSender(), address(this), amount);

    // update the collected ERC20 token to burn counter
    collectedERC20ToBurn[address(token)] = collectedERC20ToBurn[address(token)] + amount;

    // transfer complete - emit event
    emit TokensAdded(address(token), amount, collectedERC20ToBurn[address(token)]);
  }

  /**
   * @notice Transfers native tokens from message sender to this smart contract and updates collectedTokenForBurn counter
   *
   * @param amount amount of native tokens that should be transfered
   * @dev emits event TokensAdded
   */
  function depositNativeToken(uint256 amount) external payable override whenNotPaused {
    //check input parameter
    require(amount > 0, 'BuyBackAndBurnV1: amount cannot be 0');
    require(msg.value == amount, 'BuyBackAndBurnV1: given amount does not match the value sent with this call');

    // update the collected native token to burn counter
    collectedNativeTokenToBurn = collectedNativeTokenToBurn + amount;

    // transfer complete - emit event
    emit TokensAdded(address(0), amount, collectedNativeTokenToBurn);
  }

  /**
   * @notice Sets the address for the bridgeERC20 contract
   *
   * @dev can only be called by MANAGE_CONTRACTS_ROLE
   * @param _bridgeERC20 the address of the bridgeERC20 contract
   */
  function setBridgeERC20(ICrossChainBridgeERC20 _bridgeERC20) external {
    require(
      hasRole(MANAGE_CONTRACTS_ROLE, _msgSender()),
      'BuyBackAndBurnV1: must have MANAGE_CONTRACTS_ROLE role to execute this function'
    );
    bridgeERC20 = _bridgeERC20;
  }

  /**
   * @notice Default function that is executed whenever native tokens are sent to this contract without any information/data.
   */
  receive() external payable {
    // update the collected native token to burn counter
    collectedNativeTokenToBurn = collectedNativeTokenToBurn + msg.value;

    // transfer complete - emit event
    emit TokensAdded(address(0), msg.value, collectedNativeTokenToBurn);
  }
}