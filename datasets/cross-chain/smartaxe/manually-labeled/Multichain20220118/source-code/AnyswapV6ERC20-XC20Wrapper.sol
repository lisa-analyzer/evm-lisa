// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/// @title Extension of the ERC20 interface that allows an owner
/// @dev Contract to pilot the ERC20 contract.
interface LocalAsset {
    /// @dev Mint tokens to an address
    /// @custom:selector 40c10f19
    /// @param to address The address to which you want to mint tokens
    /// @param value uint256 the amount of tokens to be minted
    function mint(address to, uint256 value) external returns (bool);

    /// @dev Burn tokens from an address
    /// @custom:selector 9dc29fac
    /// @param from address The address from which you want to burn tokens
    /// @param value uint256 the amount of tokens to be burnt
    function burn(address from, uint256 value) external returns (bool);

    /// @dev Freeze an account, preventing it from operating with the asset
    /// @custom:selector 8d1fdf2f
    /// @param account address The address that you want to freeze
    function freeze(address account) external returns (bool);

    /// @dev Unfreeze an account, letting it from operating againt with the asset
    /// @custom:selector 5ea20216
    /// @param account address The address that you want to unfreeze
    function thaw(address account) external returns (bool);

    /// @dev Freeze the entire asset operations
    /// @custom:selector d4937f51
    function freezeAsset() external returns (bool);

    /// @custom:selector 6b8751c1 (version before v0.26.0)
    function freeze_asset() external returns (bool);

    /// @dev Unfreeze the entire asset operations
    /// @custom:selector 51ec2ad7
    function thawAsset() external returns (bool);

    /// @custom:selector 1cddec19 (version before v0.26.0)
    function thaw_asset() external returns (bool);

    /// @dev Transfer the ownership of an asset to a new account
    /// @custom:selector f2fde38b
    /// @param owner address The address of the new owner
    function transferOwnership(address owner) external returns (bool);

    /// @custom:selector f0350c04 (version before v0.26.0)
    function transfer_ownership(address owner) external returns (bool);

    /// @dev Specify the issuer, admin and freezer of an asset
    /// @custom:selector c7d93c59
    /// @param issuer address The address capable of issuing tokens
    /// @param admin address The address capable of burning tokens and unfreezing accounts/assets
    /// @param freezer address The address capable of freezing accounts/asset
    function setTeam(
        address issuer,
        address admin,
        address freezer
    ) external returns (bool);

    /// @custom:selector f8bf8e95 (version before v0.26.0)
    function set_team(
        address issuer,
        address admin,
        address freezer
    ) external returns (bool);

