// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "@zeppelin-solidity/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController{
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors) {}
}
