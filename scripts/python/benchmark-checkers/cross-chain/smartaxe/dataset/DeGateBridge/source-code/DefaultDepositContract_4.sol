// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;

import "./AddressUtil.sol";
import "./Claimable.sol";
import "./ERC20.sol";
import "./ERC20SafeTransfer.sol";
import "./MathUint.sol";
import "./SafeCast.sol";
import "./IDepositContract.sol";


/// @title DefaultDepositContract
/// @dev   Default implementation of IDepositContract that just stores
///        all funds without doing anything with them.
///
///        Should be able to work with proxy contracts so the contract
///        can be updated easily (but with great caution and transparency!)
///        when necessary.
///
/// @author Brecht Devos - <brecht@loopring.org>
contract DefaultDepositContract is IDepositContract, Claimable
{
    using AddressUtil       for address;
    using ERC20SafeTransfer for address;
    using MathUint          for uint;
    using SafeCast          for uint;

    address public exchange;

    mapping (address => bool) private needCheckBalance;

    modifier onlyExchange()
    {
        require(msg.sender == exchange, "UNAUTHORIZED");
        _;
    }

    modifier ifNotZero(uint amount)
    {
        if (amount == 0) return;
        else  _;
    }

    event CheckBalance(
        address indexed token,
        bool            checkBalance
    );

    receive() external payable { }

    function initialize(
        address _exchange
        )
        external
    {
        require(
            exchange == address(0) && _exchange != address(0),
            "INVALID_EXCHANGE"
        );
        owner = msg.sender;
        exchange = _exchange;
    }

    function setCheckBalance(
        address token,
        bool    checkBalance
        )
        external
        onlyOwner
    {
        require(needCheckBalance[token] != checkBalance, "INVALID_VALUE");

        needCheckBalance[token] = checkBalance;
        emit CheckBalance(token, checkBalance);
    }

    function isTokenSupported(address /*token*/)
        external
        override
        pure
        returns (bool)
    {
        return true;
    }

    function deposit(
        address from,
        address token,
        uint248  amount, // 0-value supported
        bytes   calldata /*extraData*/
        )
        external
        override
        payable
        onlyExchange
        returns (uint248 amountReceived)
    {
        uint ethToReturn = 0;

        if (isETHInternal(token)) {
            require(msg.value >= amount, "INVALID_ETH_DEPOSIT");
            amountReceived = amount;
            ethToReturn = msg.value - amount;
        } else {
            // When checkBalance is enabled for a token we check the balance change
            // on the contract instead of counting on transferFrom to transfer exactly
            // the amount of tokens that is specified in the transferFrom call.
            // This is to support non-standard tokens which do custom transfer logic.
            bool checkBalance = needCheckBalance[token];
            uint balanceBefore = checkBalance ? ERC20(token).balanceOf(address(this)) : 0;

            token.safeTransferFromAndVerify(from, address(this), uint(amount));

            uint balanceAfter = checkBalance ? ERC20(token).balanceOf(address(this)) : amount;
            uint diff = balanceAfter.sub(balanceBefore);
            amountReceived = diff.toUint248();

            ethToReturn = msg.value;
        }

        if (ethToReturn > 0) {
            from.sendETHAndVerify(ethToReturn, gasleft());
        }
    }

    function withdraw(
        address /*from*/,
        address to,
        address token,
        uint    amount
        )
        external
        override
        payable
        onlyExchange
        ifNotZero(amount)
    {
        if (isETHInternal(token)) {
            to.sendETHAndVerify(amount, gasleft());
        } else {
            // Try to transfer the amount requested.
            // If this fails try to transfer the remaining balance in this contract.
            // This is to guard against non-standard token behavior where total supply
            // has changed in unexpected ways.
            if (!token.safeTransfer(to, amount)){
                uint amountPaid = ERC20(token).balanceOf(address(this));
                require(amountPaid < amount, "UNEXPECTED");
                token.safeTransferAndVerify(to, amountPaid);
            }
        }
    }

    function transfer(
        address from,
        address to,
        address token,
        uint    amount
        )
        external
        override
        payable
        onlyExchange
        ifNotZero(amount)
    {
        token.safeTransferFromAndVerify(from, to, amount);
    }

    function isETH(address addr)
        external
        override
        pure
        returns (bool)
    {
        return isETHInternal(addr);
    }

    // -- private --

    function isETHInternal(address addr)
        private
        pure
        returns (bool)
    {
        return addr == address(0);
    }
}