    /// @dev Specify the name, symbol and decimals of your asset
    /// @custom:selector 37d2c2f4
    /// @param name string The name of the asset
    /// @param symbol string The symbol of the asset
    /// @param decimals uint8 The number of decimals of your asset
    function setMetadata(
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external returns (bool);

    /// @custom:selector ee5dc1e4 (version before v0.26.0)
    function set_metadata(
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external returns (bool);

    /// @dev Clear the name, symbol and decimals of your asset
    /// @custom:selector efb6d432
    function clearMetadata() external returns (bool);

    /// @custom:selector d3ba4b9e (version before v0.26.0)
    function clear_metadata() external returns (bool);
}

interface IXC20 is IERC20, LocalAsset {}

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(
            address(token).code.length > 0,
            "SafeERC20: call to non-contract"
        );

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// TokenType token type enumerations
// When in `need approve` situations, the user should approve to this wrapper contract,
// not to the Router contract, and not to the target token to be wrapped.
// If not, this wrapper will fail its function.
enum TokenType {
    MintBurnAny, // mint and burn(address from, uint256 amount), don't need approve
    MintBurnFrom, // mint and burnFrom(address from, uint256 amount), need approve
    MintBurnSelf, // mint and burn(uint256 amount), call transferFrom first, need approve
    Transfer, // transfer and transferFrom, need approve
    TransferDeposit, // transfer and transferFrom, deposit and withdraw, need approve, block when lack of liquidity
    TransferDeposit2 // transfer and transferFrom, deposit and withdraw, need approve, don't block when lack of liquidity
}

// deploy steps:
// 1. deploy this contract
// 2. retrieve or register xc20 token
//      set owner to this contract for mintable xc20, or
//      set issuer and admin to this contract for external xc20
// 3. call init() function of this contract
contract AnyswapV6ERC20_XC20Wrapper is IERC20 {
    using SafeERC20 for IERC20;
    string public name;
    string public symbol;
    uint8 public decimals;

    // impl MintBurnWrapper of `token()` and `tokenType()` interface
    TokenType public tokenType;
    address public token; // the target token this contract is wrapping

    /// @dev Records amount of AnyswapV6ERC20 token owned by account.
    mapping(address => uint256) public override balanceOf;
    uint256 private _totalSupply;

    // init flag for setting immediate vault, needed for CREATE2 support
    bool private _init;

    // flag to enable/disable swapout vs vault.burn so multiple events are triggered
    bool private _vaultOnly;

    // delay for timelock functions
    uint256 public constant DELAY = 2 days;

    // set of minters, can be this bridge or other bridges
    mapping(address => bool) public isMinter;
    address[] public minters;

    // primary controller of the token contract
    address public vault;

    address public pendingMinter;
    uint256 public delayMinter;

    modifier onlyAuth() {
        require(isMinter[msg.sender], "onlyAuth");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "onlyVault");
        _;
    }

    modifier onlyMintableXC20() {
        require(isMintableXC20(), "onlyMintableXC20");
        _;
    }

    modifier onlyExternalXC20() {
        require(!isMintableXC20(), "onlyExternalXC20");
        _;
    }

    function isMintableXC20() public view returns (bool) {
        return tokenType == TokenType.MintBurnAny;
    }

    function owner() external view returns (address) {
        return vault;
    }

    function mpc() external view returns (address) {
        return vault;
    }

    function setVaultOnly(bool enabled) external onlyVault {
        _vaultOnly = enabled;
    }

    function setMinter(address _auth) external onlyVault {
        require(_auth != address(0), "zero address");
        pendingMinter = _auth;
        delayMinter = block.timestamp + DELAY;
    }

    function applyMinter() external onlyVault {
        require(pendingMinter != address(0) && block.timestamp >= delayMinter);
        isMinter[pendingMinter] = true;
        minters.push(pendingMinter);

        pendingMinter = address(0);
        delayMinter = 0;
    }

    // No time delay revoke minter emergency function
    function revokeMinter(address _auth) external onlyVault {
        isMinter[_auth] = false;
    }

    function getAllMinters() external view returns (address[] memory) {
        return minters;
    }

    function changeVault(address newVault) external onlyVault returns (bool) {
        require(newVault != address(0), "zero address");
        emit LogChangeVault(vault, newVault, block.timestamp);
        vault = newVault;
        return true;
    }

    function mint(address to, uint256 amount) external onlyAuth returns (bool) {
        _swapin(to, amount);
        return true;
    }

    function burn(address from, uint256 amount)
        external
        onlyAuth
        returns (bool)
    {
        _swapout(from, amount);
        return true;
    }

    function Swapin(
        bytes32 txhash,
        address account,
        uint256 amount
    ) external onlyAuth returns (bool) {
        _swapin(account, amount);
        emit LogSwapin(txhash, account, amount);
        return true;
    }

    // swapout to evm chain
    function Swapout(uint256 amount, address bindaddr) external returns (bool) {
        require(!_vaultOnly, "vaultOnly");
        require(bindaddr != address(0), "zero address");
        _swapout(msg.sender, amount);
        emit LogSwapout(msg.sender, bindaddr, amount);
        return true;
    }

    // swapout to non-evm chain
    function Swapout(uint256 amount, string memory bindaddr)
        external
        returns (bool)
    {
        require(!_vaultOnly, "vaultOnly");
        require(bytes(bindaddr).length > 0, "empty bindaddr");
        _swapout(msg.sender, amount);
        emit LogSwapout(msg.sender, amount, bindaddr);
        return true;
    }

    function _swapin(address to, uint256 amount) internal {
        if (isMintableXC20()) {
            assert(IXC20(token).mint(to, amount));
        } else if (IERC20(token).balanceOf(address(this)) >= amount) {
            IERC20(token).safeTransfer(to, amount);
        } else {
            _mint(to, amount);
        }
    }

    function _swapout(address from, uint256 amount) internal {
        if (isMintableXC20()) {
            uint256 old_balance = IERC20(token).balanceOf(from);
            require(old_balance >= amount, "balance not enough");
            assert(IXC20(token).burn(from, amount));
            uint256 new_balance = IERC20(token).balanceOf(from);
            require(new_balance + amount == old_balance, "burn amount mismatch");
        } else if (balanceOf[from] >= amount) {
            _burn(from, amount);
        } else {
            require(IERC20(token).balanceOf(from) >= amount, "balance not enough");
            uint256 old_balance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransferFrom(from, address(this), amount);
            uint256 new_balance = IERC20(token).balanceOf(address(this));
            require(new_balance == old_balance + amount, "receive amount mismatch");
        }
    }

    /// @dev Records number of AnyswapV6ERC20 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}.
    mapping(address => mapping(address => uint256)) public override allowance;

    event LogChangeVault(
        address indexed oldVault,
        address indexed newVault,
        uint256 indexed effectiveTime
    );
    event LogSwapin(
        bytes32 indexed txhash,
        address indexed account,
        uint256 amount
    );
    event LogSwapout(
        address indexed account,
        address indexed bindaddr,
        uint256 amount
    );
    event LogSwapout(address indexed account, uint256 amount, string bindaddr);

    constructor() {
        vault = msg.sender;
    }

    // call `init` after this contract got suitable roles of the underlying xc20 token
    // make this function `payable` as it may call set meta data which needs deposit (bond)
    // add `_underlyingIsMint` flag as the underlying also support external xc20
    // add `_callInitMetaData` flag as the meta data may be already set outside
    function init(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        address _vault,
        address _auth,
        address _underlying,
        bool _underlyingIsMint,
        bool _callInitMetaData
    ) external payable onlyVault {
        require(!_init, "inited");
        _init = true;

        require(
            _underlying != address(0) && _underlying != address(this),
            "wrong underlying token"
        );

        token = _underlying;
        tokenType = _underlyingIsMint
            ? TokenType.MintBurnAny
            : TokenType.TransferDeposit;

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        if (_callInitMetaData && _underlyingIsMint) {
            _initMetaData(_name, _symbol, _decimals);
        }

        require(
            _decimals == IERC20(_underlying).decimals(),
            "decimals mismatch"
        );
        require(bytes(IERC20(_underlying).symbol()).length > 0, "empty symbol");

        require(_vault != address(0), "zero vault address");
        vault = _vault;

        require(_auth != address(0), "zero auth address");
        isMinter[_auth] = true;
        minters.push(_auth);

        // return left value to the message sender
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = msg.sender.call{value: balance}("");
            require(success);
        }
    }

