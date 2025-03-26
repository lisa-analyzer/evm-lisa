// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../IEverscale.sol";
import "./IMultiVaultFacetPendingWithdrawals.sol";


interface IMultiVaultFacetDeposit {
    struct DepositParams {
        IEverscale.EverscaleAddress recipient;
        address token;
        uint amount;
        uint expected_evers;
        bytes payload;
    }

    struct DepositNativeTokenParams {
        IEverscale.EverscaleAddress recipient;
        uint amount;
        uint expected_evers;
        bytes payload;
    }

    function depositByNativeToken(
        DepositNativeTokenParams memory d
    ) external payable;

    function depositByNativeToken(
        DepositNativeTokenParams memory d,
        uint256 expectedMinBounty,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external payable;

    function deposit(
        DepositParams memory d
    ) external payable;

    function deposit(
        DepositParams memory d,
        uint256 expectedMinBounty,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external payable;
}