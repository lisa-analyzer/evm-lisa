pragma solidity ^0.8.13;

// SPDX-License-Identifier: MIT



import "./IMailbox.sol";
import "./IGovernance.sol";
import "./IExecutor.sol";
import "./IDiamondCut.sol";
import "./IGetters.sol";

interface IZkSync is IMailbox, IGovernance, IExecutor, IDiamondCut, IGetters {}