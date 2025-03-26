// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

/**
 * @title MyPausableUpgradeable
 * This contracts introduces pausability,reentrancy guard and access control to all smart contracts that inherit from it
 */
abstract contract MyPausableUpgradeable is
  AccessControlUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable,
  UUPSUpgradeable
{
  bytes32 public constant PAUSABILITY_PAUSE_ROLE = keccak256('PAUSABILITY_PAUSE_ROLE');
  bytes32 public constant PAUSABILITY_UNPAUSE_ROLE = keccak256('PAUSABILITY_UNPAUSE_ROLE');
  bytes32 public constant MANAGE_UPGRADES_ROLE = keccak256('MANAGE_UPGRADES_ROLE');

  /**
   * @notice Initializer instead of constructor to have the contract upgradeable
   * @dev can only be called once after deployment of the contract
   */
  function __MyPausableUpgradeable_init() internal initializer {
    // call parent initializers
    __ReentrancyGuard_init();
    __AccessControl_init();
    __Pausable_init();
    __UUPSUpgradeable_init();

    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(PAUSABILITY_PAUSE_ROLE, _msgSender());
    _setupRole(PAUSABILITY_UNPAUSE_ROLE, _msgSender());
    _setupRole(MANAGE_UPGRADES_ROLE, _msgSender());
  }

  /**
   * @notice This function s required to enable the OpenZeppelin UUPS proxy upgrade pattern
   * We decided to implement this function here as every other contract inherits from this one
   *
   * @dev can only be called by MANAGE_UPGRADES_ROLE
   */
  function _authorizeUpgrade(address) internal view override {
    require(
      hasRole(MANAGE_UPGRADES_ROLE, _msgSender()),
      'MyPausableUpgradeable: must have MANAGE_UPGRADES_ROLE to execute this function'
    );
  }

  /**
   * @notice Pauses all contract functions that have the "whenNotPaused" modifier
   *
   * @dev can only be called by PAUSABILITY_ADMIN_ROLE
   */
  function pause() external whenNotPaused {
    require(
      hasRole(PAUSABILITY_PAUSE_ROLE, _msgSender()),
      'MyPausableUpgradeable: must have PAUSABILITY_PAUSE_ROLE to execute this function'
    );
    PausableUpgradeable._pause();
  }

  /**
   * @notice Un-pauses/resumes all contract functions that have the "whenNotPaused" modifier
   *
   * @dev can only be called by PAUSABILITY_ADMIN_ROLE
   */
  function unpause() external whenPaused {
    require(
      hasRole(PAUSABILITY_UNPAUSE_ROLE, _msgSender()),
      'MyPausableUpgradeable: must have PAUSABILITY_UNPAUSE_ROLE to execute this function'
    );
    PausableUpgradeable._unpause();
  }
}