// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./interfaces/IERC20.sol";
import "./interfaces/IMultiVault.sol";
import "./interfaces/IMultiVaultToken.sol";
import "./interfaces/IBridge.sol";

import "./libraries/SafeERC20.sol";
import "./libraries/MultiVaultLibrary.sol";

import "./utils/Initializable.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/ChainId.sol";

import "./MultiVaultToken.sol";


uint constant MAX_BPS = 10_000;
uint constant FEE_LIMIT = MAX_BPS / 2;

uint8 constant DECIMALS_LIMIT = 18;
uint256 constant SYMBOL_LENGTH_LIMIT = 32;
uint256 constant NAME_LENGTH_LIMIT = 32;

string constant DEFAULT_NAME_PREFIX = 'Octus ';
string constant DEFAULT_SYMBOL_PREFIX = 'oct';


string constant API_VERSION = '0.1.3';


/// @notice Vault, based on Octus Bridge. Allows to transfer arbitrary tokens from Everscale
/// to EVM and backwards. Everscale tokens are called "natives" (eg QUBE). EVM tokens are called
/// "aliens" (eg AAVE).
/// Inspired by Yearn Vault V2.
contract MultiVault is IMultiVault, ReentrancyGuard, Initializable, ChainId {
    using SafeERC20 for IERC20;

    function getInitHash() public pure returns(bytes32) {
        bytes memory bytecode = type(MultiVaultToken).creationCode;
        return keccak256(abi.encodePacked(bytecode));
    }

    mapping (address => Token) tokens_;
    mapping (address => EverscaleAddress) natives_;

    uint public override defaultNativeDepositFee;
    uint public override defaultNativeWithdrawFee;
    uint public override defaultAlienDepositFee;
    uint public override defaultAlienWithdrawFee;

    bool public override emergencyShutdown;

    address public override bridge;
    mapping(bytes32 => bool) public override withdrawalIds;
    EverscaleAddress rewards_;
    EverscaleAddress configurationNative_;
    EverscaleAddress configurationAlien_;

    address public override governance;
    address pendingGovernance;
    address public override guardian;
    address public override management;

    mapping (address => TokenPrefix) prefixes_;
    mapping (address => uint) public override fees;

    // STORAGE UPDATE 1
    // Pending withdrawals
    // - Counter pending withdrawals per user
    mapping(address => uint) public override pendingWithdrawalsPerUser;
    // - Pending withdrawal details
    mapping(address => mapping(uint256 => PendingWithdrawalParams)) pendingWithdrawals_;

    function pendingWithdrawals(
        address user,
        uint256 id
    ) external view override returns (PendingWithdrawalParams memory) {
        return pendingWithdrawals_[user][id];
    }

    // - Total amount of pending withdrawals per token
    mapping(address => uint) public override pendingWithdrawalsTotal;


    modifier tokenNotBlacklisted(address token) {
        require(!tokens_[token].blacklisted);

        _;
    }

    modifier initializeToken(address token) {
        if (tokens_[token].activation == 0) {
            // Non-activated tokens are always aliens, native tokens are activate on the first `saveWithdrawNative`

            require(
                IERC20Metadata(token).decimals() <= DECIMALS_LIMIT &&
                bytes(IERC20Metadata(token).symbol()).length <= SYMBOL_LENGTH_LIMIT &&
                bytes(IERC20Metadata(token).name()).length <= NAME_LENGTH_LIMIT
            );

            _activateToken(token, false);
        }

        _;
    }

    modifier onlyEmergencyDisabled() {
        require(!emergencyShutdown, "Vault: emergency mode enabled");

        _;
    }

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

    modifier withdrawalNotSeenBefore(bytes memory payload) {
        bytes32 withdrawalId = keccak256(payload);

        require(!withdrawalIds[withdrawalId], "Vault: withdraw payload already seen");

        _;

        withdrawalIds[withdrawalId] = true;
    }

    modifier respectFeeLimit(uint fee) {
        require(fee <= FEE_LIMIT);

        _;
    }

    /// @notice Get token prefix
    /// @dev Used to set up in advance prefix for the ERC20 native token
    /// @param _token Token address
    /// @return Name and symbol prefix
    function prefixes(
        address _token
    ) external view override returns (TokenPrefix memory) {
        return prefixes_[_token];
    }

    /// @notice Get token information
    /// @param _token Token address
    function tokens(
        address _token
    ) external view override returns (Token memory) {
        return tokens_[_token];
    }

    /// @notice Get native Everscale token address for EVM token
    /// @param _token Token address
    function natives(
        address _token
    ) external view override returns (EverscaleAddress memory) {
        return natives_[_token];
    }

    /// @notice Rewards address
    /// @return Everscale address, used for collecting rewards.
    function rewards()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return rewards_;
    }

    /// @notice Native configuration address
    /// @return Everscale address, used for verifying native withdrawals
    function configurationNative()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return configurationNative_;
    }

    /// @notice Alien configuration address
    /// @return Everscale address, used for verifying alien withdrawals
    function configurationAlien()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return configurationAlien_;
    }

    /// @notice Vault API version. Used to track the deployed version of this contract.
    //  @return api_version Current API version
    function apiVersion()
        external
        override
        pure
        returns (string memory api_version)
    {
        return API_VERSION;
    }

    /// @notice MultiVault initializer
    /// @param _bridge Bridge address
    /// @param _governance Governance address
    function initialize(
        address _bridge,
        address _governance
    ) external override initializer {
        bridge = _bridge;
        emit UpdateBridge(bridge);

        governance = _governance;
        emit UpdateGovernance(governance);
    }

    /// @notice Set prefix for native token
    /// @param token Expected native token address, see note on `getNative`
    /// @param name_prefix Name prefix, leave empty for no-prefix
    /// @param symbol_prefix Symbol prefix, leave empty for no-prefix
    function setPrefix(
        address token,
        string memory name_prefix,
        string memory symbol_prefix
    ) external override onlyGovernanceOrManagement {
        TokenPrefix memory prefix = prefixes_[token];

        if (prefix.activation == 0) {
            prefix.activation = block.number;
        }

        prefix.name = name_prefix;
        prefix.symbol = symbol_prefix;

        prefixes_[token] = prefix;

        emit UpdateTokenPrefix(token, name_prefix, symbol_prefix);
    }

    /// @notice Add token to blacklist. Only native token can be blacklisted.
    /// Blacklisted tokens cant be deposited or withdrawn.
    /// @param token Token address
    function blacklistAddToken(
        address token
    ) public override onlyGovernance tokenNotBlacklisted(token) {
        tokens_[token].blacklisted = true;

        emit BlacklistTokenAdded(token);
    }

    /// @notice Remove token from blacklist.
    /// @param token Token address
    function blacklistRemoveToken(
        address token
    ) external override onlyGovernance {
        require(tokens_[token].blacklisted);

        tokens_[token].blacklisted = false;

        emit BlacklistTokenRemoved(token);
    }

    /// @notice Set address to receive fees.
    /// This may be called only by `governance`
    /// @param _rewards Rewards receiver in Everscale network
    function setRewards(
        EverscaleAddress memory _rewards
    ) external override onlyGovernance {
        rewards_ = _rewards;

        emit UpdateRewards(rewards_.wid, rewards_.addr);
    }

    /// @notice Set default deposit fee for native tokens.
    /// Charged on the `deposit`.
    /// @param fee Fee amount, should be less than FEE_LIMIT
    function setDefaultNativeDepositFee(
        uint fee
    )
        external
        override
        onlyGovernanceOrManagement
        respectFeeLimit(fee)
    {
        defaultNativeDepositFee = fee;

        emit UpdateDefaultNativeDepositFee(fee);
    }

    /// @notice Set default withdraw fee for native tokens.
    /// Charged on the `saveWithdrawNative`.
    /// @param fee Fee amount, should be less than FEE_LIMIT
    function setDefaultNativeWithdrawFee(
        uint fee
    )
        external
        override
        onlyGovernanceOrManagement
        respectFeeLimit(fee)
    {
        defaultNativeWithdrawFee = fee;

        emit UpdateDefaultNativeWithdrawFee(fee);
    }

    /// @notice Set default deposit fee for alien tokens.
    /// Charged on the `deposit`.
    /// @param fee Fee amount, should be less than FEE_LIMIT
    function setDefaultAlienDepositFee(
        uint fee
    )
        external
        override
        onlyGovernanceOrManagement
        respectFeeLimit(fee)
    {
        defaultAlienDepositFee = fee;

        emit UpdateDefaultAlienDepositFee(fee);
    }

    /// @notice Set default withdraw fee for alien tokens.
    /// Charged on the `saveWithdrawAlien`.
    /// @param fee Fee amount, should be less than FEE_LIMIT
    function setDefaultAlienWithdrawFee(
        uint fee
    )
        external
        override
        onlyGovernanceOrManagement
        respectFeeLimit(fee)
    {
        defaultAlienWithdrawFee = fee;

        emit UpdateDefaultAlienWithdrawFee(fee);
    }

    /// @notice Set deposit fee for specific token.
    /// This may be called only by `owner` or `management`.
    /// @param token Token address
    /// @param _depositFee Deposit fee, must be less than FEE_LIMIT.
    function setTokenDepositFee(
        address token,
        uint _depositFee
    )
        public
        override
        onlyGovernanceOrManagement
        respectFeeLimit(_depositFee)
    {
        tokens_[token].depositFee = _depositFee;

        emit UpdateTokenDepositFee(token, _depositFee);
    }

    /// @notice Set withdraw fee for specific token.
    /// This may be called only by `governance` or `management`
    /// @param token Token address, must be enabled
    /// @param _withdrawFee Withdraw fee, must be less than FEE_LIMIT.
    function setTokenWithdrawFee(
        address token,
        uint _withdrawFee
    )
        public
        override
        onlyGovernanceOrManagement
        respectFeeLimit(_withdrawFee)
    {
        tokens_[token].withdrawFee = _withdrawFee;

        emit UpdateTokenWithdrawFee(token, _withdrawFee);
    }

    /// @notice Set alien configuration address.
    /// @param _configuration The address to use for alien configuration.
    function setConfigurationAlien(
        EverscaleAddress memory _configuration
    ) external override onlyGovernance {
        configurationAlien_ = _configuration;

        emit UpdateConfiguration(
            TokenType.Alien,
            _configuration.wid,
            _configuration.addr
        );
    }

    /// @notice Set native configuration address.
    /// @param _configuration The address to use for native configuration.
    function setConfigurationNative(
        EverscaleAddress memory _configuration
    ) external override onlyGovernance {
        configurationNative_ = _configuration;

        emit UpdateConfiguration(
            TokenType.Native,
            _configuration.wid,
            _configuration.addr
        );
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

    /// @notice Changes the address of `guardian`.
    /// This may only be called by `governance`.
    /// @param _guardian The new guardian address to use.
    function setGuardian(
        address _guardian
    )
        external
        override
        onlyGovernance
    {
        guardian = _guardian;

        emit UpdateGuardian(guardian);
    }

    /// @notice Activates or deactivates MultiVault emergency shutdown.
    ///     During emergency shutdown:
    ///     - Deposits are disabled
    ///     - Withdrawals are disabled
    /// This may only be called by `governance` or `guardian`.
    /// @param active If `true`, the MultiVault goes into Emergency Shutdown. If `false`, the MultiVault goes back into
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

    /// @notice Changes pending withdrawal bounty for specific pending withdrawal
    /// @param id Pending withdrawal ID.
    /// @param bounty The new value for pending withdrawal bounty.
    function setPendingWithdrawalBounty(
        uint256 id,
        uint256 bounty
    )
        public
        override
    {
        PendingWithdrawalParams memory pendingWithdrawal = pendingWithdrawals_[msg.sender][id];

        require(bounty <= pendingWithdrawal.amount);

        pendingWithdrawals_[msg.sender][id].bounty = bounty;

        emit PendingWithdrawalUpdateBounty(
            msg.sender,
            id,
            bounty
        );
    }

    function forceWithdraw(
        PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external override {
        for (uint i = 0; i < pendingWithdrawalIds.length; i++) {
            PendingWithdrawalId memory pendingWithdrawalId = pendingWithdrawalIds[i];

            PendingWithdrawalParams memory pendingWithdrawal = pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id];

            pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].amount = 0;

            IERC20(pendingWithdrawal.token).safeTransfer(
                pendingWithdrawalId.recipient,
                pendingWithdrawal.amount
            );

            emit PendingWithdrawalForce(pendingWithdrawalId.recipient, pendingWithdrawalId.id);
        }
    }

    /// @notice Cancel pending withdrawal partially or completely.
    /// This may only be called by pending withdrawal recipient.
    /// @param id Pending withdrawal ID
    /// @param amount Amount to cancel, should be less or equal than pending withdrawal amount
    /// @param recipient Tokens recipient, in Everscale network
    /// @param bounty New value for bounty
    function cancelPendingWithdrawal(
        uint256 id,
        uint256 amount,
        EverscaleAddress memory recipient,
        uint bounty
    )
        external
        override
        onlyEmergencyDisabled
    {
        PendingWithdrawalParams memory pendingWithdrawal = pendingWithdrawals_[msg.sender][id];

        require(amount > 0 && amount <= pendingWithdrawal.amount);

        pendingWithdrawals_[msg.sender][id].amount -= amount;

        _transferToEverscaleAlien(pendingWithdrawal.token, recipient, amount);

        emit PendingWithdrawalCancel(msg.sender, id, amount);

        setPendingWithdrawalBounty(id, bounty);
    }

    /// @notice Transfer tokens to the Everscale. Works both for native and alien tokens.
    /// Approve is required only for alien tokens deposit.
    /// @param recipient Everscale recipient.
    /// @param token EVM token address, should not be blacklisted.
    /// @param amount Amount of tokens to transfer.
    function deposit(
        EverscaleAddress memory recipient,
        address token,
        uint amount
    )
        external
        override
        nonReentrant
        tokenNotBlacklisted(token)
        initializeToken(token)
        onlyEmergencyDisabled
    {
        uint fee = calculateMovementFee(amount, token, Fee.Deposit);

        bool isNative = tokens_[token].isNative;

        if (isNative) {
            IMultiVaultToken(token).burn(
                msg.sender,
                amount
            );

            _transferToEverscaleNative(token, recipient, amount - fee);
        } else {
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );

            _transferToEverscaleAlien(token, recipient, amount - fee);
        }

        _increaseTokenFee(token, fee);

        emit Deposit(
            isNative ? TokenType.Native : TokenType.Alien,
            msg.sender,
            token,
            recipient.wid,
            recipient.addr,
            amount,
            fee
        );
    }

    function deposit(
        EverscaleAddress memory recipient,
        address token,
        uint256 amount,
        uint256 expectedMinBounty,
        PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external override nonReentrant {
        uint amountLeft = amount;
        uint amountPlusBounty = amount;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        for (uint i = 0; i < pendingWithdrawalIds.length; i++) {
            PendingWithdrawalId memory pendingWithdrawalId = pendingWithdrawalIds[i];
            PendingWithdrawalParams memory pendingWithdrawal = pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id];

            require(pendingWithdrawal.amount > 0);
            require(pendingWithdrawal.token == token);

            amountLeft -= pendingWithdrawal.amount;
            amountPlusBounty += pendingWithdrawal.bounty;

            pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].amount = 0;

            emit PendingWithdrawalFill(pendingWithdrawalId.recipient, pendingWithdrawalId.id);

            IERC20(pendingWithdrawal.token).safeTransfer(
                pendingWithdrawalId.recipient,
                pendingWithdrawal.amount - pendingWithdrawal.bounty
            );
        }

        require(amountPlusBounty - amount >= expectedMinBounty);

        uint fee = calculateMovementFee(amount, token, Fee.Deposit);

        _transferToEverscaleAlien(
            token,
            recipient,
            amountPlusBounty - fee
        );

        _increaseTokenFee(token, fee);
    }

    /// @notice Save withdrawal for native token
    /// @param payload Withdraw payload
    /// @param signatures Payload signatures
    function saveWithdrawNative(
        bytes memory payload,
        bytes[] memory signatures
    )
        external
        override
        nonReentrant
        withdrawalNotSeenBefore(payload)
        onlyEmergencyDisabled
    {
        EverscaleEvent memory _event = _processWithdrawEvent(
            payload,
            signatures,
            configurationNative_
        );

        bytes32 payloadId = keccak256(payload);

        // Decode event data
        NativeWithdrawalParams memory withdrawal = MultiVaultLibrary.decodeNativeWithdrawalEventData(_event.eventData);

        // Ensure chain id is correct
        require(withdrawal.chainId == getChainID());

        // Derive token address
        // Depends on the withdrawn token source
        address token = _getNativeWithdrawalToken(withdrawal);

        // Ensure token is not blacklisted
        require(!tokens_[token].blacklisted);

        // Consider movement fee and send it to `rewards_`
        uint256 fee = calculateMovementFee(
            withdrawal.amount,
            token,
            Fee.Withdraw
        );

        IMultiVaultToken(token).mint(
            withdrawal.recipient,
            withdrawal.amount - fee
        );

        _increaseTokenFee(token, fee);

        emit Withdraw(
            TokenType.Native,
            payloadId,
            token,
            withdrawal.recipient,
            withdrawal.amount,
            fee
        );
    }

    /// @notice Save withdrawal of alien token
    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures,
        uint bounty
    )
        public
        override
        nonReentrant
        withdrawalNotSeenBefore(payload)
        onlyEmergencyDisabled
    {
        EverscaleEvent memory _event = _processWithdrawEvent(
            payload,
            signatures,
            configurationAlien_
        );

        bytes32 payloadId = keccak256(payload);

        // Decode event data
        AlienWithdrawalParams memory withdrawal = MultiVaultLibrary.decodeAlienWithdrawalEventData(_event.eventData);

        // Ensure chain id is correct
        require(withdrawal.chainId == getChainID());

        // Ensure token is not blacklisted
        require(!tokens_[withdrawal.token].blacklisted);

        // Consider movement fee and send it to `rewards_`
        uint256 fee = calculateMovementFee(
            withdrawal.amount,
            withdrawal.token,
            Fee.Withdraw
        );

        _increaseTokenFee(withdrawal.token, fee);

        uint withdrawAmount = withdrawal.amount - fee;

        // Check that token balance is sufficient
        if (IERC20(withdrawal.token).balanceOf(address(this)) < withdrawAmount) {
            uint pendingWithdrawalId = pendingWithdrawalsPerUser[withdrawal.recipient];

            pendingWithdrawalsPerUser[withdrawal.recipient]++;

            pendingWithdrawalsTotal[withdrawal.token] += withdrawAmount;

            // - Save withdrawal as pending
            pendingWithdrawals_[withdrawal.recipient][pendingWithdrawalId] = PendingWithdrawalParams({
                token: withdrawal.token,
                amount: withdrawAmount,
                bounty: msg.sender == withdrawal.recipient ? bounty : 0
            });

            emit PendingWithdrawalCreated(
                withdrawal.recipient,
                pendingWithdrawalId,
                withdrawal.token,
                withdrawAmount,
                payloadId
            );
        } else {
            IERC20(withdrawal.token).safeTransfer(
                withdrawal.recipient,
                withdrawAmount
            );

            emit Withdraw(
                TokenType.Alien,
                payloadId,
                withdrawal.token,
                withdrawal.recipient,
                withdrawal.amount,
                fee
            );
        }
    }

    /// @notice Save withdrawal of alien token
    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures
    )
        external
        override
    {
        saveWithdrawAlien(payload, signatures, 0);
    }

    /// @notice Skim multivault fees for specific token
    /// @dev If `skim_to_everscale` is true, than fees will be sent to Everscale.
    /// Token type will be derived automatically and transferred with correct pipeline to the `rewards`.
    /// Otherwise, tokens will be transferred to the `governance` address.
    ///
    /// Can be called only by governance or management.
    /// @param token Token address, can be both native or alien
    /// @param skim_to_everscale Skim fees to Everscale or not
    function skim(
        address token,
        bool skim_to_everscale
    ) external override nonReentrant onlyGovernanceOrManagement {
        uint fee = fees[token];

        require(fee > 0);

        fees[token] = 0;

        // Find out token type
        bool isNative = tokens_[token].isNative;

        if (skim_to_everscale) {
            if (isNative) {
                _transferToEverscaleNative(token, rewards_, fee);
            } else {
                _transferToEverscaleAlien(token, rewards_, fee);
            }
        } else {
            if (isNative) {
                IMultiVaultToken(token).mint(governance, fee);
            } else {
                IERC20(token).safeTransfer(governance, fee);
            }
        }

        emit SkimFee(token, skim_to_everscale, fee);
    }

    function migrateAlienTokenToVault(
        address token,
        address vault
    )
        external
        override
        onlyGovernance
    {
        require(tokens_[token].activation > 0);
        require(!tokens_[token].isNative);

        tokens_[token].blacklisted = true;

        IERC20(token).safeTransfer(
            vault,
            IERC20(token).balanceOf(address(this))
        );

        emit TokenMigrated(token, vault);
    }

    /// @notice Calculates fee for deposit or withdrawal.
    /// @param amount Amount of tokens.
    /// @param _token Token address.
    /// @param fee Fee type (Deposit = 0, Withdraw = 1).
    function calculateMovementFee(
        uint256 amount,
        address _token,
        Fee fee
    ) public view returns (uint256) {
        Token memory token = tokens_[_token];

        uint tokenFee = fee == Fee.Deposit ? token.depositFee : token.withdrawFee;

        return tokenFee * amount / MAX_BPS;
    }

    function getNativeToken(
        int8 native_wid,
        uint256 native_addr
    ) external view returns (address) {
        return MultiVaultLibrary.getNativeToken(native_wid, native_addr);
    }

    function _increaseTokenFee(
        address token,
        uint amount
    ) internal {
        if (amount > 0) fees[token] += amount;
    }

    function _activateToken(
        address token,
        bool isNative
    ) internal {
        uint depositFee = isNative ? defaultNativeDepositFee : defaultAlienDepositFee;
        uint withdrawFee = isNative ? defaultNativeWithdrawFee : defaultAlienWithdrawFee;

        tokens_[token] = Token({
            activation: block.number,
            blacklisted: false,
            isNative: isNative,
            depositFee: depositFee,
            withdrawFee: withdrawFee
        });

        emit TokenActivated(
            token,
            block.number,
            isNative,
            depositFee,
            withdrawFee
        );
    }

    function _transferToEverscaleNative(
        address _token,
        EverscaleAddress memory recipient,
        uint amount
    ) internal {
        EverscaleAddress memory native = natives_[_token];

        emit NativeTransfer(
            native.wid,
            native.addr,
            uint128(amount),
            recipient.wid,
            recipient.addr
        );
    }

    function _transferToEverscaleAlien(
        address _token,
        EverscaleAddress memory recipient,
        uint amount
    ) internal {
        emit AlienTransfer(
            getChainID(),
            uint160(_token),
            IERC20Metadata(_token).name(),
            IERC20Metadata(_token).symbol(),
            IERC20Metadata(_token).decimals(),
            uint128(amount),
            recipient.wid,
            recipient.addr
        );
    }

    function _getNativeWithdrawalToken(
        NativeWithdrawalParams memory withdrawal
    ) internal returns (address token) {
        token = MultiVaultLibrary.getNativeToken(
            withdrawal.native.wid,
            withdrawal.native.addr
        );

        if (tokens_[token].activation == 0) {
            _deployTokenForNative(withdrawal.native, withdrawal.meta);
            _activateToken(token, true);

            natives_[token] = withdrawal.native;
        }
    }

    function _deployTokenForNative(
        EverscaleAddress memory native,
        TokenMeta memory meta
    ) internal returns (address token) {
        bytes memory bytecode = type(MultiVaultToken).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(native.wid, native.addr));

        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Check custom prefix available
        TokenPrefix memory prefix = prefixes_[token];

        string memory name_prefix = prefix.activation == 0 ? DEFAULT_NAME_PREFIX : prefix.name;
        string memory symbol_prefix = prefix.activation == 0 ? DEFAULT_SYMBOL_PREFIX : prefix.symbol;

        IMultiVaultToken(token).initialize(
            string(abi.encodePacked(name_prefix, meta.name)),
            string(abi.encodePacked(symbol_prefix, meta.symbol)),
            meta.decimals
        );

        emit TokenCreated(
            token,
            native.wid,
            native.addr,
            name_prefix,
            symbol_prefix,
            meta.name,
            meta.symbol,
            meta.decimals
        );
    }

    function _processWithdrawEvent(
        bytes memory payload,
        bytes[] memory signatures,
        EverscaleAddress memory configuration
    ) internal view returns (EverscaleEvent memory) {
        require(
            IBridge(bridge).verifySignedEverscaleEvent(payload, signatures) == 0,
            "Vault: signatures verification failed"
        );

        // Decode Everscale event
        (EverscaleEvent memory _event) = abi.decode(payload, (EverscaleEvent));

        require(
            _event.configurationWid == configuration.wid &&
            _event.configurationAddress == configuration.addr
        );

        return _event;
     }
}