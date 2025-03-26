// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '../RewardPoolsV1.sol';
import '../utils/MyPausable.sol';

interface IPools {
  function transferInterestBearingTokenHandler(
    address baseToken,
    uint256 amount,
    address from,
    address to
  ) external;
}

/**
 * @title PoolsInterestBearingToken
 * The token that users receive in return for staking their bridge tokens in our pools (liquidity mining or reward pools)
 */
contract PoolsInterestBearingToken is MyPausable, ERC20Burnable {
  bytes32 public constant MANAGE_POOLS_ROLE = keccak256('MANAGE_POOLS_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

  address public baseToken;
  address public poolsContractAddress;

  /**
   * @notice Constructor: Creates a new token
   *
   * @param name the name of the new token
   * @param symbol the symbol (short name) of the new token
   * @param _baseToken the address of the underlying token of the pool
   */
  constructor(
    string memory name,
    string memory symbol,
    address _baseToken
  ) ERC20(name, symbol) {
    require(address(_baseToken) != address(0), 'PoolsInterestBearingToken: invalid base token address provided');
    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MANAGE_POOLS_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(BURNER_ROLE, _msgSender());

    baseToken = _baseToken;
  }

  /**
   * @notice Mints new tokens and transfers them to the 'to' address
   *
   * @param from the address from which the tokens should be burned
   * @param amount the amount of tokens that should be minted and transferred
   * @dev emits event Transfer()
   */
  function burn(address from, uint256 amount) external whenNotPaused {
    require(
      hasRole(BURNER_ROLE, _msgSender()),
      'PoolsInterestBearingToken: must have BURNER_ROLE to execute this function'
    );
    _burn(from, amount);
  }

  /**
   * @notice Mints new tokens and transfers them to the 'to' address
   *
   * @param to the address the newly minted tokens should be sent to
   * @param amount the amount of tokens that should be minted and transfered
   * @dev emits event Transfer()
   */
  function mint(address to, uint256 amount) external whenNotPaused {
    require(
      hasRole(MINTER_ROLE, _msgSender()),
      'PoolsInterestBearingToken: must have MINTER_ROLE to execute this function'
    );
    _mint(to, amount);
  }

  /**
   * @notice This function (or hook) is called before every token transfer
   *         (to make sure that the accounting in the respective pools is up-to-date)
   *
   * @dev for further information on hooks see https://docs.openzeppelin.com/contracts/3.x/extending-contracts#using-hooks
   * @param from the address of the sender of the token transfer
   * @param to the address of the recipient of the token transfer
   * @param amount the amount of tokens that will be transfered
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);

    // check if this call was triggered by a mint() (in which case from is zero address) or by a transfer
    if (from != address(0) && to != address(0)) {
      // token transfer - call handler
      IPools(poolsContractAddress).transferInterestBearingTokenHandler(baseToken, amount, from, to);
    }
  }

  /**
   * @notice Sets the address of the pools contract
   *
   * @dev can only be called by MANAGE_POOLS_ROLE
   * @param _poolsContractAddress the address of the pools contract (RewardPools or LiquidityMiningPools)
   */
  function setPoolsContract(address _poolsContractAddress) external {
    require(
      hasRole(MANAGE_POOLS_ROLE, _msgSender()),
      'PoolsInterestBearingToken: must have MANAGE_POOLS_ROLE to execute this function'
    );
    require(address(_poolsContractAddress) != address(0), 'PoolsInterestBearingToken: invalid pool address provided');
    poolsContractAddress = _poolsContractAddress;
  }
}