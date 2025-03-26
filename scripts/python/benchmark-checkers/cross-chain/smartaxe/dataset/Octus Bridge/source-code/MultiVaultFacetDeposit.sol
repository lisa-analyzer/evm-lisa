// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetDeposit.sol";
import "../../interfaces/multivault/IMultiVaultFacetFees.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawals.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawalsEvents.sol";
import "../../interfaces/multivault/IMultiVaultFacetWithdraw.sol";
import "../../interfaces/IMultiVaultToken.sol";
import "../../interfaces/IEverscale.sol";
import "../../interfaces/IERC20.sol";
import "../../../interfaces/IWETH.sol";

import "../../libraries/SafeERC20.sol";

import "../storage/MultiVaultStorage.sol";

import "../helpers/MultiVaultHelperEverscale.sol";
import "../helpers/MultiVaultHelperReentrancyGuard.sol";
import "../helpers/MultiVaultHelperTokens.sol";
import "../helpers/MultiVaultHelperFee.sol";
import "../helpers/MultiVaultHelperPendingWithdrawal.sol";
import "../helpers/MultiVaultHelperCallback.sol";
import "../helpers/MultiVaultHelperGas.sol";


contract MultiVaultFacetDeposit is
    MultiVaultHelperFee,
    MultiVaultHelperGas,
    MultiVaultHelperEverscale,
    MultiVaultHelperReentrancyGuard,
    MultiVaultHelperTokens,
    MultiVaultHelperPendingWithdrawal,
    IMultiVaultFacetDeposit,
    MultiVaultHelperCallback
{
    using SafeERC20 for IERC20;

    function depositByNativeToken(
        DepositNativeTokenParams memory d
    )
        external
        payable
        override
        nonReentrant
        wethNotBlacklisted
        initializeWethToken
        onlyEmergencyDisabled
    {
        require(msg.value >= d.amount, "Msg value to low");
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IWETH(s.weth).deposit{value: d.amount}();
        _deposit(
            DepositParams({
            recipient: d.recipient,
            token: s.weth,
            amount: d.amount,
            expected_evers: d.expected_evers,
            payload: d.payload
            }),
            msg.value - d.amount,
            address(this)
        );
    }

    function deposit(
        DepositParams memory d
    )
        external
        payable
        override
        nonReentrant
        tokenNotBlacklisted(d.token)
        initializeToken(d.token)
        onlyEmergencyDisabled
    {
        _deposit(d, msg.value, msg.sender);
    }
    /// @notice Transfer tokens to the Everscale. Works both for native and alien tokens.
    /// Approve is required only for alien tokens deposit.
    /// @param d Deposit parameters
    function _deposit(
        DepositParams memory d,
        uint256 _value,
        address tokens_owner
    ) internal drainGas {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        uint fee = _calculateMovementFee(
            d.amount,
            d.token,
            IMultiVaultFacetFees.Fee.Deposit
        );

        bool isNative = s.tokens_[d.token].isNative;

        // Replace token address with custom token, if specified
        address token = s.tokens_[d.token].custom == address(0) ? d.token : s.tokens_[d.token].custom;

        if (isNative) {
            IMultiVaultToken(token).burn(
                msg.sender,
                d.amount
            );

            d.amount -= fee;

            _transferToEverscaleNative(d, fee, msg.value);
        } else {

            if (tokens_owner != address(this)) {
                IERC20(token).safeTransferFrom(
                    tokens_owner,
                    address(this),
                    d.amount
                );
            }

            d.amount -= fee;

            _transferToEverscaleAlien(d, fee, _value);
        }

        _increaseTokenFee(d.token, fee);
    }

    function depositByNativeToken(
        DepositNativeTokenParams memory d,
        uint256 expectedMinBounty,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId[] memory pendingWithdrawalIds
    )
        external
        payable
        override
        wethNotBlacklisted
        nonReentrant
        initializeWethToken
        onlyEmergencyDisabled
    {
        require(msg.value >= d.amount, "Msg value to low");
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IWETH(s.weth).deposit{value: d.amount}();
        _deposit(
            DepositParams({
                recipient:d.recipient,
                token: s.weth,
                amount: d.amount,
                expected_evers: d.expected_evers,
                payload: d.payload
            }),
            expectedMinBounty,
            pendingWithdrawalIds,
            msg.value - d.amount
        );
    }

    function deposit(
        DepositParams memory d,
        uint256 expectedMinBounty,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId[] memory pendingWithdrawalIds
    )
        external
        payable
        override
        tokenNotBlacklisted(d.token)
        nonReentrant
        initializeToken(d.token)
        onlyEmergencyDisabled
    {
        IERC20(d.token).safeTransferFrom(msg.sender, address(this), d.amount);
        _deposit(d, expectedMinBounty, pendingWithdrawalIds, msg.value);
    }

    function _deposit(
        DepositParams memory d,
        uint256 expectedMinBounty,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId[] memory pendingWithdrawalIds,
        uint256 _value
    ) internal drainGas {
        uint amountLeft = d.amount;
        uint amountPlusBounty = d.amount;


        for (uint i = 0; i < pendingWithdrawalIds.length; i++) {
            IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId = pendingWithdrawalIds[i];
            IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

            require(pendingWithdrawal.amount > 0);
            require(pendingWithdrawal.token == d.token);

            amountLeft -= pendingWithdrawal.amount;
            amountPlusBounty += pendingWithdrawal.bounty;

            _pendingWithdrawalAmountReduce(
                pendingWithdrawalId,
                pendingWithdrawal.amount
            );

            emit PendingWithdrawalFill(
                pendingWithdrawalId.recipient,
                pendingWithdrawalId.id
            );

            IERC20(pendingWithdrawal.token).safeTransfer(
                pendingWithdrawalId.recipient,
                pendingWithdrawal.amount - pendingWithdrawal.bounty
            );

            _callbackAlienWithdrawal(
                IMultiVaultFacetWithdraw.AlienWithdrawalParams({
                    token: pendingWithdrawal.token,
                    amount: pendingWithdrawal.amount,
                    recipient: pendingWithdrawalId.recipient,
                    chainId: pendingWithdrawal.chainId,
                    callback: pendingWithdrawal.callback
                }),
                pendingWithdrawal.amount
            );

        }

        require(amountPlusBounty - d.amount >= expectedMinBounty);

        uint fee = _calculateMovementFee(d.amount, d.token, IMultiVaultFacetFees.Fee.Deposit);

        d.amount = amountPlusBounty - fee;

        _transferToEverscaleAlien(
            d,
            fee,
            _value
        );

        _increaseTokenFee(d.token, fee);
    }
}