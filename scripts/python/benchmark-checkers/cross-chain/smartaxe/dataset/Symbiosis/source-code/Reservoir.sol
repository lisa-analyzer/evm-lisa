// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Reservoir
 *
 * @dev The contract is used to keep tokens with the function
 * of transfer them to another target address (it is assumed that
 * it will be a contract address).
 */
contract Reservoir is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    address public target;

    event TokensWithdrawn(IERC20 token, uint256 amount);

    /**
     * @dev A constructor sets the address of token and
     * the address of the target contract.
     */
    constructor(IERC20 _token, address _target) {
        token = _token;
        target = _target;
    }

    /**
     * @dev Transfers a certain amount of tokens to the target address.
     *
     * Requirements:
     * - msg.sender should be the target address.
     *
     * @param _requestedTokens The amount of tokens to transfer.
     */
    function drip(uint256 _requestedTokens)
        external
        returns (uint256 sentTokens)
    {
        address target_ = target;
        IERC20 token_ = token;
        require(msg.sender == target_, "Reservoir: permission denied");

        uint256 reservoirBalance = token_.balanceOf(address(this));
        sentTokens = (_requestedTokens > reservoirBalance)
            ? reservoirBalance
            : _requestedTokens;

        token_.safeTransfer(target_, sentTokens);
    }

    /**
     * @dev Transfers ERC20 tokens to the owner.
     *
     * Requirements:
     * - msg.sender should be the owner.
     *
     * @param _token ERC20 token that owner wants to withdraw.
     * @param _amount Amount of ERC20 tokens.
     */
    function withdrawTokens(IERC20 _token, uint256 _amount) external onlyOwner {
        uint256 reservoirBalance = _token.balanceOf(address(this));
        uint256 withdrawalAmount = (_amount > reservoirBalance) ? reservoirBalance : _amount;

        _token.safeTransfer(msg.sender, withdrawalAmount);
        emit TokensWithdrawn(_token, withdrawalAmount);
    }
}