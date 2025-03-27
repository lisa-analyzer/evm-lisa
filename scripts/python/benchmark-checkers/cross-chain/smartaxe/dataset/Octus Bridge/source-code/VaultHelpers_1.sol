// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


import "./Math.sol";
import "./IStrategy.sol";

import "./IERC20.sol";

import "./VaultStorage.sol";


abstract contract VaultHelpers is VaultStorage {
    modifier onlyGovernance() {
        require(msg.sender == governance);

        _;
    }

    modifier onlyPendingGovernance() {
        require(msg.sender == pendingGovernance);

        _;
    }

    modifier onlyStrategyOrGovernanceOrGuardian(address strategyId) {
        require(msg.sender == strategyId || msg.sender == governance || msg.sender == guardian);

        _;
    }

    modifier onlyGovernanceOrManagement() {
        require(msg.sender == governance || msg.sender == management);

        _;
    }

    modifier onlyGovernanceOrGuardian() {
        require(msg.sender == governance || msg.sender == guardian);

        _;
    }

    modifier onlyGovernanceOrWithdrawGuardian() {
        require(msg.sender == governance || msg.sender == withdrawGuardian);

        _;
    }

    modifier onlyGovernanceOrStrategyRewardsManager(address strategyId) {
        require(msg.sender == governance || msg.sender == strategies_[strategyId].rewardsManager);

        _;
    }

    modifier pendingWithdrawalOpened(
        PendingWithdrawalId memory pendingWithdrawalId
    ) {
        PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

        require(pendingWithdrawal.amount > 0, "Vault: pending withdrawal closed");

        _;
    }

    modifier pendingWithdrawalApproved(
        PendingWithdrawalId memory pendingWithdrawalId
    ) {
        PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

        require(
            pendingWithdrawal.approveStatus == ApproveStatus.NotRequired ||
            pendingWithdrawal.approveStatus == ApproveStatus.Approved,
            "Vault: pending withdrawal not approved"
        );

        _;
    }

    modifier strategyExists(address strategyId) {
        StrategyParams memory strategy = _strategy(strategyId);

        require(strategy.activation > 0, "Vault: strategy not exists");

        _;
    }

    modifier strategyNotExists(address strategyId) {
        StrategyParams memory strategy = _strategy(strategyId);

        require(strategy.activation == 0, "Vault: strategy exists");

        _;
    }

    modifier respectDepositLimit(uint amount) {
        require(
            _totalAssets() + amount <= depositLimit,
            "Vault: respect the deposit limit"
        );

        _;
    }

    modifier onlyEmergencyDisabled() {
        require(!emergencyShutdown, "Vault: emergency mode enabled");

        _;
    }

    modifier withdrawalNotSeenBefore(bytes memory payload) {
        bytes32 withdrawalId = keccak256(payload);

        require(!withdrawalIds[withdrawalId], "Vault: withdraw payload already seen");

        _;

        withdrawalIds[withdrawalId] = true;
    }

    function decodeWithdrawalEventData(
        bytes memory eventData
    ) public view override returns(WithdrawalParams memory) {
        (
            int8 sender_wid,
            uint256 sender_addr,
            uint128 amount,
            uint160 recipient,
            uint32 chainId
        ) = abi.decode(
            eventData,
            (int8, uint256, uint128, uint160, uint32)
        );

        return WithdrawalParams({
            sender: EverscaleAddress(sender_wid, sender_addr),
            amount: convertFromTargetDecimals(amount),
            recipient: address(recipient),
            chainId: chainId
        });
    }

    //8b           d8   db        88        88  88      888888888888
    //`8b         d8'  d88b       88        88  88           88
    // `8b       d8'  d8'`8b      88        88  88           88
    //  `8b     d8'  d8'  `8b     88        88  88           88
    //   `8b   d8'  d8YaaaaY8b    88        88  88           88
    //    `8b d8'  d8""""""""8b   88        88  88           88
    //     `888'  d8'        `8b  Y8a.    .a8P  88           88
    //      `8'  d8'          `8b  `"Y8888Y"'   88888888888  88
    function _vaultTokenBalance() internal view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function _debtRatioReduce(
        uint256 amount
    ) internal {
        debtRatio -= amount;
    }

    function _debtRatioIncrease(
        uint256 amount
    ) internal {
        debtRatio += amount;
    }

    function _totalAssets() internal view returns (uint256) {
        return _vaultTokenBalance() + totalDebt;
    }

    function _calculateLockedProfit() internal view returns (uint256) {
        uint256 lockedFundsRatio = (block.timestamp - lastReport) * lockedProfitDegradation;

        if (lockedFundsRatio < DEGRADATION_COEFFICIENT) {
            uint256 _lockedProfit = lockedProfit;

            return _lockedProfit - (lockedFundsRatio * _lockedProfit / DEGRADATION_COEFFICIENT);
        } else {
            return 0;
        }
    }

    function convertFromTargetDecimals(
        uint256 amount
    ) public view returns (uint256) {
        if (targetDecimals == tokenDecimals) {
            return amount;
        } else if (targetDecimals > tokenDecimals) {
            return amount / 10 ** (targetDecimals - tokenDecimals);
        } else {
            return amount * 10 ** (tokenDecimals - targetDecimals);
        }
    }

    function convertToTargetDecimals(
        uint256 amount
    ) public view returns (uint256) {
        if (targetDecimals == tokenDecimals) {
            return amount;
        } else if (targetDecimals > tokenDecimals) {
            return amount * 10 ** (targetDecimals - tokenDecimals);
        } else {
            return amount / 10 ** (tokenDecimals - targetDecimals);
        }
    }

    function _calculateMovementFee(
        uint256 amount,
        uint256 fee
    ) internal pure returns (uint256) {
        if (fee == 0) return 0;

        return amount * fee / MAX_BPS;
    }

    // ad88888ba  888888888888  88888888ba          db    888888888888  88888888888  ,ad8888ba,  8b        d8
    //d8"     "8b      88       88      "8b        d88b        88       88          d8"'    `"8b  Y8,    ,8P
    //Y8,              88       88      ,8P       d8'`8b       88       88         d8'             Y8,  ,8P
    //`Y8aaaaa,        88       88aaaaaa8P'      d8'  `8b      88       88aaaaa    88               "8aa8"
    //  `"""""8b,      88       88""""88'       d8YaaaaY8b     88       88"""""    88      88888     `88'
    //        `8b      88       88    `8b      d8""""""""8b    88       88         Y8,        88      88
    //Y8a     a8P      88       88     `8b    d8'        `8b   88       88          Y8a.    .a88      88
    // "Y88888P"       88       88      `8b  d8'          `8b  88       88888888888  `"Y88888P"       88
    function _strategy(
        address strategyId
    ) internal view returns (StrategyParams memory) {
        return strategies_[strategyId];
    }

    function _strategyCreate(
        address strategyId,
        StrategyParams memory strategyParams
    ) internal {
        strategies_[strategyId] = strategyParams;
    }

    function _strategyRewardsUpdate(
        address strategyId,
        EverscaleAddress memory _rewards
    ) internal {
        strategies_[strategyId].rewards = _rewards;
    }

    function _strategyDebtRatioUpdate(
        address strategyId,
        uint256 debtRatio
    ) internal {
        strategies_[strategyId].debtRatio = debtRatio;
    }

    function _strategyLastReportUpdate(
        address strategyId
    ) internal {
        strategies_[strategyId].lastReport = block.timestamp;
        lastReport = block.timestamp;
    }

    function _strategyTotalDebtReduce(
        address strategyId,
        uint256 debtPayment
    ) internal {
        strategies_[strategyId].totalDebt -= debtPayment;
        totalDebt -= debtPayment;
    }

    function _strategyTotalDebtIncrease(
        address strategyId,
        uint256 credit
    ) internal {
        strategies_[strategyId].totalDebt += credit;
        totalDebt += credit;
    }

    function _strategyDebtOutstanding(
        address strategyId
    ) internal view returns (uint256) {
        StrategyParams memory strategy = _strategy(strategyId);

        if (debtRatio == 0) return strategy.totalDebt;

        uint256 strategy_debtLimit = strategy.debtRatio * _totalAssets() / MAX_BPS;

        if (emergencyShutdown) {
            return strategy.totalDebt;
        } else if (strategy.totalDebt <= strategy_debtLimit) {
            return 0;
        } else {
            return strategy.totalDebt - strategy_debtLimit;
        }
    }

    function _strategyCreditAvailable(
        address strategyId
    ) internal view returns (uint256) {
        if (emergencyShutdown) return 0;

        uint256 vault_totalAssets = _totalAssets();

        // Cant extend Strategies debt until total amount of pending withdrawals is more than Vault's total assets
        if (pendingWithdrawalsTotal >= vault_totalAssets) return 0;

        uint256 vault_debtLimit = debtRatio * vault_totalAssets / MAX_BPS;
        uint256 vault_totalDebt = totalDebt;

        StrategyParams memory strategy = _strategy(strategyId);

        uint256 strategy_debtLimit = strategy.debtRatio * vault_totalAssets / MAX_BPS;

        // Exhausted credit line
        if (strategy_debtLimit <= strategy.totalDebt || vault_debtLimit <= vault_totalDebt) return 0;

        // Start with debt limit left for the Strategy
        uint256 available = strategy_debtLimit - strategy.totalDebt;

        // Adjust by the global debt limit left
        available = Math.min(available, vault_debtLimit - vault_totalDebt);

        // Can only borrow up to what the contract has in reserve
        // NOTE: Running near 100% is discouraged
        available = Math.min(available, IERC20(token).balanceOf(address(this)));

        // Adjust by min and max borrow limits (per harvest)
        // NOTE: min increase can be used to ensure that if a strategy has a minimum
        //       amount of capital needed to purchase a position, it's not given capital
        //       it can't make use of yet.
        // NOTE: max increase is used to make sure each harvest isn't bigger than what
        //       is authorized. This combined with adjusting min and max periods in
        //       `BaseStrategy` can be used to effect a "rate limit" on capital increase.
        if (available < strategy.minDebtPerHarvest) {
            return 0;
        } else {
            return Math.min(available, strategy.maxDebtPerHarvest);
        }
    }

    function _strategyTotalGainIncrease(
        address strategyId,
        uint256 amount
    ) internal {
        strategies_[strategyId].totalGain += amount;
    }

    function _strategyExpectedReturn(
        address strategyId
    ) internal view returns (uint256) {
        StrategyParams memory strategy = _strategy(strategyId);

        uint256 timeSinceLastHarvest = block.timestamp - strategy.lastReport;
        uint256 totalHarvestTime = strategy.lastReport - strategy.activation;

        if (timeSinceLastHarvest > 0 && totalHarvestTime > 0 && IStrategy(strategyId).isActive()) {
            return strategy.totalGain * timeSinceLastHarvest / totalHarvestTime;
        } else {
            return 0;
        }
    }

    function _strategyDebtRatioReduce(
        address strategyId,
        uint256 amount
    ) internal {
        strategies_[strategyId].debtRatio -= amount;
        debtRatio -= amount;
    }

    function _strategyRevoke(
        address strategyId
    ) internal {
        _strategyDebtRatioReduce(strategyId, strategies_[strategyId].debtRatio);
    }

    function _strategyMinDebtPerHarvestUpdate(
        address strategyId,
        uint256 minDebtPerHarvest
    ) internal {
        strategies_[strategyId].minDebtPerHarvest = minDebtPerHarvest;
    }

    function _strategyMaxDebtPerHarvestUpdate(
        address strategyId,
        uint256 maxDebtPerHarvest
    ) internal {
        strategies_[strategyId].maxDebtPerHarvest = maxDebtPerHarvest;
    }


    function _strategyReportLoss(
        address strategyId,
        uint256 loss
    ) internal {
        StrategyParams memory strategy = _strategy(strategyId);

        uint256 totalDebt = strategy.totalDebt;

        // Loss can only be up the amount of debt issued to strategy
        require(loss <= totalDebt);

        // Also, make sure we reduce our trust with the strategy by the amount of loss
        if (debtRatio != 0) { // if vault with single strategy that is set to EmergencyOne
            // NOTE: The context to this calculation is different than the calculation in `_reportLoss`,
            // this calculation intentionally approximates via `totalDebt` to avoid manipulable results
            // NOTE: This calculation isn't 100% precise, the adjustment is ~10%-20% more severe due to EVM math
            uint256 ratio_change = Math.min(
                loss * debtRatio / totalDebt,
                strategy.debtRatio
            );

            _strategyDebtRatioReduce(strategyId, ratio_change);
        }

        // Finally, adjust our strategy's parameters by the loss
        strategies_[strategyId].totalLoss += loss;

        _strategyTotalDebtReduce(strategyId, loss);
    }

    //88888888ba   88888888888  888b      88  88888888ba,    88  888b      88    ,ad8888ba,
    //88      "8b  88           8888b     88  88      `"8b   88  8888b     88   d8"'    `"8b
    //88      ,8P  88           88 `8b    88  88        `8b  88  88 `8b    88  d8'
    //88aaaaaa8P'  88aaaaa      88  `8b   88  88         88  88  88  `8b   88  88
    //88""""""'    88"""""      88   `8b  88  88         88  88  88   `8b  88  88      88888
    //88           88           88    `8b 88  88         8P  88  88    `8b 88  Y8,        88
    //88           88           88     `8888  88      .a8P   88  88     `8888   Y8a.    .a88
    //88           88888888888  88      `888  88888888Y"'    88  88      `888    `"Y88888P"
    function _pendingWithdrawal(
        PendingWithdrawalId memory pendingWithdrawalId
    ) internal view returns (PendingWithdrawalParams memory) {
        return pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id];
    }

    function _pendingWithdrawalCreate(
        address recipient,
        uint256 amount,
        uint256 timestamp
    ) internal returns (uint256 pendingWithdrawalId) {
        pendingWithdrawalId = pendingWithdrawalsPerUser[recipient];
        pendingWithdrawalsPerUser[recipient]++;

        pendingWithdrawals_[recipient][pendingWithdrawalId] = PendingWithdrawalParams({
            amount: amount,
            timestamp: timestamp,
            bounty: 0,
            approveStatus: ApproveStatus.NotRequired
        });

        pendingWithdrawalsTotal += amount;

        return pendingWithdrawalId;
    }

    function _pendingWithdrawalBountyUpdate(
        PendingWithdrawalId memory pendingWithdrawalId,
        uint bounty
    ) internal {
        pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].bounty = bounty;

        emit PendingWithdrawalUpdateBounty(pendingWithdrawalId.recipient, pendingWithdrawalId.id, bounty);
    }

    function _pendingWithdrawalAmountReduce(
        PendingWithdrawalId memory pendingWithdrawalId,
        uint amount
    ) internal {
        pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].amount -= amount;
        pendingWithdrawalsTotal -= amount;
    }

    function _pendingWithdrawalApproveStatusUpdate(
        PendingWithdrawalId memory pendingWithdrawalId,
        ApproveStatus approveStatus
    ) internal {
        pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].approveStatus = approveStatus;

        emit PendingWithdrawalUpdateApproveStatus(
            pendingWithdrawalId.recipient,
            pendingWithdrawalId.id,
            approveStatus
        );
    }

    //88888888ba   88888888888  88888888ba   88    ,ad8888ba,    88888888ba,
    //88      "8b  88           88      "8b  88   d8"'    `"8b   88      `"8b
    //88      ,8P  88           88      ,8P  88  d8'        `8b  88        `8b
    //88aaaaaa8P'  88aaaaa      88aaaaaa8P'  88  88          88  88         88
    //88""""""'    88"""""      88""""88'    88  88          88  88         88
    //88           88           88    `8b    88  Y8,        ,8P  88         8P
    //88           88           88     `8b   88   Y8a.    .a8P   88      .a8P
    //88           88888888888  88      `8b  88    `"Y8888Y"'    88888888Y"'

    function _withdrawalPeriodDeriveId(
        uint256 timestamp
    ) internal pure returns (uint256) {
        return timestamp / WITHDRAW_PERIOD_DURATION_IN_SECONDS;
    }

    function _withdrawalPeriod(
        uint256 timestamp
    ) internal view returns (WithdrawalPeriodParams memory) {
        return withdrawalPeriods_[_withdrawalPeriodDeriveId(timestamp)];
    }

    function _withdrawalPeriodIncreaseTotalByTimestamp(
        uint256 timestamp,
        uint256 amount
    ) internal {
        uint withdrawalPeriodId = _withdrawalPeriodDeriveId(timestamp);

        withdrawalPeriods_[withdrawalPeriodId].total += amount;
    }

    function _withdrawalPeriodIncreaseConsideredByTimestamp(
        uint256 timestamp,
        uint256 amount
    ) internal {
        uint withdrawalPeriodId = _withdrawalPeriodDeriveId(timestamp);

        withdrawalPeriods_[withdrawalPeriodId].considered += amount;
    }

    function _withdrawalPeriodCheckLimitsPassed(
        uint amount,
        WithdrawalPeriodParams memory withdrawalPeriod
    ) internal view returns (bool) {
        return  amount < undeclaredWithdrawLimit &&
        amount + withdrawalPeriod.total - withdrawalPeriod.considered < withdrawLimitPerPeriod;
    }

    function _getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}