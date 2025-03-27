// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title LnAccessController
/// @notice LnAccessController is a contract to control the access permission 
/// @dev See https://github.com/helix-bridge/contracts/tree/master/helix-contract
contract LnAccessController {
    address public dao;
    address public operator;
    address public pendingDao;

    mapping(address=>bool) public callerWhiteList;

    modifier onlyDao() {
        require(msg.sender == dao, "!dao");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "!operator");
        _;
    }

    modifier onlyWhiteListCaller() {
        require(callerWhiteList[msg.sender], "caller not in white list");
        _;
    }

    function _initialize(address _dao) internal {
        dao = _dao;
        operator = _dao;
    }

    function setOperator(address _operator) onlyDao external {
        operator = _operator;
    }

    function authoriseAppCaller(address appAddress, bool enable) onlyDao external {
        callerWhiteList[appAddress] = enable;
    }

    function transferOwnership(address _dao) onlyDao external {
        pendingDao = _dao;
    }

    function acceptOwnership() external {
        address newDao = msg.sender;
        require(pendingDao == newDao, "!pendingDao");
        delete pendingDao;
        dao = newDao;
    }
}

