// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRadarBridgeFeeManager.sol";
import "./IERC20.sol";

contract FeeManagerV1 is IRadarBridgeFeeManager {
    mapping(address => uint256) private maxTokenFee;
    uint256 constant FEE_BASE = 1000000;
    address private owner;

    uint256 private percentageFee;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    constructor (
        uint256 _percentageFee,
        address[] memory _tokens,
        uint256[] memory _maxFees
    ) {
        require(_percentageFee < FEE_BASE, "Fee too big");
        require(_tokens.length == _maxFees.length, "Invalid maxFees data");

        owner = msg.sender;
        percentageFee = _percentageFee;
        for(uint8 i = 0; i < _tokens.length; i++) {
            maxTokenFee[_tokens[i]] = _maxFees[i];
        }
    }

    // DAO Functions
    function passOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changePercentageFee(uint256 _newFee) external onlyOwner {
        require(_newFee < FEE_BASE, "Fee too big");
        percentageFee = _newFee;
    }

    function changeTokenMaxFee(address _token, uint256 _maxFee) external onlyOwner {
        maxTokenFee[_token] = _maxFee;
    }

    function withdrawTokens(address _token, uint256 _amount, address _receiver) external onlyOwner {
        uint256 _bal = IERC20(_token).balanceOf(address(this));
        uint256 _withdrawAmount = _amount;
        if (_withdrawAmount > _bal) {
            _withdrawAmount = _bal;
        }

        IERC20(_token).transfer(_receiver, _withdrawAmount);
    }

    // Fee Manager Functions

    function getBridgeFee(address _token, address, uint256 _amount, bytes32, address) external override view returns (uint256) {
        uint256 _percFee = percentageFee;

        if (((_amount * _percFee) / FEE_BASE) > maxTokenFee[_token]) {
            if (_amount != 0) {
                _percFee = (maxTokenFee[_token] * FEE_BASE) / _amount;
            } else {
                _percFee = 0;
            }
        }

        return _percFee;
    }

    function getFeeBase() external override view returns (uint256) {
        return FEE_BASE;
    }

    // State Getters
    function getFixedPercRate() external view returns (uint256) {
        return percentageFee;
    }

    function getMaxFeeForToken(address _token) external view returns (uint256) {
        return maxTokenFee[_token];
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}