    /// @dev Returns the total supply of AnyswapV6ERC20 token as the ETH held in this contract.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function deposit() external returns (uint256) {
        uint256 _amount = IERC20(token).balanceOf(msg.sender);
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        return _deposit(_amount, msg.sender);
    }

    function deposit(uint256 amount) external returns (uint256) {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, msg.sender);
    }

    function deposit(uint256 amount, address to) external returns (uint256) {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, to);
    }

    function depositVault(uint256 amount, address to)
        external
        onlyVault
        returns (uint256)
    {
        return _deposit(amount, to);
    }

    function _deposit(uint256 amount, address to)
        internal
        onlyExternalXC20
        returns (uint256)
    {
        _mint(to, amount);
        return amount;
    }

    function withdraw() external returns (uint256) {
        return _withdraw(msg.sender, balanceOf[msg.sender], msg.sender);
    }

    function withdraw(uint256 amount) external returns (uint256) {
        return _withdraw(msg.sender, amount, msg.sender);
    }

    function withdraw(uint256 amount, address to) external returns (uint256) {
        return _withdraw(msg.sender, amount, to);
    }

    function withdrawVault(
        address from,
        uint256 amount,
        address to
    ) external onlyVault returns (uint256) {
        return _withdraw(from, amount, to);
    }

    function _withdraw(
        address from,
        uint256 amount,
        address to
    ) internal onlyExternalXC20 returns (uint256) {
        _burn(from, amount);
        IERC20(token).safeTransfer(to, amount);
        return amount;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 balance = balanceOf[account];
        require(balance >= amount, "ERC20: burn amount exceeds balance");

        balanceOf[account] = balance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's AnyswapV6ERC20 token.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    /// @dev Moves `value` AnyswapV6ERC20 token from caller's account to account (`to`).
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` AnyswapV6ERC20 token.
    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        require(to != address(0) && to != address(this));
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "ERC20: transfer amount exceeds balance");

        balanceOf[msg.sender] = balance - value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);

        return true;
    }

    /// @dev Moves `value` AnyswapV6ERC20 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - `from` account must have at least `value` balance of AnyswapV6ERC20 token.
    ///   - `from` account must have approved caller to spend at least `value` of AnyswapV6ERC20 token, unless `from` and caller are the same account.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        require(to != address(0) && to != address(this));
        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "ERC20: request exceeds allowance");
                uint256 reduced = allowed - value;
                allowance[from][msg.sender] = reduced;
                emit Approval(from, msg.sender, reduced);
            }
        }

        uint256 balance = balanceOf[from];
        require(balance >= value, "ERC20: transfer amount exceeds balance");

        balanceOf[from] = balance - value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);

        return true;
    }

    // wrapper xc20 local asset interfaces
    // this contract could be the owner of xc20 token
    // so it should have the abilities of its roles
    // but forbid modify the metadata

    function freeze(address account)
        external
        onlyVault
        onlyMintableXC20
        returns (bool)
    {
        return IXC20(token).freeze(account);
    }

    function thaw(address account)
        external
        onlyVault
        onlyMintableXC20
        returns (bool)
    {
        return IXC20(token).thaw(account);
    }

    function freezeAsset() external onlyVault onlyMintableXC20 returns (bool) {
        return IXC20(token).freezeAsset();
    }

    function freeze_asset() external onlyVault onlyMintableXC20 returns (bool) {
        return IXC20(token).freeze_asset();
    }

    function thawAsset() external onlyVault onlyMintableXC20 returns (bool) {
        return IXC20(token).thawAsset();
    }

    function thaw_asset() external onlyVault onlyMintableXC20 returns (bool) {
        return IXC20(token).thaw_asset();
    }

    function transferOwnership(address _owner)
        external
        onlyVault
        onlyMintableXC20
        returns (bool)
    {
        return IXC20(token).transferOwnership(_owner);
    }

    function transfer_ownership(address _owner)
        external
        onlyVault
        onlyMintableXC20
        returns (bool)
    {
        return IXC20(token).transfer_ownership(_owner);
    }

    function setTeam(
        address issuer,
        address admin,
        address freezer
    ) external onlyVault onlyMintableXC20 returns (bool) {
        return IXC20(token).setTeam(issuer, admin, freezer);
    }

    function set_team(
        address issuer,
        address admin,
        address freezer
    ) external onlyVault onlyMintableXC20 returns (bool) {
        return IXC20(token).set_team(issuer, admin, freezer);
    }

    function _initMetaData(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals
    ) internal {
        bool success;
        try IXC20(token).setMetadata(_name, _symbol, _decimals) returns (
            bool succ
        ) {
            success = succ;
        } catch {}

        if (!success) {
            try IXC20(token).set_metadata(_name, _symbol, _decimals) returns (
                bool succ
            ) {
                success = succ;
            } catch {}
        }

        require(success, "init meta data failed");
    }
}
