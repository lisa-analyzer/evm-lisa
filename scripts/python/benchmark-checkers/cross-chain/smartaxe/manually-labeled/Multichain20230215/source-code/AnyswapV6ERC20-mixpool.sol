// SPDX-License-Identifier: GPL-3.0-or-later
// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.5.0

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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


// File @openzeppelin/contracts/utils/Address.sol@v4.5.0

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol@v4.5.0

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/AnyswapV6ERC20-mixpool.sol


pragma solidity ^0.8.10;

interface IAnyswapMixPool {
    function tokenInfo(address token) external view returns (bool authed, bool canMint);
    function mint(address token, address to, uint256 amount) external returns (bool);
    function burn(address token, address from, uint256 amount) external returns (bool);
    function deposit(address token, uint256 amount, address to) external returns (uint256);
    function withdraw(address token, uint256 amount, address to) external returns (uint256);
    function withdrawVault(address token, uint amount, address to) external returns (uint256);
    function balanceOf(address token, address account) external view returns (uint256);
}

library TokenOperation {
    using Address for address;

    function safeMint(
        address token,
        address to,
        uint256 value
    ) internal {
        // mint(address,uint256)
        _callOptionalReturn(token, abi.encodeWithSelector(0x40c10f19, to, value));
    }

    function safeBurnFrom(
        address token,
        address from,
        uint256 value
    ) internal {
        // burnFrom(address,uint256)
        _callOptionalReturn(token, abi.encodeWithSelector(0x79cc6790, from, value));
    }

    function _callOptionalReturn(address token, bytes memory data) private {
        bytes memory returndata = token.functionCall(data, "TokenOperation: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "TokenOperation: did not succeed");
        }
    }
}

contract AnyswapV6ERC20_MixPool is IAnyswapMixPool {
    using SafeERC20 for IERC20;

    struct TokenInfo {
        bool authed;
        bool canMint;
    }

    mapping(address => TokenInfo) public tokenInfo;

    mapping(address => mapping(address => uint256)) public balanceOf;
    mapping(address => uint256) public totalSupply;

    // init flag for setting immediate vault, needed for CREATE2 support
    bool private _init;

    // delay for timelock functions
    uint public constant DELAY = 2 days;

    // set of minters, can be this bridge or other bridges
    mapping(address => bool) public isMinter;
    address[] public minters;

    // primary controller of the token contract
    address public vault;

    address public pendingMinter;
    uint public delayMinter;

    modifier onlyAuth() {
        require(isMinter[msg.sender], "MixPool: FORBIDDEN");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "MixPool: FORBIDDEN");
        _;
    }

    modifier onlyAuthToken(address token) {
        require(tokenInfo[token].authed, "MixPool: unauth token");
        _;
    }

    event LogChangeVault(address indexed oldVault, address indexed newVault, uint indexed effectiveTime);
    event LogSwapin(string swapID, address indexed token, address indexed account, uint amount);
    event LogSwapout(address indexed token, address indexed account, address indexed bindaddr, uint amount);
    event Transfer(address indexed token, address indexed from, address indexed to, uint256 value);
    event Deposit(address indexed token, address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed token, address indexed from, address indexed to, uint256 amount);

    constructor(address _vault) {
        vault = _vault;
    }

    function getAllMinters() external view returns (address[] memory) {
        return minters;
    }

    function initMinter(address _auth) external onlyVault {
        require(!_init);
        _init = true;
        isMinter[_auth] = true;
        minters.push(_auth);
    }

    function setMinter(address _auth) external onlyVault {
        require(_auth != address(0), "MixPool: address(0)");
        pendingMinter = _auth;
        delayMinter = block.timestamp + DELAY;
    }

    function applyMinter() external {
        require(msg.sender == pendingMinter || msg.sender == vault, "MixPool: FORBIDDEN");
        require(pendingMinter != address(0) && block.timestamp >= delayMinter);
        isMinter[pendingMinter] = true;
        minters.push(pendingMinter);

        pendingMinter = address(0);
        delayMinter = 0;
    }

    function revokeMinter(address _auth) external onlyVault {
        require(isMinter[_auth]);
        isMinter[_auth] = false;
        for (uint i = 0; i < minters.length; i++) {
            if (_auth == minters[i]) {
                minters[i] = minters[minters.length - 1];
                minters.pop();
                return;
            }
        }
    }

    function changeVault(address newVault) external onlyVault returns (bool) {
        require(newVault != address(0), "MixPool: address(0)");
        emit LogChangeVault(vault, newVault, block.timestamp);
        vault = newVault;
        return true;
    }

    function addAuthToken(address token, bool canMint) external onlyVault {
        tokenInfo[token] = TokenInfo(true, canMint);
    }

    function removeAuthToken(address token) external onlyVault {
        tokenInfo[token].authed = false;
    }

    function addAuthTokens(address[] memory tokens, bool[] memory flags) external onlyVault {
        uint256 length = tokens.length;
        require(length == flags.length, "length mismatch");
        for (uint256 i = 0; i < length; i++) {
            tokenInfo[tokens[i]] = TokenInfo(true, flags[i]);
        }
    }

    function removeAuthTokens(address[] memory tokens) external onlyVault {
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenInfo[tokens[i]].authed = false;
        }
    }

    function mint(
        address token,
        address to,
        uint256 amount
    ) external onlyAuth returns (bool) {
        _mint(token, to, amount);
        return true;
    }

    function burn(
        address token,
        address from,
        uint256 amount
    ) external onlyAuth returns (bool) {
        _burn(token, from, amount);
        return true;
    }

    function deposit(address token, uint amount, address to) external returns (uint) {
        require(!tokenInfo[token].canMint);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _mint(token, to, amount);
        emit Deposit(token, msg.sender, to, amount);
        return amount;
    }

    function withdraw(address token, uint amount, address to) external returns (uint) {
        require(!tokenInfo[token].canMint);
        _burn(token, msg.sender, amount);
        IERC20(token).safeTransfer(to, amount);
        emit Withdraw(token, msg.sender, to, amount);
        return amount;
    }

    function withdrawVault(address token, uint amount, address to) external onlyAuth returns (uint) {
        require(!tokenInfo[token].canMint);
        IERC20(token).safeTransfer(to, amount);
        emit Withdraw(token, address(this), to, amount);
        return amount;
    }

    function _mint(address token, address account, uint256 amount) internal onlyAuthToken(token) {
        require(token != address(0) && account != address(0), "MixPool: address(0)");

        if (tokenInfo[token].canMint) {
            TokenOperation.safeMint(token, account, amount);
        } else {
            balanceOf[token][account] += amount;
            emit Transfer(token, address(0), account, amount);
        }

        totalSupply[token] += amount;
    }

    function _burn(address token, address account, uint256 amount) internal onlyAuthToken(token) {
        require(token != address(0) && account != address(0), "MixPool: address(0)");

        uint256 balance = balanceOf[token][account];

        if (balance < amount && tokenInfo[token].canMint) {
            TokenOperation.safeBurnFrom(token, account, amount);
        } else {
            balanceOf[token][account] = balance - amount;
            emit Transfer(token, account, address(0), amount);
        }

        totalSupply[token] -= amount;
    }
}
