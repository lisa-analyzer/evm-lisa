// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IVoterUpgradeable.sol";
import "./interfaces/IERC20Upgradeable.sol";

import "./interfaces/IDepositExecute.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IERCHandler.sol";
import "./interfaces/IERCHandlerDecimals.sol";
import "./interfaces/IGenericHandler.sol";
import "./interfaces/IWETH.sol";

/**
    @title Facilitates deposits, creation and voting of deposit proposals, and deposit executions.
    @author Router Protocol
 */
contract BridgeUpgradeable is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    function fetch_chainID() public view virtual returns (uint8) {
        return _chainID;
    }

    function fetch_expiry() public view virtual returns (uint256) {
        return _expiry;
    }

    function fetch_whitelistEnabled() public view virtual returns (bool) {
        return _whitelistEnabled;
    }

    function fetch_depositCounts(uint8 _id) public view virtual returns (uint64) {
        return _depositCounts[_id];
    }

    function fetch_resourceIDToHandlerAddress(bytes32 _id) public view virtual returns (address) {
        return _resourceIDToHandlerAddress[_id];
    }

    function fetch_proposals(bytes32 _id) public view virtual returns (uint256) {
        return _proposals[_id];
    }

    function fetch_whitelist(address _beneficiary) public view virtual returns (bool) {
        return _whitelist[_beneficiary];
    }

    function GetProposalHash(
        uint8 chainID,
        uint64 depositNonce,
        bytes32 dataHash
    ) public pure virtual returns (bytes32) {
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash));
        return proposalHash;
    }

    function HasVotedOnProposal(
        uint8 chainID,
        uint64 depositNonce,
        bytes32 dataHash
    ) public view virtual returns (bool) {
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash));
        uint256 id = _proposals[proposalHash];
        return _voter.Voted(id, msg.sender);
    }

    // View Functions

    uint8 private _chainID;
    uint256 private _expiry;
    bool private _whitelistEnabled;
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant RESOURCE_SETTER = keccak256("RESOURCE_SETTER");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    uint256 public totalRelayers;

    uint64 public _quorum;

    IVoterUpgradeable public _voter;

    // enum ProposalStatus { Inactive, Active, Passed, Executed, Cancelled }

    mapping(uint8 => uint64) private _depositCounts;

    mapping(bytes32 => address) private _resourceIDToHandlerAddress;

    mapping(bytes32 => uint256) private _proposals;

    mapping(address => bool) private _whitelist;

    mapping(uint256 => proposalStruct) private _proposalDetails;

    struct proposalStruct {
        uint8 chainID;
        uint64 depositNonce;
        bytes32 dataHash;
        bytes32 resourceID;
    }

    mapping(address => bool) private _genericWhitelist;

    // Data Structure Ends

    event quorumChanged(uint64 quorum);
    event expiryChanged(uint256 expiry);
    event ProposalEvent(
        uint8 originChainID,
        uint64 depositNonce,
        IVoterUpgradeable.ProposalStatus status,
        bytes32 dataHash
    );
    event ProposalVote(
        uint8 originChainID,
        uint64 depositNonce,
        IVoterUpgradeable.ProposalStatus status,
        bytes32 dataHash
    );
    event Deposit(
        uint8 indexed destinationChainID,
        bytes32 indexed resourceID,
        uint64 indexed depositNonce,
        uint256 widgetID
    );
    event Stake(address indexed staker, uint256 amount, address pool);
    event Unstake(address indexed unstaker, uint256 amount, address pool);
    event FeeSetterAdded(address feeSetter);
    event FeeSetterRemoved(address feeSetter);
    event AddedWhitelist(address whitelistAddress);
    event RemovedWhitelist(address whitelistAddress);
    event WhitelistingSetting(bool status);
    event AdminWithdraw(address handler, address tokenAddress, address recipient, uint256 amountOrTokenID);
    event Settlement(
        uint8 indexed originChainID,
        uint64 indexed depositNonce,
        address settlementToken,
        uint256 settlementAmount,
        IVoterUpgradeable.ProposalStatus status
    );
    event GenericDeposit(
        uint8 indexed destinationChainID,
        bytes32 resourceID,
        uint64 depositNonce,
        address indexed user,
        bytes data
    );
    /**
        @notice RelayerAdded Event
        @notice Creates a event when Relayer Role is granted.
        @param relayer Address of relayer.
    */
    event RelayerAdded(address relayer);

    /**
        @notice RelayerRemoved Event
        @notice Creates a event when Relayer Role is revoked.
        @param relayer Address of relayer.
    */
    event RelayerRemoved(address relayer);

    // Modifier Section Starts

    modifier onlyAdminOrRelayer() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(RELAYER_ROLE, msg.sender),
            "sender is not relayer or admin"
        );
        _;
    }

    modifier isWhitelisted() {
        if (_whitelistEnabled) {
            require(_whitelist[msg.sender], "address is not whitelisted");
        }
        _;
    }

    modifier isWhitelistEnabled() {
        require(_whitelistEnabled, "BridgeUpgradeable: White listing is not enabled");
        _;
    }

    modifier isResourceID(bytes32 _id) {
        require(_resourceIDToHandlerAddress[_id] != address(0), "BridgeUpgradeable: No handler for resourceID");
        _;
    }

    modifier isProposalExists(
        uint8 chainID,
        uint64 depositNonce,
        bytes32 dataHash
    ) {
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash));
        require(_proposals[proposalHash] != 0, "BridgeUpgradeable: Proposal Already Exists");
        _;
    }

    // Modifier Section ends

    receive() external payable {}

    // Upgrade Section Starts
    /**
        @notice Initializes Bridge, creates and grants {msg.sender} the admin role,
        creates and grants {initialRelayers} the relayer role.
        @param chainID ID of chain the Bridge contract exists on.
        @param quorum Number of votes needed for a deposit proposal to be considered passed.
     */
    function initialize(
        uint8 chainID,
        uint256 quorum,
        uint256 expiry,
        address voter
    ) external initializer {
        __AccessControl_init();
        __Pausable_init();

        // Constructor Fx
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _voter = IVoterUpgradeable(voter);

        _chainID = chainID;
        _quorum = uint64(quorum);
        _expiry = expiry;

        // Constructor Fx
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // Upgrade Section Ends

    // Access Control Section Starts

    /**
        @notice grantRole function
        @dev Overrides the grant role in accessControl contract.
        @dev If RELAYER_ROLE is granted then it would mint 1 voting token as voting weights.
        @dev The Token minted would be notional and non transferable type.
        @param role Hash of the role being granted
        @param account address to which role is being granted
    */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        nonReentrant
        onlyRole(getRoleAdmin(role))
    {
        super.grantRole(role, account);
        if (role == RELAYER_ROLE && _voter.balanceOf(account) == 0 ether) {
            _voter.mint(account);
            totalRelayers = totalRelayers + 1;
            emit RelayerAdded(account);
        }
    }

    /**
        @notice revokeRole function
        @dev Overrides the grant role in accessControl contract.
        @dev If RELAYER_ROLE is revoked then it would burn 1 voting token as voting weights.
        @dev The Token burned would be notional and non transferable type.
        @param role Hash of the role being revoked
        @param account address to which role is being revoked
    */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        nonReentrant
        onlyRole(getRoleAdmin(role))
    {
        super.revokeRole(role, account);
        if (role == RELAYER_ROLE && _voter.balanceOf(account) == 1 ether) {
            _voter.burn(account);
            totalRelayers = totalRelayers - 1;
            emit RelayerRemoved(account);
        }
    }

    // Access Control Section Ends

    // Whitelist Section Starts
    /**
        @dev Adds single address to _whitelist.
        @param _beneficiary Address to be added to the _whitelist
    */
    function addToWhitelist(address _beneficiary) public virtual onlyRole(DEFAULT_ADMIN_ROLE) isWhitelistEnabled {
        _whitelist[_beneficiary] = true;
        emit AddedWhitelist(_beneficiary);
    }

    /**
        @dev Removes single address from _whitelist.
        @param _beneficiary Address to be removed to the _whitelist
    */
    function removeFromWhitelist(address _beneficiary) public virtual onlyRole(DEFAULT_ADMIN_ROLE) isWhitelistEnabled {
        _whitelist[_beneficiary] = false;
        emit RemovedWhitelist(_beneficiary);
    }

    /**
        @dev setWhitelisting whitelisting process.
    */
    function setWhitelisting(bool value) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _whitelistEnabled = value;
        emit WhitelistingSetting(value);
    }

    // Whitelist Section Ends

    // Pause Section Starts

    /**
        @notice Pauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
    */
    function pause() public virtual onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
    }

    /**
        @notice Unpauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
     */
    function unpause() public virtual onlyRole(PAUSER_ROLE) whenPaused {
        _unpause();
    }

    // Pause Section Ends

    // Ancilary Admin Functions Starts

    /**
        @notice Modifies the number of votes required for a proposal to be considered passed.
        @notice Only callable by an address that currently has the admin role.
        @param newQuorum Value {newQuorum} will be changed to.
        @notice Emits {quorumChanged} event.
     */
    function adminChangeQuorum(uint256 newQuorum) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _quorum = uint64(newQuorum);
        emit quorumChanged(_quorum);
    }

    /**
        @notice Modifies the block expiry for a proposal.
        @notice Only callable by an address that currently has the admin role.
        @param newExpiry will be new value of _expiry.
        @notice Emits {expiryChanged} event.
     */
    function adminChangeExpiry(uint256 newExpiry) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _expiry = newExpiry;
        emit expiryChanged(_expiry);
    }

    /**
        @notice Sets a new resource for handler contracts that use the IERCHandler interface,
        and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param resourceID ResourceID to be used when making deposits.
        @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function adminSetResource(
        address handlerAddress,
        bytes32 resourceID,
        address tokenAddress
    ) public virtual onlyRole(RESOURCE_SETTER) {
        _resourceIDToHandlerAddress[resourceID] = handlerAddress;
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setResource(resourceID, tokenAddress);
    }

    /**
        @notice Sets a new resource for handler contracts that use the IERCHandler interface,
        and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param tokenAddress token contract for setting config.
        @param destinationChainID destinationChainID to be used when setting config.
        @param decimals decimals for token on target chain.
     */
    function adminSetTokenDecimals(
        address handlerAddress,
        address tokenAddress,
        uint8 destinationChainID,
        uint8 decimals
    ) public virtual onlyRole(RESOURCE_SETTER) {
        IERCHandlerDecimals handler = IERCHandlerDecimals(handlerAddress);
        handler.setTokenDecimals(tokenAddress, destinationChainID, decimals);
    }

    function adminSetOneSplitAddress(address handlerAddress, address contractAddress)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setOneSplitAddress(contractAddress);
    }

    /**
    @notice Creates new liquidity pool
    @notice Only callable by an address that currently has the admin role.
    @param handlerAddress Address of handler resource will be set for.
    @param tokenAddress Address of token for which pool needs to be created.
 */
    function adminSetLiquidityPool(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address handlerAddress,
        address tokenAddress,
        address lpAddress
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setLiquidityPool(name, symbol, decimals, tokenAddress, lpAddress);
    }

    function adminSetLiquidityPoolOwner(
        address handlerAddress,
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setLiquidityPoolOwner(newOwner, tokenAddress, lpAddress);
    }

    /**
        @notice Sets a new resource for handler contracts that use the IGenericHandler interface,
        and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param resourceID ResourceID to be used when making deposits.
     */
    function adminSetGenericResource(address handlerAddress, bytes32 resourceID)
        public
        virtual
        onlyRole(RESOURCE_SETTER)
    {
        _resourceIDToHandlerAddress[resourceID] = handlerAddress;
        _genericWhitelist[handlerAddress] = true;
    }

    /**
        @notice Sets a resource as burnable for handler contracts that use the IERCHandler interface.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @param status Boolean flag to change burnable status.
     */
    function adminSetBurnable(
        address handlerAddress,
        address tokenAddress,
        bool status
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setBurnable(tokenAddress, status);
    }

    /**
        @notice Used to manually withdraw funds from ERC safes.
        @param handlerAddress Address of handler to withdraw from.
        @param tokenAddress Address of token to withdraw.
        @param recipient Address to withdraw tokens to.
        @param amount the amount of ERC20 tokens to withdraw.
     */
    function adminWithdraw(
        address handlerAddress,
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual nonReentrant onlyRole(EMERGENCY_ROLE) {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.withdraw(tokenAddress, recipient, amount);
        emit AdminWithdraw(handlerAddress, tokenAddress, recipient, amount);
    }

    /**
        @notice Used to manually withdraw funds from ERC safes.
        @param handlerAddress Address of handler to withdraw from.
        @param tokenAddress Address of token to withdraw.
        @param recipient Address to withdraw tokens to.
        @param amount the amount of ERC20 tokens to withdraw.
     */
    function adminWithdrawFees(
        address handlerAddress,
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual nonReentrant onlyRole(EMERGENCY_ROLE) {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.withdrawFees(tokenAddress, recipient, amount);
        emit AdminWithdraw(handlerAddress, tokenAddress, recipient, amount);
    }

    /**
       @notice Used to set feeStatus
       @notice Only callable by admin.
    */
    function adminSetFeeStatus(bytes32 resourceID, bool status) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        address handlerAddress = _resourceIDToHandlerAddress[resourceID];
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.toggleFeeStatus(status);
    }

    // Fee Function Starts

    /**
       @notice Used to set fee
       @notice Only callable by feeSetter.
    */
    function setBridgeFee(
        bytes32 resourceID,
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    ) public virtual onlyRole(FEE_SETTER_ROLE) {
        address handlerAddress = _resourceIDToHandlerAddress[resourceID];
        IERCHandler handler = IERCHandler(handlerAddress);
        require(handler.getFeeStatus(), "fee is not enabled");
        handler.setBridgeFee(destinationChainID, feeTokenAddress, transferFee, exchangeFee, accepted);
    }

    function getBridgeFee(
        bytes32 resourceID,
        uint8 destChainID,
        address feeTokenAddress
    ) public view returns (uint256, uint256) {
        address handlerAddress = _resourceIDToHandlerAddress[resourceID];
        IERCHandler handler = IERCHandler(handlerAddress);
        return handler.getBridgeFee(destChainID, feeTokenAddress);
    }

    // Fee Function Ends

    // Deposit Function Starts

    function deposit(
        uint8 destinationChainID,
        bytes32 resourceID,
        bytes calldata data,
        uint256[] memory flags,
        address[] memory path,
        bytes[] calldata dataTx,
        address feeTokenAddress
    ) public virtual nonReentrant whenNotPaused isWhitelisted {
        _deposit(destinationChainID, resourceID, data, flags, path, dataTx, feeTokenAddress);
    }

    function depositETH(
        uint8 destinationChainID,
        bytes32 resourceID,
        bytes calldata data,
        uint256[] memory flags,
        address[] memory path,
        bytes[] calldata dataTx,
        address feeTokenAddress
    ) public payable virtual nonReentrant whenNotPaused isWhitelisted {
        IERCHandler ercHandler = IERCHandler(_resourceIDToHandlerAddress[resourceID]);
        require(address(ercHandler) != address(0), "resourceID not mapped to handler");
        require(msg.value > 0, "depositETH: No native assets transferred");

        address weth = ercHandler._WETH();

        IWETH(weth).deposit{ value: msg.value }();
        require(IWETH(weth).transfer(msg.sender, msg.value));

        _deposit(destinationChainID, resourceID, data, flags, path, dataTx, feeTokenAddress);
    }

    /**
       @notice Used notify bridge for generic deposit
       @notice Can only be called by Generic handler
    */
    function genericDeposit(uint8 _destChainID, bytes32 _resourceID) external whenNotPaused returns (uint64) {
        require(_genericWhitelist[_resourceIDToHandlerAddress[_resourceID]] == true);
        require(_resourceIDToHandlerAddress[_resourceID] == msg.sender);
        uint64 depositNonce = ++_depositCounts[_destChainID];
        emit Deposit(_destChainID, _resourceID, depositNonce, 0);
        return depositNonce;
    }

    function _deposit(
        uint8 destinationChainID,
        bytes32 resourceID,
        bytes calldata data,
        uint256[] memory flags,
        address[] memory path,
        bytes[] calldata dataTx,
        address feeTokenAddress
    ) private {
        IDepositExecute.SwapInfo memory swapDetails = unpackDepositData(data);

        swapDetails.depositer = msg.sender;
        swapDetails.flags = flags;
        swapDetails.path = path;
        swapDetails.feeTokenAddress = feeTokenAddress;
        swapDetails.dataTx = dataTx;

        swapDetails.handler = _resourceIDToHandlerAddress[resourceID];
        require(swapDetails.handler != address(0), "resourceID not mapped to handler");

        swapDetails.depositNonce = ++_depositCounts[destinationChainID];

        IDepositExecute depositHandler = IDepositExecute(swapDetails.handler);
        depositHandler.deposit(resourceID, destinationChainID, swapDetails.depositNonce, swapDetails);

        emit Deposit(destinationChainID, resourceID, swapDetails.depositNonce, swapDetails.widgetID);
    }

    function unpackDepositData(bytes calldata data)
        internal
        pure
        returns (IDepositExecute.SwapInfo memory depositData)
    {
        IDepositExecute.SwapInfo memory swapDetails;
        uint256 isDestNative;

        (
            swapDetails.srcTokenAmount,
            swapDetails.srcStableTokenAmount,
            swapDetails.destStableTokenAmount,
            swapDetails.destTokenAmount,
            isDestNative,
            swapDetails.lenRecipientAddress,
            swapDetails.lenSrcTokenAddress,
            swapDetails.lenDestTokenAddress
        ) = abi.decode(data, (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256));

        //Note: to avoid stack too deep error, we are decoding it again.
        (, , , , , , , , swapDetails.widgetID) = abi.decode(
            data,
            (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
        );

        swapDetails.isDestNative = isDestNative == 0 ? false : true;
        swapDetails.index = 288; // 32 * 6 -> 9

        bytes memory recipient = bytes(data[swapDetails.index:swapDetails.index + swapDetails.lenRecipientAddress]);
        swapDetails.index = swapDetails.index + swapDetails.lenRecipientAddress;
        bytes memory srcToken = bytes(data[swapDetails.index:swapDetails.index + swapDetails.lenSrcTokenAddress]);
        swapDetails.index = swapDetails.index + swapDetails.lenSrcTokenAddress;
        bytes memory destStableToken = bytes(
            data[swapDetails.index:swapDetails.index + swapDetails.lenDestTokenAddress]
        );
        swapDetails.index = swapDetails.index + swapDetails.lenDestTokenAddress;
        bytes memory destToken = bytes(data[swapDetails.index:swapDetails.index + swapDetails.lenDestTokenAddress]);

        bytes20 srcTokenAddress;
        bytes20 destStableTokenAddress;
        bytes20 destTokenAddress;
        bytes20 recipientAddress;
        assembly {
            srcTokenAddress := mload(add(srcToken, 0x20))
            destStableTokenAddress := mload(add(destStableToken, 0x20))
            destTokenAddress := mload(add(destToken, 0x20))
            recipientAddress := mload(add(recipient, 0x20))
        }
        swapDetails.srcTokenAddress = srcTokenAddress;
        swapDetails.destStableTokenAddress = address(destStableTokenAddress);
        swapDetails.destTokenAddress = destTokenAddress;
        swapDetails.recipient = address(recipientAddress);

        return swapDetails;
    }

    // Deposit Function Ends

    /**
       @notice Allows staking into liquidity pools.
       @notice Only callable when Bridge is not paused.
       @param handler handler address
       @param tokenAddress Asset which needs to be staked.
       @param amount Amount that needs to be staked.
       @notice Emits {Stake} event.
    */
    function stake(
        address handler,
        address tokenAddress,
        uint256 amount
    ) public virtual whenNotPaused {
        ILiquidityPool depositHandler = ILiquidityPool(handler);
        depositHandler.stake(msg.sender, tokenAddress, amount);
        emit Stake(msg.sender, amount, tokenAddress);
    }

    /**
       @notice Allows staking ETH into liquidity pools.
       @notice Only callable when Bridge is not paused.
       @param handler handler address
       @notice Emits {Stake} event.
    */
    function stakeETH(address handler) public payable virtual nonReentrant whenNotPaused {
        ILiquidityPool depositHandler = ILiquidityPool(handler);
        IERCHandler ercHandler = IERCHandler(handler);
        address WETH = ercHandler._WETH();
        uint256 amount = msg.value;
        require(amount > 0, "stakeETH: insufficient eth provided");

        IWETH(WETH).deposit{ value: amount }();
        assert(IWETH(WETH).transfer(handler, amount));
        depositHandler.stakeETH(msg.sender, WETH, amount);
        emit Stake(msg.sender, amount, WETH);
    }

    /**
       @notice Allows unstaking from liquidity pools.
       @notice Only callable when Bridge is not paused.
       @param handler handler address
       @param tokenAddress Asset which needs to be unstaked.
       @param amount Amount that needs to be unstaked.
       @notice Emits {Unstake} event.
    */
    function unstake(
        address handler,
        address tokenAddress,
        uint256 amount
    ) public virtual whenNotPaused {
        ILiquidityPool depositHandler = ILiquidityPool(handler);
        depositHandler.unstake(msg.sender, tokenAddress, amount);
        emit Unstake(msg.sender, amount, tokenAddress);
    }

    /**
       @notice Allows unstaking ETH from liquidity pools.
       @notice Only callable when Bridge is not paused.
       @param handler handler address
       @param amount Amount that needs to be unstaked.
       @notice Emits {Unstake} event.
    */
    function unstakeETH(address handler, uint256 amount) public virtual nonReentrant whenNotPaused {
        ILiquidityPool depositHandler = ILiquidityPool(handler);
        IERCHandler ercHandler = IERCHandler(handler);
        address WETH = ercHandler._WETH();
        depositHandler.unstakeETH(msg.sender, WETH, amount);
        emit Unstake(msg.sender, amount, WETH);
    }

    // Stating/UnStaking Function Ends

    // Voting Function starts

    /**
        @notice Returns a proposal.
        @param originChainID Chain ID deposit originated from.
        @param depositNonce ID of proposal generated by proposal's origin Bridge contract.
        @param dataHash Hash of data to be provided when deposit proposal is executed.
     */
    function getProposal(
        uint8 originChainID,
        uint64 depositNonce,
        bytes32 resourceID,
        bytes32 dataHash
    ) public view virtual returns (IVoterUpgradeable.issueStruct memory status) {
        bytes32 proposalHash = keccak256(abi.encodePacked(originChainID, depositNonce, dataHash, resourceID));
        return _voter.fetchIssueMap(_proposals[proposalHash]);
    }

    /**
        @notice When called, {msg.sender} will be marked as voting in favor of proposal.
        @notice Only callable by relayers when Bridge is not paused.
        @param chainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param dataHash Hash of data provided when deposit was made.
        @notice Proposal must not have already been passed or executed.
        @notice {msg.sender} must not have already voted on proposal.
        @notice Emits {ProposalEvent} event with status indicating the proposal status.
        @notice Emits {ProposalVote} event.
     */
    function voteProposal(
        uint8 chainID,
        uint64 depositNonce,
        bytes32 resourceID,
        bytes32 dataHash
    ) public virtual isResourceID(resourceID) onlyRole(RELAYER_ROLE) whenNotPaused {
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash, resourceID));
        if (_proposals[proposalHash] == 0) {
            uint256 id = _voter.createProposal(block.number + _expiry, _quorum);
            _proposals[proposalHash] = id;
            emit ProposalEvent(chainID, depositNonce, IVoterUpgradeable.ProposalStatus.Active, dataHash);
        } else if (_voter.fetchIsExpired(_proposals[proposalHash])) {
            _voter.setStatus(_proposals[proposalHash]);
            emit ProposalEvent(chainID, depositNonce, _voter.getStatus(_proposals[proposalHash]), dataHash);
            return;
        }
        if (_voter.getStatus(_proposals[proposalHash]) != IVoterUpgradeable.ProposalStatus.Cancelled) {
            _voter.vote(_proposals[proposalHash], 1, msg.sender);

            emit ProposalVote(chainID, depositNonce, _voter.getStatus(_proposals[proposalHash]), dataHash);
            if (_voter.getStatus(_proposals[proposalHash]) == IVoterUpgradeable.ProposalStatus.Passed) {
                emit ProposalEvent(chainID, depositNonce, _voter.getStatus(_proposals[proposalHash]), dataHash);
            }
        }
    }

    /**
        @notice Cancels a deposit proposal.
        @notice Only callable by admin when Bridge is not paused.
        @param chainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param dataHash Hash of data originally provided when deposit was made.
     */
    function cancelProposal(
        uint8 chainID,
        uint64 depositNonce,
        bytes32 resourceID,
        bytes32 dataHash
    ) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash, resourceID));
        IVoterUpgradeable.ProposalStatus currentStatus = _voter.getStatus(_proposals[proposalHash]);
        require(currentStatus == IVoterUpgradeable.ProposalStatus.Cancelled, "Proposal must be cancelled");
        delete _proposals[proposalHash];
    }

    /**
        @notice Executes a deposit proposal that is considered passed using a specified handler contract.
        @notice Only callable by relayers when Bridge is not paused.
        @param chainID ID of chain deposit originated from.
        @param resourceID ResourceID to be used when making deposits.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param data Data originally provided when deposit was made.
        @notice Proposal must have Passed status.
        @notice Hash of {data} must equal proposal's {dataHash}.
        @notice Emits {ProposalEvent} event with status {Executed}.
     */
    function executeProposal(
        uint8 chainID,
        uint64 depositNonce,
        bytes calldata data,
        bytes32 resourceID,
        uint256[] memory flags,
        address[] memory path,
        bytes[] memory dataTx
    ) public virtual onlyRole(RELAYER_ROLE) whenNotPaused {
        bytes32 dataHash = keccak256(abi.encodePacked(_resourceIDToHandlerAddress[resourceID], data));
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash, resourceID));
        if (_genericWhitelist[_resourceIDToHandlerAddress[resourceID]]) {
            IGenericHandler genericHandler = IGenericHandler(_resourceIDToHandlerAddress[resourceID]);
            genericHandler.executeProposal(data);
            emit ProposalEvent(chainID, depositNonce, IVoterUpgradeable.ProposalStatus.Executed, dataHash);
        } else {
            address settlementToken;
            IDepositExecute.SwapInfo memory swapDetails = unpackDepositData(data);
            swapDetails.dataTx = dataTx;
            swapDetails.flags = flags;
            swapDetails.path = path;
            swapDetails.index = chainID;
            swapDetails.depositNonce = depositNonce;
            IDepositExecute depositHandler = IDepositExecute(_resourceIDToHandlerAddress[resourceID]);
            (settlementToken, swapDetails.returnAmount) = depositHandler.executeProposal(swapDetails, resourceID);
            emit Settlement(
                chainID,
                depositNonce,
                settlementToken,
                swapDetails.returnAmount,
                IVoterUpgradeable.ProposalStatus.Executed
            );

            emit ProposalEvent(chainID, depositNonce, IVoterUpgradeable.ProposalStatus.Executed, dataHash);
        }
        IVoterUpgradeable.ProposalStatus currentStatus = _voter.getStatus(_proposals[proposalHash]);
        require(currentStatus == IVoterUpgradeable.ProposalStatus.Passed, "Proposal must have Passed status");
        _voter.executeProposal(_proposals[proposalHash]);
    }

    // Voting Function ends
}