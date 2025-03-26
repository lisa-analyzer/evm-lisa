// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '../utils/MyPausableUpgradeable.sol';
import 'hardhat/console.sol';
import '../RewardPoolsV1.sol';

contract Bridge is ERC20Upgradeable, MyPausableUpgradeable {
  bytes32 public constant MANAGE_TOKEN_ROLE = keccak256('MANAGE_TOKEN_ROLE');

  /**
   * @notice Initializer instead of constructor to have the contract upgradeable
   *
   * @param _totalSupply the total supply of Bridge tokens
   */
  function initialize(uint256 _totalSupply) external initializer {
    // call parent initializers
    __MyPausableUpgradeable_init();
    __ERC20_init('Cross-Chain Bridge Token', 'BRIDGE');

    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // mint total supply to deployer
    _mint(_msgSender(), _totalSupply);
  }

  /**
   * @notice Mints (creates new) Bridge tokens and sends them to the given address
   *
   * @dev can only be called by MANAGE_TOKEN_ROLE
   * @param to the address of the receiver the tokens should be minted to
   * @param amount the amount of tokens to be minted
   * @dev see {ERC20-_burn}
   * @dev emits event Transfer
   */
  function mint(address to, uint256 amount) external whenNotPaused {
    require(hasRole(MANAGE_TOKEN_ROLE, _msgSender()), 'Bridge: must have MANAGE_TOKEN_ROLE to mint');
    _mint(to, amount);
  }

  /**
   * @notice Burns (destroys) the given amount of Bridge tokens from the caller of the function
   *
   * @dev see {ERC20-_burn}
   * @dev emits event Transfer
   */
  function burn(uint256 amount) external virtual whenNotPaused {
    _burn(_msgSender(), amount);
  }

  /**
   * @notice Burns (destroys) the given amount of Bridge tokens on behalf of another account
   *
   * @dev see {ERC20-_burn} and {ERC20-allowance}
   * @dev the caller must have allowance for ``accounts``'s tokens
   * @param from the address that owns the tokens to be burned
   * @param amount the amount of tokens to be burned
   * @dev emits event Transfer
   */
  function burnFrom(address from, uint256 amount) external virtual whenNotPaused {
    // check if burn amount is within allowance
    require(allowance(from, _msgSender()) >= amount, 'Bridge: burn amount exceeds allowance');
    _approve(from, _msgSender(), allowance(from, _msgSender()) - amount);
    // burn token
    _burn(from, amount);
  }

  /**
   * @notice This function (or hook) is called before every token transfer
   *
   * @dev for further information on hooks see https://docs.openzeppelin.com/contracts/3.x/extending-contracts#using-hooks
   * @param from the address of the sender of the token transfer
   * @param to the address of the recipient of the token transfer
   * @param amount the amount of tokens that will be transferred
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}