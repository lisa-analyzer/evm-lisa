// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./../interfaces/IERC20Mintable.sol";
import "./../interfaces/IBridge.sol";

import "./VaultStorage.sol";

import "hardhat/console.sol";

string constant API_VERSION = '0.1.0';


contract Vault is VaultStorage {
    using SafeERC20 for IERC20;
    address constant MULTIVAULT = 0x54c55369A6900731D22eACb0DF7C0253CF19dFff;

    modifier onlyGovernance() {
        require(msg.sender == governance);

        _;
    }

    modifier onlyPendingGovernance() {
        require(msg.sender == pendingGovernance);

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

    function initialize(
        address _bridge,
        address _governance,
        address _token,
        EverscaleAddress memory _rewards
    ) external override initializer {
        bridge = _bridge;
        emit UpdateBridge(bridge);

        governance = _governance;
        emit UpdateGovernance(governance);

        rewards_ = _rewards;
        emit UpdateRewards(rewards_.wid, rewards_.addr);

        withdrawFee = 0;
        emit UpdateWithdrawFee(0);

        depositFee = 0;
        emit UpdateDepositFee(0);

        token = _token;
    }

    /**
        @notice Vault API version. Used to track the deployed version of this contract.
        @return api_version Current API version
    */
    function apiVersion()
        external
        override
        pure
    returns (string memory api_version)
    {
        return API_VERSION;
    }

    /**
        @notice Set deposit fee. Must be less than `MAX_BPS`.
        This may be called only by `governance` or `management`.
        @param _depositFee Deposit fee, must be less than `MAX_BPS / 2`.
    */
    function setDepositFee(
        uint _depositFee
    ) external override onlyGovernanceOrManagement {
        require(_depositFee <= MAX_BPS / 2);

        depositFee = _depositFee;

        emit UpdateDepositFee(depositFee);
    }

    /**
        @notice Set withdraw fee. Must be less than `MAX_BPS`.
        This may be called only by `governance` or `management`
        @param _withdrawFee Withdraw fee, must be less than `MAX_BPS / 2`.
    */
    function setWithdrawFee(
        uint _withdrawFee
    ) external override onlyGovernanceOrManagement {
        require(_withdrawFee <= MAX_BPS / 2);

        withdrawFee = _withdrawFee;

        emit UpdateWithdrawFee(withdrawFee);
    }

    /// @notice Set configuration_ address.
    /// @param _configuration The address to use for configuration_.
    function setConfiguration(
        EverscaleAddress memory _configuration
    ) external override onlyGovernance {
        configuration_ = _configuration;

        emit UpdateConfiguration(configuration_.wid, configuration_.addr);
    }

    /// @notice Nominate new address to use as a governance.
    /// The change does not go into effect immediately. This function sets a
    /// pending change, and the governance address is not updated until
    /// the proposed governance address has accepted the responsibility.
    /// This may only be called by the `governance`.
    /// @param _governance The address requested to take over Vault governance.
    function setGovernance(
        address _governance
    ) external override onlyGovernance {
        pendingGovernance = _governance;

        emit NewPendingGovernance(pendingGovernance);
    }

    /// @notice Once a new governance address has been proposed using `setGovernance`,
    /// this function may be called by the proposed address to accept the
    /// responsibility of taking over governance for this contract.
    /// This may only be called by the `pendingGovernance`.
    function acceptGovernance()
        external
        override
        onlyPendingGovernance
    {
        governance = pendingGovernance;

        emit UpdateGovernance(governance);
    }

    /// @notice Changes the address of `guardian`.
    /// This may only be called by `governance` or `guardian`.
    /// @param _guardian The new guardian address to use.
    function setGuardian(
        address _guardian
    ) external override onlyGovernanceOrGuardian {
        guardian = _guardian;

        emit UpdateGuardian(guardian);
    }

    /// @notice Changes the management address.
    /// This may only be called by `governance`
    /// @param _management The address to use for management.
    function setManagement(
        address _management
    )
        external
        override
        onlyGovernance
    {
        management = _management;

        emit UpdateManagement(management);
    }

    /// @notice Set address to receive rewards_ (fees, gains, etc)
    /// This may be called only by `governance`
    /// @param _rewards Rewards receiver in Everscale network
    function setRewards(
        EverscaleAddress memory _rewards
    ) external override onlyGovernance {
        rewards_ = _rewards;

        emit UpdateRewards(rewards_.wid, rewards_.addr);
    }

    function transferTokenOwnership() external onlyGovernance {
        Ownable(token).transferOwnership(MULTIVAULT);
    }

    /// @notice Activates or deactivates Vault emergency mode, where all Strategies go into full withdrawal.
    ///     During emergency shutdown:
    ///     - Deposits are disabled
    ///     - Withdrawals are disabled (all types of withdrawals)
    ///     - Each Strategy must pay back their debt as quickly as reasonable to minimally affect their position
    ///     - Only `governance` may undo Emergency Shutdown
    /// This may only be called by `governance` or `guardian`.
    /// @param active If `true`, the Vault goes into Emergency Shutdown. If `false`, the Vault goes back into
    ///     Normal Operation.
    function setEmergencyShutdown(
        bool active
    ) external override {
        if (active) {
            require(msg.sender == guardian || msg.sender == governance);
        } else {
            require(msg.sender == governance);
        }

        emergencyShutdown = active;

        emit EmergencyShutdown(active);
    }

    /// @notice Deposits `token` into the Vault, leads to producing corresponding token
    /// on the Everscale side.
    /// @param recipient Recipient in the Everscale network
    /// @param amount Amount of `token` to deposit
    function deposit(
        EverscaleAddress memory recipient,
        uint256 amount
    )
        public
        override
        onlyEmergencyDisabled
        nonReentrant
    {
        IERC20Mintable(token).burn(msg.sender, amount);

        uint256 fee = _calculateMovementFee(amount, depositFee);

        _transferToEverscale(recipient, amount - fee);

        if (fee > 0) fees += fee;

        emit UserDeposit(msg.sender, recipient.wid, recipient.addr, amount, address(0), 0, 0);

    }

    function depositToFactory(
        uint128 amount,
        int8 wid,
        uint256 user,
        uint256 creditor,
        uint256 recipient,
        uint128 tokenAmount,
        uint128 tonAmount,
        uint8 swapType,
        uint128 slippageNumerator,
        uint128 slippageDenominator,
        bytes memory level3
    )
        external
        override
        onlyEmergencyDisabled
    {
        require(
            tokenAmount <= amount &&
            swapType < 2 &&
            user != 0 &&
            recipient != 0 &&
            creditor != 0 &&
            slippageNumerator < slippageDenominator,
            "Wrapper: wrong args"
        );

        IERC20Mintable(token).burn(msg.sender, amount);

        uint256 fee = _calculateMovementFee(amount, depositFee);

        if (fee > 0) fees += fee;

        emit FactoryDeposit(
            amount - uint128(fee),
            wid,
            user,
            creditor,
            recipient,
            tokenAmount,
            tonAmount,
            swapType,
            slippageNumerator,
            slippageDenominator,
            0x07,
            level3
        );
    }

    /**
        @notice Save withdrawal receipt. If Vault has enough tokens and withdrawal passes the
            limits, then it's executed immediately. Otherwise it's saved as a pending withdrawal.
        @param payload Withdrawal receipt. Bytes encoded `struct EverscaleEvent`.
        @param signatures List of relay's signatures. See not on `Bridge.verifySignedEverscaleEvent`.
    */
    function saveWithdraw(
        bytes memory payload,
        bytes[] memory signatures
    )
        external
        override
        onlyEmergencyDisabled
        withdrawalNotSeenBefore(payload)
    {
        require(
            IBridge(bridge).verifySignedEverscaleEvent(payload, signatures) == 0,
            "Vault: signatures verification failed"
        );

        // Decode Everscale event
        (EverscaleEvent memory _event) = abi.decode(payload, (EverscaleEvent));

        require(
            _event.configurationWid == configuration_.wid &&
            _event.configurationAddress == configuration_.addr
        );

        bytes32 payloadId = keccak256(payload);

        // Decode event data
        WithdrawalParams memory withdrawal = decodeWithdrawalEventData(_event.eventData);

        require(withdrawal.chainId == _getChainID());

        // Ensure withdrawal fee
        uint256 fee = _calculateMovementFee(withdrawal.amount, withdrawFee);

        if (fee > 0) fees += fee;

        IERC20Mintable(token).mint(withdrawal.recipient, withdrawal.amount - fee);

        emit InstantWithdrawal(payloadId, withdrawal.recipient, withdrawal.amount - fee);
    }

    /**
        @notice Removes tokens from this Vault that are not the type of token managed
            by this Vault. This may be used in case of accidentally sending the
            wrong kind of token to this Vault.

            Tokens will be sent to `governance`.

            This will fail if an attempt is made to sweep the tokens that this
            Vault manages.

            This may only be called by `governance`.
        @param _token The token to transfer out of this vault.
    */
    function sweep(
        address _token
    ) external override onlyGovernance {
        require(token != _token);

        uint256 amount = IERC20(_token).balanceOf(address(this));

        IERC20(_token).safeTransfer(governance, amount);
    }

    /// @notice Skim fees
    /// Can be called only by governance or management
    /// @param skim_to_everscale Skim fees to Everscale or not
    function skim(
        bool skim_to_everscale
    ) external override nonReentrant onlyGovernanceOrManagement {
        require(fees > 0);

        if (skim_to_everscale) {
            _transferToEverscale(rewards_, fees);
        } else {
            IERC20Mintable(token).mint(governance, fees);
        }

        fees = 0;
    }

    function decodeWithdrawalEventData(
        bytes memory eventData
    ) public pure override returns(WithdrawalParams memory) {
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
            amount: amount,
            recipient: address(recipient),
            chainId: chainId
        });
    }

    function _calculateMovementFee(
        uint256 amount,
        uint256 fee
    ) internal pure returns (uint256) {
        if (fee == 0) return 0;

        return amount * fee / MAX_BPS;
    }

    function _transferToEverscale(
        EverscaleAddress memory recipient,
        uint256 amount
    ) internal {
        emit Deposit(amount, recipient.wid, recipient.addr);
    }

    function _getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}