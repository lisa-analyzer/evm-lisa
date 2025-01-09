pragma solidity 0.8.10;
// IGNORE_LICENSE-Identifier: MIT

// IGNORE_LICENSE-Identifier: MIT


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @notice claimToken contract. ERC20 contract for LunaFi's LP Tokens
contract claimToken is IERC20 {
    uint8 public decimals;
    address public owner;
    uint256 public _totalSupply;
    uint256 public initialSupply;
    uint256 public constant maxCap = 1000000000 * 10**18;
    string public name;
    string public symbol;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) internal admins;

    modifier onlyAdmin() {
        require(admins[msg.sender]);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @notice constructor to construct the contract with the initial values
    /// @param tokenName The name of the token
    /// @param tokenSymbol The symbol of the token
    constructor(string memory tokenName, string memory tokenSymbol) {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = 18;
        _totalSupply = 0;
        initialSupply = _totalSupply;
        owner = msg.sender;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /// @notice addAdmin function is used to add an admin. Only this admin can call mint or burn the tokens
    /// @param account the EOA address to be added as an admin.
    function addAdmin(address account) public onlyOwner {
        admins[account] = true;
    }

    /// @notice removeAadmin function is used to remove an admin. 
    /// @param account the EOA address to be removed as an admin
    function removeAdmin(address account) public onlyOwner {
        admins[account] = false;
    }

    /// @notice isAdmin function is used to query if the provided address is an admin or not
    /// @param account the EOA address to query if that address is an admin or not
    function isAdmin(address account) public view onlyOwner returns (bool) {
        return admins[account];
    }

    /// @notice totalSupply function returns the total number of tokens
    function totalSupply() external view override returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    /// @notice balanceOf function returns the balance of a particular user
    /// @param tokenOwner the address to which the token balance is returned
    function balanceOf(address tokenOwner)
        external
        view
        override
        returns (uint256 getBalance)
    {
        return balances[tokenOwner];
    }

    /// @notice allowance function that returns the allowance
    function allowance(address tokenOwner, address spender)
        external
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }
    /// @notice Approves an operator to use msg.sender's tokens
    function approve(address spender, uint256 tokens)
        external
        override
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    /// @notice transfer specified amount of tokens of msg.sender to the to address specified
    function transfer(address to, uint256 tokens)
        external
        override
        returns (bool success)
    {
        require(
            to != address(0),
            "claimToken: Address should not be a zero"
        );
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    /// @notice allows opertr to transfet owner's tokens to the specified address
    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external override returns (bool success) {
        require(
            to != address(0),
            "claimToken: Address should not be a zero"
        );
        balances[from] = balances[from] - tokens;
        allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    /// @notice burn function burns the tokens of the token holder
//    SWC-Unprotected Ether Withdrawal: L131-140
    function burn( uint256 tokens) external  {
        uint256 accountBalance = balances[msg.sender];
        require(
            accountBalance >= tokens,
            "claimToken: Burn amount exceeds Balance"
        );
        balances[msg.sender] = accountBalance - tokens;
        _totalSupply = _totalSupply - tokens;
        emit Transfer(msg.sender, address(0), tokens);
    }

    /// @notice Mint Function checks for the maxCap and mints the specified amout of tokens.
    //    SWC-Unprotected Ether Withdrawal: L144-156
    function mint(address account, uint256 tokens) external onlyAdmin {
        require(
            account != address(0),
            "claimToken: Mint from a zero address"
        );
        require(
            _totalSupply + tokens <= maxCap,
            "claimToken Max supply reached, 1 Billion tokens minted."
        );
        balances[account] = balances[account] + tokens;
        _totalSupply = _totalSupply + tokens;
        emit Transfer(address(0), account, tokens);
    }
}
