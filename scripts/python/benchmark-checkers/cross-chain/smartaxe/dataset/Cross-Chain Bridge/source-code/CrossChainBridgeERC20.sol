// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import './interfaces/IBuyBackAndBurn.sol';
import './interfaces/ICrossChainBridgeERC20.sol';
import './interfaces/IMultiSignatureOracle.sol';
import './interfaces/ICrossChainBridgeERC20LiquidityManager.sol';
import './token/MintableERC20.sol';
import './CrossChainBridgeERC20LiquidityManager.sol';
import './utils/MyPausableUpgradeable.sol';
import './BuyBackAndBurn.sol';
import './LiquidityMiningPoolsV1.sol';

interface IRewardPools {
  function addRewards(IERC20 token, uint256 amount) external;
}

interface ILiquidityMiningPools {
  function addRewards(IERC20 token, uint256 amount) external;

  function setCrossChainERC20Bridge(ICrossChainBridgeERC20 bridge) external;
}

/**
 * @title Cross chain token bridge for ERC20 token
 */
contract CrossChainBridgeERC20 is MyPausableUpgradeable {
  using SafeERC20 for IERC20;

  // Roles
  bytes32 public constant MANAGE_COLLECTED_FEES_ROLE = keccak256('MANAGE_COLLECTED_FEES_ROLE');
  bytes32 public constant MANAGE_FEES_ROLE = keccak256('MANAGE_FEES_ROLE');
  bytes32 public constant MANAGE_ORACLES_ROLE = keccak256('MANAGE_ORACLES_ROLE');
  bytes32 public constant MANAGE_OUTSIDE_PEGGED_TOKENS_ROLE = keccak256('MANAGE_OUTSIDE_PEGGED_TOKENS_ROLE');
  bytes32 public constant MANAGE_REWARD_POOLS_ROLE = keccak256('MANAGE_REWARD_POOLS_ROLE');
  bytes32 public constant MANAGE_LIQUIDITY_MANAGER_ROLE = keccak256('MANAGE_LIQUIDITY_MANAGER_ROLE');
  bytes32 public constant MANAGE_LIQUIDITY_MINING_POOLS_ROLE = keccak256('MANAGE_LIQUIDITY_MINING_POOLS_ROLE');

  event TokensDeposited(
    address indexed sourceNetworkTokenAddress,
    uint256 amount,
    address indexed receiverAddress,
    uint256 sourceChainId,
    uint256 targetChainId,
    uint256 number
  );

  event TokensReleased(
    address indexed sourceNetworkTokenAddress,
    uint256 amount,
    address indexed receiverAddress,
    uint256 depositChainId,
    uint256 depositNumber
  );

  event PeggedTokenMappingAdded(address indexed depositChainTokenAddress, address indexed releaseChainTokenAddress);

  /// Counts all deposits
  /// Assigns a unique deposit ID to each deposit which helps to prevent double releases
  uint256 public depositCount;

  /// Default bridge fee (in ppm: parts per million - 10,000ppm = 1%)
  uint256 public defaultBridgeFee;

  /// Relative fee from the bridge fee to collect for further usage
  uint256 public collectBridgeFeePercentage;

  /// Relative fee from the bridge fee to distribute to liquidity miner
  uint256 public liquidityMiningFeePercentage;

  /// Default liquidity withdrawal fee (in ppm: parts per million - 10,000ppm = 1%)
  uint256 public defaultLiquidityWithdrawalFee;

  /// A mapping from deposit IDs to boolean if a deposit has been released or not
  /// depositChainId => depositNumber => true (released)
  mapping(uint256 => mapping(uint256 => bool)) public releasedDeposits;

  /// Individual bridge fees per supported token (in ppm: parts per million - 10,000ppm = 1%)
  /// tokenAdressInDepositNetwork => ppm
  mapping(address => uint256) public bridgeFees;

  /// Storage of the outside pegged tokens
  /// tokenAddressInThisNetwork => tokenAddressInTargetNetwork
  mapping(address => address) public outsidePeggedTokens;

  /// Contract to receive a part of the bridge fees for token burns
  IBuyBackAndBurn public buyBackAndBurn;

  /// RewardPools contract
  IRewardPools public rewardPools;

  /// LiquidityMiningPools contract
  ILiquidityMiningPools public liquidityMiningPools;

  /// MultiSignatureOracle contract
  IMultiSignatureOracle public multiSignatureOracle;

  /// the contract address of the wrapped native token in the network this contract is deployed in (e.g. WETH, WBNB)
  INativeToken public wrappedNative;

  /// address of the contract that manages liquidity for the ERC20 bridge
  ICrossChainBridgeERC20LiquidityManager public liquidityManager;

  /// Stores for each asset the collected but unsent fees for BuyBackAndBurn, Reward and LiquidityMining Pools
  /// tokenAddressInThisNetwork => addressOfContract => lastTransferBlockNumber
  mapping(address => mapping(address => uint256)) public collectedUnsentFees;

  /// Stores for each asset the last block number in which fees were transferred to Reward and LiquidityMining Pools
  /// tokenAddressInThisNetwork => RewardPoolsAddress/LiquidityMiningPoolsAddress => lastTransferBlockNumber
  mapping(address => mapping(address => uint256)) public lastTransferBlock;

  /// Number of blocks that need to pass before fees are transferred again
  uint256 public blocksBetweenFeeTransfersToLiquidityMiningPools;
  uint256 public blocksBetweenFeeTransfersToRewardPools;

  /**
   * @notice Initializer instead of constructor to have the contract upgradable
   * @param _rewardPools the address of the rewardPools contract
   * @param _multiSignatureOracle the address of the multiSignatureOracle contract
   * @param _buyBackAndBurn the address of the buyBackAndBurn contract
   * @param _wrappedNative the address of the wrapped native token contract
   * @param _liquidityMiningPools the address of the liquidity mining pools contract
   * @dev can only be called once after deployment of the contract
   */
  function initialize(
    address _rewardPools,
    address _multiSignatureOracle,
    address _buyBackAndBurn,
    address _wrappedNative,
    address _liquidityMiningPools
  ) external initializer {
    // call parent initializers
    MyPausableUpgradeable.__MyPausableUpgradeable_init();

    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // initialize required state variables
    defaultBridgeFee = 3500; // 0.35%
    collectBridgeFeePercentage = 150000; // 15%
    liquidityMiningFeePercentage = 150000; // 15%
    rewardPools = IRewardPools(_rewardPools);
    multiSignatureOracle = IMultiSignatureOracle(_multiSignatureOracle);
    buyBackAndBurn = IBuyBackAndBurn(_buyBackAndBurn);
    wrappedNative = INativeToken(_wrappedNative);
    liquidityMiningPools = ILiquidityMiningPools(_liquidityMiningPools);
  }

  /**
   * @notice Accepts native token deposits that should be bridged into another network
   * (effectively starting a new bridge transaction)
   *
   * @param amount the amount that is being deposited
   * @param receiverAddress target address the bridged token should be sent to (in the target network)
   * @param targetChainId chain ID of the target network
   * @dev emits event TokensDeposited after successful deposit
   *
   */
  function depositNative(
    uint256 amount,
    address receiverAddress,
    uint256 targetChainId
  ) external payable nonReentrant {
    // check input parameters
    require(amount == msg.value, 'CrossChainBridgeERC20: msg.value did not match amount');

    // check native token balance before swap
    uint256 contractBalance = wrappedNative.balanceOf(address(this));

    // swap native to wrapped native ERC20 token
    wrappedNative.deposit{value: msg.value}();

    // check if wrapped native token balance has increased by deposit amount
    require(
      wrappedNative.balanceOf(address(this)) == contractBalance + amount,
      'CrossChainBridgeERC20: error while wrapping native tokens'
    );

    // call depositERC20 function with wrapped native token to complete the deposit
    _depositERC20(wrappedNative, amount, receiverAddress, targetChainId);
  }

  /**
   * @notice Accepts ERC20 token deposits that should be bridged into another network
   * (effectively starting a new bridge transaction)
   * public function interface with reentrancy guard
   *
   * @param token the ERC20 contract the to-be-bridged token was issued with
   * @param amount the amount that is being deposited
   * @param receiverAddress target address the bridged token should be sent to (in the target network)
   * @param targetChainId chain ID of the target network
   * @dev emits event TokensDeposited after successful deposit
   */
  function depositERC20(
    IERC20 token,
    uint256 amount,
    address receiverAddress,
    uint256 targetChainId
  ) public nonReentrant {
    // check token balance before deposit
    uint256 balanceBefore = token.balanceOf(address(this));

    // Transfer to-be-deposited tokens from sender to this smart contract
    token.safeTransferFrom(_msgSender(), address(this), amount);

    // check if token balance has increased by amount (>> effectively preventing deflationary tokens to be added for now)
    require(
      token.balanceOf(address(this)) == balanceBefore + amount,
      'CrossChainBridgeERC20: deposited token amount incorrect'
    );

    // call internal function that mints LP tokens and emits event
    _depositERC20(token, amount, receiverAddress, targetChainId);
  }

  /**
   * @notice Accepts ERC20 token deposits that should be bridged into another network
   * (effectively starting a new bridge transaction)
   * private function interface without reentrancy guard (to enable internal calls by depositNative function)
   *
   * @param token the ERC20 contract the to-be-bridged token was issued with
   * @param amount the amount that is being deposited
   * @param receiverAddress target address the bridged token should be sent to (in the target network)
   * @param targetChainId chain ID of the target network
   * @dev emits event TokensDeposited after successful deposit
   */
  function _depositERC20(
    IERC20 token,
    uint256 amount,
    address receiverAddress,
    uint256 targetChainId
  ) private whenNotPaused {
    // check input parameters
    require(amount > 0, 'CrossChainBridgeERC20: amount cannot be 0');
    require(receiverAddress != address(0), 'CrossChainBridgeERC20: invalid receiverAddress provided');
    require(address(token) != address(0), 'CrossChainBridgeERC20: invalid token address provided');

    (bool exists, ) = liquidityManager.lpTokens(address(token));
    if (!exists) {
      // LP token does not exist yet and needs to be created
      liquidityManager.createPool(address(token));
    }

    // We assign a unique depositCount (=ID) to each deposit which can be used on the target side bridge
    // to avoid double releases
    depositCount = depositCount + 1;

    // deposit completed, emit event
    emit TokensDeposited(address(token), amount, receiverAddress, _getChainID(), targetChainId, depositCount);
  }

  /**
   * @notice Releases native tokens in this network that were deposited in another network
   *         (effectively completing a bridge transaction)
   *
   * @param sigV Array of recovery Ids for the signature
   * @param sigR Array of R values of the signatures
   * @param sigS Array of S values of the signatures
   * @param receiverAddress The account to receive the tokens
   * @param sourceNetworkTokenAddress the address of the ERC20 contract in the network the deposit was made
   * @param amount The amount of tokens to be released
   * @param depositChainId chain ID of the network in which the deposit was made
   * @param depositNumber The identifier of the corresponding deposit
   * @dev emits event TokensReleased after successful release
   */
  function releaseNative(
    uint8[] memory sigV,
    bytes32[] memory sigR,
    bytes32[] memory sigS,
    address receiverAddress,
    address sourceNetworkTokenAddress,
    uint256 amount,
    uint256 depositChainId,
    uint256 depositNumber
  ) external nonReentrant {
    // release wrapped native (ERC20) tokens from bridge without transferring them
    // tokens will be swapped from ERC20 to native token in the following steps
    uint256 releaseAmountAfterFees = _releaseERC20(
      sigV,
      sigR,
      sigS,
      receiverAddress,
      sourceNetworkTokenAddress,
      amount,
      depositChainId,
      depositNumber,
      true
    );

    // check native token balance before ERC20-to-native swap
    uint256 contractBalance = address(this).balance;

    // swap wrapped native ERC20 token back to native token
    wrappedNative.withdraw(releaseAmountAfterFees);

    // check if native token balance has increased by release amount
    require(
      address(this).balance == contractBalance + releaseAmountAfterFees,
      'CrossChainBridgeERC20: error while unwrapping native tokens'
    );

    // send native token back to user
    payable(_msgSender()).transfer(releaseAmountAfterFees);
  }

  /**
   * @notice Releases an ERC20 token in this network after a deposit was made in another network
   *         (effectively completing a bridge transaction)
   *
   * @param sigV Array of recovery Ids for the signature
   * @param sigR Array of R values of the signatures
   * @param sigS Array of S values of the signatures
   * @param receiverAddress The account to receive the tokens
   * @param sourceNetworkTokenAddress the address of the ERC20 contract in the network the deposit was made
   * @param amount The amount of tokens to be released
   * @param depositChainId chain ID of the network in which the deposit was made
   * @param depositNumber The identifier of the corresponding deposit
   * @dev emits event TokensReleased after successful release
   */
  function releaseERC20(
    uint8[] memory sigV,
    bytes32[] memory sigR,
    bytes32[] memory sigS,
    address receiverAddress,
    address sourceNetworkTokenAddress,
    uint256 amount,
    uint256 depositChainId,
    uint256 depositNumber
  ) external nonReentrant {
    // forward call internally to private function with "false" parameter (=send ERC20 tokens to _msgSender())
    _releaseERC20(
      sigV,
      sigR,
      sigS,
      receiverAddress,
      sourceNetworkTokenAddress,
      amount,
      depositChainId,
      depositNumber,
      false
    );
  }

  /**
   * @notice Releases an ERC20 token in this network after a deposit was made in another network
   *         (effectively completing a bridge transaction)
   * private function without reentrancy guard to to enable calls by releaseNative function
   *
   * @param sigV Array of recovery Ids for the signature
   * @param sigR Array of R values of the signatures
   * @param sigS Array of S values of the signatures
   * @param receiverAddress The account to receive the tokens
   * @param sourceNetworkTokenAddress the address of the ERC20 contract in the network the deposit was made
   * @param amount The amount of tokens to be released
   * @param depositChainId chain ID of the network in which the deposit was made
   * @param depositNumber The identifier of the corresponding deposit
   * @dev emits event TokensReleased after successful release
   */
  function _releaseERC20(
    uint8[] memory sigV,
    bytes32[] memory sigR,
    bytes32[] memory sigS,
    address receiverAddress,
    address sourceNetworkTokenAddress,
    uint256 amount,
    uint256 depositChainId,
    uint256 depositNumber,
    bool keepTokensInBridge
  ) private whenNotPaused returns (uint256 releaseAmountAfterFees) {
    // check if tokens were already released for the deposit that is uniquely identified by chainId and depositNumber
    require(
      !releasedDeposits[depositChainId][depositNumber],
      'CrossChainBridgeERC20: Deposit was already processed and released'
    );
    require(receiverAddress != address(0), 'CrossChainBridgeERC20: invalid receiverAddress provided');
    require(
      sourceNetworkTokenAddress != address(0),
      'CrossChainBridgeERC20: invalid sourceNetworkTokenAddress provided'
    );
    require(amount > 0, 'CrossChainBridgeERC20: amount cannot be 0');

    // check if signature is correct, i.e. if the sender of this request is permitted to receive these tokens
    require(
      multiSignatureOracle.signaturesCheckERC20(
        sigV,
        sigR,
        sigS,
        receiverAddress,
        sourceNetworkTokenAddress,
        amount,
        depositChainId,
        depositNumber
      ),
      'CrossChainBridgeERC20: Release not permitted. Not enough signatures from permitted oracles'
    );

    // assign token address for release chain
    // usually this address is the same as the deposit chain address
    address releaseChainTokenAddress = sourceNetworkTokenAddress;

    // if the address of the pegged token (in release chain) differs, we use this address instead
    if (outsidePeggedTokens[sourceNetworkTokenAddress] != address(0)) {
      releaseChainTokenAddress = outsidePeggedTokens[sourceNetworkTokenAddress];
    }
    IERC20 token = ERC20(releaseChainTokenAddress);

    // check if bridge has sufficient liquidity
    require(token.balanceOf(address(this)) >= amount, 'CrossChainBridgeERC20: Not enough liquidity in bridge');

    // // determine the fee rate to be used for this transaction (usually default bridge fee)
    // // if a specific fee rate is stored for this particular release token then we use this rate instead
    uint256 relativeFee = bridgeFees[releaseChainTokenAddress] > 0
      ? bridgeFees[releaseChainTokenAddress]
      : defaultBridgeFee;

    // calculate the fee amounts (dividing by 1.000.000 since the fee rate is provided as parts per million [ppm])
    // calculate the total fee amount for this transaction
    uint256 bridgingFee = (amount * relativeFee) / 1000000;

    // calculate the part of the fee amount that will be sent to BuyBackAndBurn for burning
    uint256 bridgingFeeToCollectAddress = (bridgingFee * collectBridgeFeePercentage) / 1000000;

    // calculate the part of the fee amount that will be sent to LiquidityMiningPools
    uint256 bridgingFeeToLiquidityMining = (bridgingFee * liquidityMiningFeePercentage) / 1000000;

    // calculate the part of the fee amount that will be sent to RewardPools
    uint256 bridgingFeeToRewardPool = bridgingFee - bridgingFeeToCollectAddress - bridgingFeeToLiquidityMining;

    // update released deposits log to prevent double spending
    releasedDeposits[depositChainId][depositNumber] = true;

    // increase counters for unsent fees
    collectedUnsentFees[releaseChainTokenAddress][address(buyBackAndBurn)] += bridgingFeeToCollectAddress;
    collectedUnsentFees[releaseChainTokenAddress][address(liquidityMiningPools)] += bridgingFeeToLiquidityMining;
    collectedUnsentFees[releaseChainTokenAddress][address(rewardPools)] += bridgingFeeToRewardPool;

    // transfer fees (only one transfer max for gas optimization)
    if (
      lastTransferBlock[releaseChainTokenAddress][address(rewardPools)] + blocksBetweenFeeTransfersToRewardPools <=
      block.number &&
      collectedUnsentFees[releaseChainTokenAddress][address(rewardPools)] > 0
    ) {
      // send all collected fees for this asset to RewardPools
      rewardPools.addRewards(
        IERC20(releaseChainTokenAddress),
        collectedUnsentFees[releaseChainTokenAddress][address(rewardPools)]
      );

      // set collectedUnsentFees to 0
      collectedUnsentFees[releaseChainTokenAddress][address(rewardPools)] = 0;

      // update lastTransferBlock
      lastTransferBlock[releaseChainTokenAddress][address(rewardPools)] = block.number;
    } else if (
      lastTransferBlock[releaseChainTokenAddress][address(liquidityMiningPools)] +
        blocksBetweenFeeTransfersToLiquidityMiningPools <=
      block.number &&
      collectedUnsentFees[releaseChainTokenAddress][address(liquidityMiningPools)] > 0
    ) {
      // transfer fees to liquidityMiningPools if enough blocks have passed since last transfer(
      // send all collected fees for this asset to LiquidityMiningPools
      liquidityMiningPools.addRewards(
        IERC20(releaseChainTokenAddress),
        collectedUnsentFees[releaseChainTokenAddress][address(liquidityMiningPools)]
      );

      // set collectedUnsentFees to 0
      collectedUnsentFees[releaseChainTokenAddress][address(liquidityMiningPools)] = 0;

      // update lastTransferBlock
      lastTransferBlock[releaseChainTokenAddress][address(liquidityMiningPools)] = block.number;
    }

    releaseAmountAfterFees = amount - bridgingFee;

    // safely transfer (release) token amount minus fees to the caller
    // if keepTokenInBridge=true: ERC20 tokens will be kept in bridge and swapped to native tokens
    if (!keepTokensInBridge) {
      // case: external caller - send to receiverAddress
      token.safeTransfer(receiverAddress, releaseAmountAfterFees);
    }

    emit TokensReleased(
      sourceNetworkTokenAddress,
      releaseAmountAfterFees,
      receiverAddress,
      depositChainId,
      depositNumber
    );
  }

  /**
   * @notice Sets the address for the ERC20 bridge liquidity manager contract
   *
   * @dev can only be called by MANAGE_LIQUIDITY_MANAGER_ROLE
   * @param contractAddress the address of the liquidity manager contract
   */
  function setCrossChainBridgeERC20LiquidityManager(ICrossChainBridgeERC20LiquidityManager contractAddress) external {
    require(
      hasRole(MANAGE_LIQUIDITY_MANAGER_ROLE, _msgSender()),
      'CrossChainBridgeERC20: must have MANAGE_LIQUIDITY_MANAGER_ROLE role to execute this function'
    );
    require(address(contractAddress) != address(0), 'CrossChainBridgeERC20: invalid address provided');
    liquidityManager = contractAddress;
  }

  /**
   * @notice Sets the address for the LiquidityMiningPools contract
   *
   * @dev can only be called by MANAGE_LIQUIDITY_MINING_POOLS_ROLE
   * @param contractAddress the address of the LiquidityMiningPools contract
   */
  function setLiquidityMiningPools(ILiquidityMiningPools contractAddress) external {
    require(
      hasRole(MANAGE_LIQUIDITY_MINING_POOLS_ROLE, _msgSender()),
      'CrossChainBridgeERC20: must have MANAGE_LIQUIDITY_MINING_POOLS_ROLE role to execute this function'
    );
    require(address(contractAddress) != address(0), 'CrossChainBridgeERC20: invalid address provided');
    liquidityMiningPools = contractAddress;
  }

  /**
   * @notice Adds an outside pegged token (= same token but in a different network)
   *
   * @dev can only be called by MANAGE_OUTSIDE_PEGGED_TOKENS_ROLE
   * @param depositChainTokenAddress the address of the token in the source network (deposit token)
   * @param peggedTokenAddress the address of the pegged token in the network this bridge contract is released on (release token)
   * @dev emits event PeggedTokenMappingAdded
   */
  function addOutsidePeggedToken(address depositChainTokenAddress, address peggedTokenAddress) external {
    require(
      hasRole(MANAGE_OUTSIDE_PEGGED_TOKENS_ROLE, _msgSender()),
      'CrossChainBridgeERC20: must have MANAGE_OUTSIDE_PEGGED_TOKENS_ROLE role to execute this function'
    );
    require(
      depositChainTokenAddress != address(0) && peggedTokenAddress != address(0),
      'CrossChainBridgeERC20: invalid tokenAddress provided'
    );
    outsidePeggedTokens[depositChainTokenAddress] = peggedTokenAddress;

    emit PeggedTokenMappingAdded(depositChainTokenAddress, peggedTokenAddress);
  }

  /**
   * @notice Removes an outsidePeggedToken (i.e. a token with different contract addresses across networks)
   *
   * @dev can only be called by MANAGE_OUTSIDE_PEGGED_TOKENS_ROLE
   * @param sourceNetworkTokenAddress the address of the token contract
   */
  function removeOutsidePeggedToken(address sourceNetworkTokenAddress) external {
    require(
      hasRole(MANAGE_OUTSIDE_PEGGED_TOKENS_ROLE, _msgSender()),
      'CrossChainBridgeERC20: must have MANAGE_OUTSIDE_PEGGED_TOKENS_ROLE role to execute this function'
    );
    outsidePeggedTokens[sourceNetworkTokenAddress] = address(0);
  }

  /**
   * @notice Sets the default bridge fee percentage that is being used for token buybacks and burns
   *
   * @dev can only be called by MANAGE_FEES_ROLE
   * @param fee the default bridging fee rate provided in ppm: parts per million - 10,000ppm = 1%
   */
  function setDefaultBridgeFee(uint256 fee) external {
    require(
      hasRole(MANAGE_FEES_ROLE, _msgSender()),
      'CrossChainBridgeERC20: must have MANAGE_FEES_ROLE role to execute this function'
    );
    defaultBridgeFee = fee;
  }

  /**
   * @notice Sets an individual bridge fee for the provided token
   *
   * @dev can only be called by MANAGE_FEES_ROLE
   * @param sourceNetworkTokenAddress the address of the token contract
   * @param fee the individual bridging fee rate provided in ppm: parts per million - 10,000ppm = 1%
   */
  function setBridgeFee(address sourceNetworkTokenAddress, uint256 fee) external {
    require(
      hasRole(MANAGE_FEES_ROLE, _msgSender()),
      'CrossChainBridgeERC20: must have MANAGE_FEES_ROLE role to execute this function'
    );
    bridgeFees[sourceNetworkTokenAddress] = fee;
  }

  /**
   * @notice Sets the percentage of the total bridge fee that is being used for token buybacks and burns
   *
   * @dev can only be called by MANAGE_FEES_ROLE
   * @param fee the percentage of the relative bridge fee provided in ppm: parts per million - 10,000ppm = 1%
   */
  function setCollectBridgeFeePercentage(uint256 fee) external {
    require(
      hasRole(MANAGE_COLLECTED_FEES_ROLE, _msgSender()),
      'CrossChainBridgeERC20: must have MANAGE_COLLECTED_FEES_ROLE role to execute this function'
    );
    collectBridgeFeePercentage = fee;
  }

  /**
   * @notice Sets the percentage of the total bridge fee that is being used for token buybacks and burns
   *
   * @dev can only be called by MANAGE_FEES_ROLE
   * @param fee the percentage of the relative bridge fee provided in ppm: parts per million - 10,000ppm = 1%
   */
  function setLiquidityMiningFeePercentage(uint256 fee) external {
    require(
      hasRole(MANAGE_COLLECTED_FEES_ROLE, _msgSender()),
      'CrossChainBridgeERC20: must have MANAGE_COLLECTED_FEES_ROLE role to execute this function'
    );
    liquidityMiningFeePercentage = fee;
  }

  /**
   * @notice Sets the address for the BuyBackAndBurn contract that receives bridging fees to fund token burns
   *
   * @dev can only be called by MANAGE_COLLECTED_FEES_ROLE
   * @param _buyBackAndBurn the address of the BuyBackAndBurn contract
   */
  function setBuyBackAndBurn(IBuyBackAndBurn _buyBackAndBurn) external {
    require(
      hasRole(MANAGE_COLLECTED_FEES_ROLE, _msgSender()),
      'CrossChainBridgeERC20: must have MANAGE_COLLECTED_FEES_ROLE role to execute this function'
    );
    require(address(_buyBackAndBurn) != address(0), 'CrossChainBridgeERC20: invalid buyBackAndBurn address provided');
    buyBackAndBurn = _buyBackAndBurn;
  }

  /**
   * @notice Sets the address for the RewardPools contract that receives the liquidity fees
   *
   * @dev can only be called by MANAGE_REWARD_POOLS_ROLE
   * @param _rewardPools the address of the RewardPools contract
   */
  function setRewardPools(IRewardPools _rewardPools) external {
    require(
      hasRole(MANAGE_REWARD_POOLS_ROLE, _msgSender()),
      'CrossChainBridgeERC20: must have MANAGE_REWARD_POOLS_ROLE role to execute this function'
    );
    require(address(_rewardPools) != address(0), 'CrossChainBridgeERC20: invalid rewardPools address provided');
    rewardPools = _rewardPools;
  }

  /**
   * @notice Sets the address for the MultiSignatureOracle contract
   *
   * @dev can only be called by MANAGE_ORACLES_ROLE
   * @param _multiSignatureOracle the address of the multiSignatureOracle contract
   */
  function setMultiSignatureOracle(IMultiSignatureOracle _multiSignatureOracle) external {
    require(
      hasRole(MANAGE_ORACLES_ROLE, _msgSender()),
      'CrossChainBridgeERC20: must have MANAGE_ORACLES_ROLE role to execute this function'
    );
    require(
      address(_multiSignatureOracle) != address(0),
      'CrossChainBridgeERC20: invalid multiSignatureOracle address provided'
    );
    multiSignatureOracle = _multiSignatureOracle;
  }

  /**
   * @notice Sets the number of blocks that need to pass between fee transfers
   *
   * @dev can only be called by MANAGE_COLLECTED_FEES_ROLE
   * @param blocksRewardPools the new number of blocks that need to pass between fee transfers to RewardPools
   * @param blocksLiquidityMiningPools the new number of blocks that need to pass between fee transfers to LiquidityMiningPools
   */
  function setBlocksBetweenFeeTransfers(uint256 blocksRewardPools, uint256 blocksLiquidityMiningPools) external {
    require(
      hasRole(MANAGE_COLLECTED_FEES_ROLE, _msgSender()),
      'CrossChainBridgeERC20: must have MANAGE_COLLECTED_FEES_ROLE role to execute this function'
    );
    blocksBetweenFeeTransfersToRewardPools = blocksRewardPools;
    blocksBetweenFeeTransfersToLiquidityMiningPools = blocksLiquidityMiningPools;
  }

  /**
   * @notice Transfers collected but unsent fees to BuyBackAndBurn contract for the given asset
   *
   * @param token the token in which fees were collected
   */
  function sendCollectedTokensToBuyBackAndBurn(IERC20 token) external {
    forwardCollectedFees(token, true, false, false);
    // TODO: remove this function after next BuyBackAndBurn upgrade
  }

  /**
   * @notice Transfers collected but unsent fees to BuyBackAndBurn, LiquidityMiningPools and RewardPools
   *
   * @param token the token in which fees were collected
   * @param _buyBackAndBurn true if collected fees should be sent to BuyBackAndBurn
   * @param _miningPools true if collected fees should be sent to LiquidityMiningPools
   * @param _rewardPools true if collected fees should be sent to RewardPools
   */
  function forwardCollectedFees(
    IERC20 token,
    bool _buyBackAndBurn,
    bool _miningPools,
    bool _rewardPools
  ) public nonReentrant {
    if (token.balanceOf(address(this)) > 0) {
      if (_buyBackAndBurn) {
        buyBackAndBurn.depositERC20(token, collectedUnsentFees[address(token)][address(buyBackAndBurn)]);
        collectedUnsentFees[address(token)][address(buyBackAndBurn)] = 0;
      }
      if (_miningPools) {
        liquidityMiningPools.addRewards(token, collectedUnsentFees[address(token)][address(liquidityMiningPools)]);
        collectedUnsentFees[address(token)][address(liquidityMiningPools)] = 0;
      }
      if (_rewardPools) {
        rewardPools.addRewards(token, collectedUnsentFees[address(token)][address(rewardPools)]);
        collectedUnsentFees[address(token)][address(rewardPools)] = 0;
      }
    }
  }

  // returns the ID of the network this contract is deployed in
  function _getChainID() private view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  /**
   * @notice Register approvals required for token transfers between this and various other contracts
   *
   * @param tokenAddress the address of the token contract for which approvals should be registered
   */
  function registerTokenTransferApprovals(address tokenAddress) external returns (bool) {
    require(tokenAddress != address(0), 'CrossChainBridgeERC20: invalid token address provided');

    // Register approval with the underlying token for the reward pools (to enable transfer)
    IERC20(tokenAddress).safeApprove(address(rewardPools), 0);
    IERC20(tokenAddress).safeApprove(address(rewardPools), type(uint256).max);

    // Register approval with the underlying token for the liquidity mining pools (to enable transfer)
    IERC20(tokenAddress).safeApprove(address(liquidityMiningPools), 0);
    IERC20(tokenAddress).safeApprove(address(liquidityMiningPools), type(uint256).max);

    // Register approval with the underlying token for the buyBackAndBurn (to enable transfer)
    IERC20(tokenAddress).safeApprove(address(buyBackAndBurn), 0);
    IERC20(tokenAddress).safeApprove(address(buyBackAndBurn), type(uint256).max);

    // Register approval with the underlying token for the liquidityManager (to enable transfer)
    IERC20(tokenAddress).safeApprove(address(liquidityManager), 0);
    IERC20(tokenAddress).safeApprove(address(liquidityManager), type(uint256).max);

    return true;
  }

  /**
   * @notice Receive function that enables the contract to receive native tokens in transactions
   *         Required ERC20<->nativeToken swaps with a wrapped native token contract
   */
  receive() external payable {}
}