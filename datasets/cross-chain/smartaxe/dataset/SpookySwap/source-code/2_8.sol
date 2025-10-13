// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface ierc20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

abstract contract SpookyApprovals {
    mapping(address => mapping(address => bool)) isApproved;

    function _approveIfNeeded(address _token, address _spender) internal {
        if(!isApproved[_token][_spender]) {
            ierc20(_token).approve(_spender, 2**256 - 1);
            isApproved[_token][_spender] = true;
        }
    }

}