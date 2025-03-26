// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

/**
 * @title MyPausable
 * This contracts introduces pausability and access control to all smart contracts that inherit from it
 */
abstract contract MyPausable is AccessControl, Pausable {
  bytes32 public constant PAUSABILITY_ADMIN_ROLE = keccak256('PAUSABILITY_ADMIN_ROLE');

  constructor() {
    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(PAUSABILITY_ADMIN_ROLE, _msgSender());
  }

  /**
   * @notice Pauses all contract functions that have the "whenNotPaused" modifier
   *
   * @dev can only be called by PAUSABILITY_ADMIN_ROLE
   */
  function pause() external whenNotPaused {
    require(
      hasRole(PAUSABILITY_ADMIN_ROLE, _msgSender()),
      'MyPausable: must have PAUSABILITY_ADMIN_ROLE to execute this function'
    );
    Pausable._pause();
  }

  /**
   * @notice Un-pauses/resumes all contract functions that have the "whenNotPaused" modifier
   *
   * @dev can only be called by PAUSABILITY_ADMIN_ROLE
   */
  function unpause() external whenPaused {
    require(
      hasRole(PAUSABILITY_ADMIN_ROLE, _msgSender()),
      'MyPausable: must have PAUSABILITY_ADMIN_ROLE to execute this function'
    );
    Pausable._unpause();
  }
}