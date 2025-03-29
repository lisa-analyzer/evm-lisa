/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}



/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}



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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

contract Governance is ReentrancyGuard {

	using SafeERC20 for IERC20;

	uint constant public governance_challenging_period = 10 days;
	uint constant public governance_freeze_period = 30 days;

	address public votingTokenAddress;
	address public governedContractAddress;

	mapping(address => uint) public balances;

	VotedValue[] public votedValues;
	mapping(string => VotedValue) public votedValuesMap;

	event Deposit(address indexed who, uint amount);
	event Withdrawal(address indexed who, uint amount);


	constructor(address _governedContractAddress, address _votingTokenAddress){
		init(_governedContractAddress, _votingTokenAddress);
	}

	function init(address _governedContractAddress, address _votingTokenAddress) public {
		require(governedContractAddress == address(0), "governance already initialized");
		governedContractAddress = _governedContractAddress;
		votingTokenAddress = _votingTokenAddress;
	}

	function addressBelongsToGovernance(address addr) public view returns (bool) {
		for (uint i = 0; i < votedValues.length; i++)
			if (address(votedValues[i]) == addr)
				return true;
		return false;
	}

	function isUntiedFromAllVotes(address addr) public view returns (bool) {
		for (uint i = 0; i < votedValues.length; i++)
			if (votedValues[i].hasVote(addr))
				return false;
		return true;
	}

	function addVotedValue(string memory name, VotedValue votedValue) external {
		require(msg.sender == governedContractAddress, "not authorized");
		votedValues.push(votedValue);
		votedValuesMap[name] = votedValue;
	}


	// deposit

	function deposit(uint amount) payable external {
		deposit(msg.sender, amount);
	}

	function deposit(address from, uint amount) nonReentrant payable public {
		require(from == msg.sender || addressBelongsToGovernance(msg.sender), "not allowed");
		if (votingTokenAddress == address(0))
			require(msg.value == amount, "wrong amount received");
		else {
			require(msg.value == 0, "don't send ETH");
			IERC20(votingTokenAddress).safeTransferFrom(from, address(this), amount);
		}
		balances[from] += amount;
		emit Deposit(from, amount);
	}


	// withdrawal functions

	function withdraw() external {
		withdraw(balances[msg.sender]);
	}

	function withdraw(uint amount) nonReentrant public {
		require(amount > 0, "zero withdrawal requested");
		require(amount <= balances[msg.sender], "not enough balance");
		require(isUntiedFromAllVotes(msg.sender), "some votes not removed yet");
		balances[msg.sender] -= amount;
		if (votingTokenAddress == address(0))
			payable(msg.sender).transfer(amount);
		else
			IERC20(votingTokenAddress).safeTransfer(msg.sender, amount);
		emit Withdrawal(msg.sender, amount);
	}
}


abstract contract VotedValue is ReentrancyGuard {
	Governance public governance;
	uint public challenging_period_start_ts;
	mapping(address => bool) public hasVote;

	constructor(Governance _governance){
		governance = _governance;
	}

	function checkVoteChangeLock() view public {
		require(challenging_period_start_ts + governance.governance_challenging_period() + governance.governance_freeze_period() < block.timestamp, "you cannot change your vote yet");
	}

	function checkChallengingPeriodExpiry() view public {
		require(block.timestamp > challenging_period_start_ts + governance.governance_challenging_period(), "challenging period not expired yet");
	}
}


contract VotedValueUint is VotedValue {

	function(uint) external validationCallback;
	function(uint) external commitCallback;

	uint public leader;
	uint public current_value;

	mapping(address => uint) public choices;
	mapping(uint => uint) public votesByValue;
	mapping(uint => mapping(address => uint)) public votesByValueAddress;

	event Vote(address indexed who, uint indexed value, uint votes, uint total_votes, uint leader, uint leader_total_votes, uint expiry_ts);
	event Unvote(address indexed who, uint indexed value, uint votes);
	event Commit(address indexed who, uint indexed value);

	constructor() VotedValue(Governance(address(0))) {}

	// constructor(Governance _governance, uint initial_value, function(uint) external _validationCallback, function(uint) external _commitCallback) VotedValue(_governance) {
	// 	leader = initial_value;
	// 	current_value = initial_value;
	// 	validationCallback = _validationCallback;
	// 	commitCallback = _commitCallback;
	// }

	function init(Governance _governance, uint initial_value, function(uint) external _validationCallback, function(uint) external _commitCallback) external {
		require(address(governance) == address(0), "already initialized");
		governance = _governance;
		leader = initial_value;
		current_value = initial_value;
		validationCallback = _validationCallback;
		commitCallback = _commitCallback;
	}

	function vote(uint value) nonReentrant external {
		_vote(value);
	}

	function voteAndDeposit(uint value, uint amount) nonReentrant payable external {
		governance.deposit{value: msg.value}(msg.sender, amount);
		_vote(value);
	}

	function _vote(uint value) private {
		validationCallback(value);
		uint prev_choice = choices[msg.sender];
		bool hadVote = hasVote[msg.sender];
		if (prev_choice == leader)
			checkVoteChangeLock();

		// first, remove votes from the previous choice
		if (hadVote)
			removeVote(prev_choice);

		// then, add them to the new choice
		uint balance = governance.balances(msg.sender);
		require(balance > 0, "no balance");
		votesByValue[value] += balance;
		votesByValueAddress[value][msg.sender] = balance;
		choices[msg.sender] = value;
		hasVote[msg.sender] = true;

		// check if the leader has just changed
		if (votesByValue[value] > votesByValue[leader]){
			leader = value;
			challenging_period_start_ts = block.timestamp;
		}
		emit Vote(msg.sender, value, balance, votesByValue[value], leader, votesByValue[leader], challenging_period_start_ts + governance.governance_challenging_period());
	}

	function unvote() external {
		if (!hasVote[msg.sender])
			return;
		uint prev_choice = choices[msg.sender];
		if (prev_choice == leader)
			checkVoteChangeLock();
		
		removeVote(prev_choice);
		delete choices[msg.sender];
		delete hasVote[msg.sender];
		emit Unvote(msg.sender, prev_choice, votesByValue[prev_choice]);
	}

	function removeVote(uint value) internal {
		votesByValue[value] -= votesByValueAddress[value][msg.sender];
		votesByValueAddress[value][msg.sender] = 0;
	}

	function commit() nonReentrant external {
		require(leader != current_value, "already equal to leader");
		checkChallengingPeriodExpiry();
		current_value = leader;
		commitCallback(leader);
		emit Commit(msg.sender, leader);
	}
}




contract VotedValueUintArray is VotedValue {

	function(uint[] memory) external validationCallback;
	function(uint[] memory) external commitCallback;

	uint[] public leader;
	uint[] public current_value;

	mapping(address => uint[]) public choices;
	mapping(bytes32 => uint) public votesByValue;
	mapping(bytes32 => mapping(address => uint)) public votesByValueAddress;

	event Vote(address indexed who, uint[] value, uint votes, uint total_votes, uint[] leader, uint leader_total_votes, uint expiry_ts);
	event Unvote(address indexed who, uint[] value, uint votes);
	event Commit(address indexed who, uint[] value);

	constructor() VotedValue(Governance(address(0))) {}

	// constructor(Governance _governance, uint[] memory initial_value, function(uint[] memory) external _validationCallback, function(uint[] memory) external _commitCallback) VotedValue(_governance) {
	// 	leader = initial_value;
	// 	current_value = initial_value;
	// 	validationCallback = _validationCallback;
	// 	commitCallback = _commitCallback;
	// }

	function init(Governance _governance, uint[] memory initial_value, function(uint[] memory) external _validationCallback, function(uint[] memory) external _commitCallback) external {
		require(address(governance) == address(0), "already initialized");
		governance = _governance;
		leader = initial_value;
		current_value = initial_value;
		validationCallback = _validationCallback;
		commitCallback = _commitCallback;
	}

	function equal(uint[] memory a1, uint[] memory a2) public pure returns (bool) {
		if (a1.length != a2.length)
			return false;
		for (uint i = 0; i < a1.length; i++)
			if (a1[i] != a2[i])
				return false;
		return true;
	}

	function getKey(uint[] memory a) public pure returns (bytes32){
		return keccak256(abi.encodePacked(a));
	}

	function vote(uint[] memory value) nonReentrant external {
		_vote(value);
	}

	function voteAndDeposit(uint[] memory value, uint amount) nonReentrant payable external {
		governance.deposit{value: msg.value}(msg.sender, amount);
		_vote(value);
	}

	function _vote(uint[] memory value) private {
		validationCallback(value);
		uint[] storage prev_choice = choices[msg.sender];
		bool hadVote = hasVote[msg.sender];
		if (equal(prev_choice, leader))
			checkVoteChangeLock();

		// remove one's vote from the previous choice first
		if (hadVote)
			removeVote(prev_choice);

		// then, add it to the new choice, if any
		bytes32 key = getKey(value);
		uint balance = governance.balances(msg.sender);
		require(balance > 0, "no balance");
		votesByValue[key] += balance;
		votesByValueAddress[key][msg.sender] = balance;
		choices[msg.sender] = value;
		hasVote[msg.sender] = true;

		// check if the leader has just changed
		if (votesByValue[key] > votesByValue[getKey(leader)]){
			leader = value;
			challenging_period_start_ts = block.timestamp;
		}
		emit Vote(msg.sender, value, balance, votesByValue[key], leader, votesByValue[getKey(leader)], challenging_period_start_ts + governance.governance_challenging_period());
	}

	function unvote() external {
		if (!hasVote[msg.sender])
			return;
		uint[] storage prev_choice = choices[msg.sender];
		if (equal(prev_choice, leader))
			checkVoteChangeLock();
		
		removeVote(prev_choice);
		delete choices[msg.sender];
		delete hasVote[msg.sender];
		emit Unvote(msg.sender, prev_choice, votesByValue[getKey(prev_choice)]);
	}

	function removeVote(uint[] memory value) internal {
		bytes32 key = getKey(value);
		votesByValue[key] -= votesByValueAddress[key][msg.sender];
		votesByValueAddress[key][msg.sender] = 0;
	}

	function commit() nonReentrant external {
		require(!equal(leader, current_value), "already equal to leader");
		checkChallengingPeriodExpiry();
		current_value = leader;
		commitCallback(leader);
		emit Commit(msg.sender, leader);
	}
}



contract VotedValueAddress is VotedValue {

	function(address) external validationCallback;
	function(address) external commitCallback;

	address public leader;
	address public current_value;

	// mapping(who => value)
	mapping(address => address) public choices;

	// mapping(value => votes)
	mapping(address => uint) public votesByValue;

	// mapping(value => mapping(who => votes))
	mapping(address => mapping(address => uint)) public votesByValueAddress;

	event Vote(address indexed who, address indexed value, uint votes, uint total_votes, address leader, uint leader_total_votes, uint expiry_ts);
	event Unvote(address indexed who, address indexed value, uint votes);
	event Commit(address indexed who, address indexed value);

	constructor() VotedValue(Governance(address(0))) {}

	// constructor(Governance _governance, address initial_value, function(address) external _validationCallback, function(address) external _commitCallback) VotedValue(_governance) {
	// 	leader = initial_value;
	// 	current_value = initial_value;
	// 	validationCallback = _validationCallback;
	// 	commitCallback = _commitCallback;
	// }

	function init(Governance _governance, address initial_value, function(address) external _validationCallback, function(address) external _commitCallback) external {
		require(address(governance) == address(0), "already initialized");
		governance = _governance;
		leader = initial_value;
		current_value = initial_value;
		validationCallback = _validationCallback;
		commitCallback = _commitCallback;
	}

	function vote(address value) nonReentrant external {
		_vote(value);
	}

	function voteAndDeposit(address value, uint amount) nonReentrant payable external {
		governance.deposit{value: msg.value}(msg.sender, amount);
		_vote(value);
	}

	function _vote(address value) private {
		validationCallback(value);
		address prev_choice = choices[msg.sender];
		bool hadVote = hasVote[msg.sender];
		if (prev_choice == leader)
			checkVoteChangeLock();

		// first, remove votes from the previous choice
		if (hadVote)
			removeVote(prev_choice);

		// then, add them to the new choice
		uint balance = governance.balances(msg.sender);
		require(balance > 0, "no balance");
		votesByValue[value] += balance;
		votesByValueAddress[value][msg.sender] = balance;
		choices[msg.sender] = value;
		hasVote[msg.sender] = true;

		// check if the leader has just changed
		if (votesByValue[value] > votesByValue[leader]){
			leader = value;
			challenging_period_start_ts = block.timestamp;
		}
		emit Vote(msg.sender, value, balance, votesByValue[value], leader, votesByValue[leader], challenging_period_start_ts + governance.governance_challenging_period());
	}

	function unvote() external {
		if (!hasVote[msg.sender])
			return;
		address prev_choice = choices[msg.sender];
		if (prev_choice == leader)
			checkVoteChangeLock();
		
		removeVote(prev_choice);
		delete choices[msg.sender];
		delete hasVote[msg.sender];
		emit Unvote(msg.sender, prev_choice, votesByValue[prev_choice]);
	}

	function removeVote(address value) internal {
		votesByValue[value] -= votesByValueAddress[value][msg.sender];
		votesByValueAddress[value][msg.sender] = 0;
	}

	function commit() nonReentrant external {
		require(leader != current_value, "already equal to leader");
		checkChallengingPeriodExpiry();
		current_value = leader;
		commitCallback(leader);
		emit Commit(msg.sender, leader);
	}
}


contract VotedValueFactory {

	address public immutable votedValueUintMaster;
	address public immutable votedValueUintArrayMaster;
	address public immutable votedValueAddressMaster;

	constructor(address _votedValueUintMaster, address _votedValueUintArrayMaster, address _votedValueAddressMaster) {
		votedValueUintMaster = _votedValueUintMaster;
		votedValueUintArrayMaster = _votedValueUintArrayMaster;
		votedValueAddressMaster = _votedValueAddressMaster;
	}


	function createVotedValueUint(Governance governance, uint initial_value, function(uint) external validationCallback, function(uint) external commitCallback) external returns (VotedValueUint) {
		VotedValueUint vv = VotedValueUint(Clones.clone(votedValueUintMaster));
		vv.init(governance, initial_value, validationCallback, commitCallback);
		return vv;
	}

	function createVotedValueUintArray(Governance governance, uint[] memory initial_value, function(uint[] memory) external validationCallback, function(uint[] memory) external commitCallback) external returns (VotedValueUintArray) {
		VotedValueUintArray vv = VotedValueUintArray(Clones.clone(votedValueUintArrayMaster));
		vv.init(governance, initial_value, validationCallback, commitCallback);
		return vv;
	}

	function createVotedValueAddress(Governance governance, address initial_value, function(address) external validationCallback, function(address) external commitCallback) external returns (VotedValueAddress) {
		VotedValueAddress vv = VotedValueAddress(Clones.clone(votedValueAddressMaster));
		vv.init(governance, initial_value, validationCallback, commitCallback);
		return vv;
	}

}




contract GovernanceFactory {

	address public immutable governanceMaster;

	constructor(address _governanceMaster) {
		governanceMaster = _governanceMaster;
	}

	function createGovernance(address governedContractAddress, address votingTokenAddress) external returns (Governance) {
		Governance governance = Governance(Clones.clone(governanceMaster));
		governance.init(governedContractAddress, votingTokenAddress);
		return governance;
	}

}






// The purpose of the library is to separate some of the code out of the Export/Import contracts and keep their sizes under the 24KiB limit


library CounterstakeLibrary {

	using SafeERC20 for IERC20;

	enum Side {no, yes}

	// small values (bool, uint32, ...) are grouped together in order to be packed efficiently
	struct Claim {
		uint amount;
	//	int reward;

		address payable recipient_address; // 20 bytes, 12 bytes left
		uint32 txts;
		uint32 ts;
		
		address payable claimant_address;
		uint32 expiry_ts;
		uint16 period_number;
		Side current_outcome;
		bool is_large;
		bool withdrawn;
		bool finished;
		
		string sender_address;
	//	string txid;
		string data;
		uint yes_stake;
		uint no_stake;
	//	uint challenging_target;
	}

	struct Settings {
		address tokenAddress;
		uint16 ratio100;// = 100;
		uint16 counterstake_coef100;// = 150;
		uint32 min_tx_age;
		uint min_stake;
		uint[] challenging_periods;// = [12 hours, 3 days, 1 weeks, 30 days];
		uint[] large_challenging_periods;// = [3 days, 1 weeks, 30 days];
		uint large_threshold;
	}

	event NewClaim(uint indexed claim_num, address author_address, string sender_address, address recipient_address, string txid, uint32 txts, uint amount, int reward, uint stake, string data, uint32 expiry_ts);
	event NewChallenge(uint indexed claim_num, address author_address, uint stake, Side outcome, Side current_outcome, uint yes_stake, uint no_stake, uint32 expiry_ts, uint challenging_target);
	event FinishedClaim(uint indexed claim_num, Side outcome);


	struct ClaimRequest {
		string txid;
		uint32 txts;
		uint amount;
		int reward;
		uint stake;
		uint required_stake;
		address payable recipient_address;
		string sender_address;
		string data;
	}

	function claim(
		Settings storage settings,
		mapping(string => uint) storage claim_nums,
		mapping(uint => Claim) storage claims,
		mapping(uint => mapping(Side => mapping(address => uint))) storage stakes,
		uint claim_num,
		ClaimRequest memory req
	) external {
		require(req.amount > 0, "0 claim");
		require(req.stake >= req.required_stake, "the stake is too small");
		require(block.timestamp >= req.txts + settings.min_tx_age, "too early");
		if (req.recipient_address == address(0))
			req.recipient_address = payable(msg.sender);
		if (req.reward < 0)
			require(req.recipient_address == payable(msg.sender), "the sender disallowed third-party claiming by setting a negative reward");
		string memory claim_id = getClaimId(req.sender_address, req.recipient_address, req.txid, req.txts, req.amount, req.reward, req.data);
		require(claim_nums[claim_id] == 0, "this transfer has already been claimed");
		bool is_large = (settings.large_threshold > 0 && req.stake >= settings.large_threshold);
		uint32 expiry_ts = uint32(block.timestamp + getChallengingPeriod(settings, 0, is_large)); // might wrap
		claim_nums[claim_id] = claim_num;
	//	uint challenging_target = req.stake * settings.counterstake_coef100/100;
		claims[claim_num] = Claim({
			amount: req.amount,
		//	reward: req.reward,
			recipient_address: req.recipient_address,
			claimant_address: payable(msg.sender),
			sender_address: req.sender_address,
		//	txid: req.txid,
			data: req.data,
			yes_stake: req.stake,
			no_stake: 0,
			current_outcome: Side.yes,
			is_large: is_large,
			period_number: 0,
			txts: req.txts,
			ts: uint32(block.timestamp),
			expiry_ts: expiry_ts,
		//	challenging_target: req.stake * settings.counterstake_coef100/100,
			withdrawn: false,
			finished: false
		});
		stakes[claim_num][Side.yes][msg.sender] = req.stake;
		emit NewClaim(claim_num, msg.sender, req.sender_address, req.recipient_address, req.txid, req.txts, req.amount, req.reward, req.stake, req.data, expiry_ts);
	//	return claim_id;
	}


	function challenge(
		Settings storage settings, 
		Claim storage c,
		mapping(uint => mapping(Side => mapping(address => uint))) storage stakes, 
		uint claim_num, 
		Side stake_on, 
		uint stake
	) external {
		require(block.timestamp < c.expiry_ts, "the challenging period has expired");
		require(stake_on != c.current_outcome, "this outcome is already current");
		uint excess;
		uint challenging_target = (c.current_outcome == Side.yes ? c.yes_stake : c.no_stake) * settings.counterstake_coef100/100;
		{ // circumvent stack too deep
			uint stake_on_proposed_outcome = (stake_on == Side.yes ? c.yes_stake : c.no_stake) + stake;
			bool would_override_current_outcome = stake_on_proposed_outcome >= challenging_target;
			excess = would_override_current_outcome ? stake_on_proposed_outcome - challenging_target : 0;
			uint accepted_stake = stake - excess;
			if (stake_on == Side.yes)
				c.yes_stake += accepted_stake;
			else
				c.no_stake += accepted_stake;
			if (would_override_current_outcome){
				c.period_number++;
				c.current_outcome = stake_on;
				c.expiry_ts = uint32(block.timestamp + getChallengingPeriod(settings, c.period_number, c.is_large));
				challenging_target = challenging_target * settings.counterstake_coef100/100;
			}
			stakes[claim_num][stake_on][msg.sender] += accepted_stake;
		}
		emit NewChallenge(claim_num, msg.sender, stake, stake_on, c.current_outcome, c.yes_stake, c.no_stake, c.expiry_ts, challenging_target);
		if (excess > 0){
			if (settings.tokenAddress == address(0))
				payable(msg.sender).transfer(excess);
			else
				IERC20(settings.tokenAddress).safeTransfer(msg.sender, excess);
		}
	}



	function finish(
		Claim storage c,
		mapping(uint => mapping(Side => mapping(address => uint))) storage stakes, 
		uint claim_num, 
		address payable to_address
	) external 
	returns (bool, bool, uint)
	{
		require(block.timestamp > c.expiry_ts, "challenging period is still ongoing");
		if (to_address == address(0))
			to_address = payable(msg.sender);
		
		bool is_winning_claimant = (to_address == c.claimant_address && c.current_outcome == Side.yes);
		require(!(is_winning_claimant && c.withdrawn), "already withdrawn");
		uint won_stake;
		{ // circumvent stack too deep
			uint my_stake = stakes[claim_num][c.current_outcome][to_address];
			require(my_stake > 0 || is_winning_claimant, "you are not the recipient and you didn't stake on the winning outcome or you have already withdrawn");
			uint winning_stake = c.current_outcome == Side.yes ? c.yes_stake : c.no_stake;
			if (my_stake > 0)
				won_stake = (c.yes_stake + c.no_stake) * my_stake / winning_stake;
		}
		if (is_winning_claimant)
			c.withdrawn = true;
		bool finished;
		if (!c.finished){
			finished = true;
			c.finished = true;
		//	Side losing_outcome = outcome == Side.yes ? Side.no : Side.yes;
		//	delete stakes[claim_id][losing_outcome]; // can't purge the stakes that will never be claimed
			emit FinishedClaim(claim_num, c.current_outcome);
		}
		delete stakes[claim_num][c.current_outcome][to_address];
		return (finished, is_winning_claimant, won_stake);
	}



	function getChallengingPeriod(Settings storage settings, uint16 period_number, bool bLarge) public view returns (uint) {
		uint[] storage periods = bLarge ? settings.large_challenging_periods : settings.challenging_periods;
		if (period_number > periods.length - 1)
			period_number = uint16(periods.length - 1);
		return periods[period_number];
	}

	function validateChallengingPeriods(uint[] memory periods) pure external {
		require(periods.length > 0, "empty periods");
		uint prev_period = 0;
		for (uint i = 0; i < periods.length; i++) {
			require(periods[i] < 3 * 365 days, "some periods are longer than 3 years");
			require(periods[i] >= prev_period, "subsequent periods cannot get shorter");
			prev_period = periods[i];
		}
	}

	function getClaimId(string memory sender_address, address recipient_address, string memory txid, uint32 txts, uint amount, int reward, string memory data) public pure returns (string memory){
		return string(abi.encodePacked(sender_address, '_', toAsciiString(recipient_address), '_', txid, '_', uint2str(txts), '_', uint2str(amount), '_', int2str(reward), '_', data));
	}


	function uint2str(uint256 _i) private pure returns (string memory) {
		if (_i == 0)
			return "0";
		uint256 j = _i;
		uint256 length;
		while (j != 0) {
			length++;
			j /= 10;
		}
		bytes memory bstr = new bytes(length);
		uint256 k = length;
		j = _i;
		while (j != 0) {
			bstr[--k] = bytes1(uint8(48 + j % 10));
			j /= 10;
		}
		return string(bstr);
	}

	function int2str(int256 _i) private pure returns (string memory) {
		require(_i < type(int).max, "int too large");
		return _i >= 0 ? uint2str(uint(_i)) : string(abi.encodePacked('-', uint2str(uint(-_i))));
	}

	function toAsciiString(address x) private pure returns (string memory) {
		bytes memory s = new bytes(40);
		for (uint i = 0; i < 20; i++) {
			bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
			bytes1 hi = bytes1(uint8(b) / 16);
			bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
			s[2*i] = char(hi);
			s[2*i+1] = char(lo);            
		}
		return string(s);
	}

	function char(bytes1 b) private pure returns (bytes1 c) {
		if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
		else return bytes1(uint8(b) + 0x57);
	}

	function isContract(address _addr) public view returns (bool){
		uint32 size;
		assembly {
			size := extcodesize(_addr)
		}
		return (size > 0);
	}
}




/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface CounterstakeReceiver {
	function onReceivedFromClaim(uint claim_num, uint net_claimed_amount, uint won_stake, string memory sender_address, address claim_recipient_address, string memory data) external;
}

abstract contract Counterstake is ReentrancyGuard {

	using SafeERC20 for IERC20;

	event NewClaim(uint indexed claim_num, address author_address, string sender_address, address recipient_address, string txid, uint32 txts, uint amount, int reward, uint stake, string data, uint32 expiry_ts);
	event NewChallenge(uint indexed claim_num, address author_address, uint stake, CounterstakeLibrary.Side outcome, CounterstakeLibrary.Side current_outcome, uint yes_stake, uint no_stake, uint32 expiry_ts, uint challenging_target);
	event FinishedClaim(uint indexed claim_num, CounterstakeLibrary.Side outcome);

	Governance public governance;
	CounterstakeLibrary.Settings public settings;


	uint64 public last_claim_num;
	uint64[] public ongoing_claim_nums;
	mapping(uint => uint) public num2index;

	mapping(string => uint) public claim_nums;
	mapping(uint => CounterstakeLibrary.Claim) private claims;
	mapping(uint => mapping(CounterstakeLibrary.Side => mapping(address => uint))) public stakes;

	function getClaim(uint claim_num) external view returns (CounterstakeLibrary.Claim memory) {
		return claims[claim_num];
	}

	function getClaim(string memory claim_id) external view returns (CounterstakeLibrary.Claim memory) {
		return claims[claim_nums[claim_id]];
	}

	function getOngoingClaimNums() external view returns (uint64[] memory) {
		return ongoing_claim_nums;
	}


	constructor (address _tokenAddr, uint16 _counterstake_coef100, uint16 _ratio100, uint _large_threshold, uint[] memory _challenging_periods, uint[] memory _large_challenging_periods) {
		initCounterstake(_tokenAddr, _counterstake_coef100, _ratio100, _large_threshold, _challenging_periods, _large_challenging_periods);
	}

	function initCounterstake(address _tokenAddr, uint16 _counterstake_coef100, uint16 _ratio100, uint _large_threshold, uint[] memory _challenging_periods, uint[] memory _large_challenging_periods) public {
		require(address(governance) == address(0), "already initialized");
		validateRatio(_ratio100);
		validateCounterstakeCoef(_counterstake_coef100);
		validateChallengingPeriods(_challenging_periods);
		validateChallengingPeriods(_large_challenging_periods);
		settings = CounterstakeLibrary.Settings({
			tokenAddress: _tokenAddr,
			counterstake_coef100: _counterstake_coef100 > 100 ? _counterstake_coef100 : 150,
			ratio100: _ratio100 > 0 ? _ratio100 : 100,
			min_stake: 0,
			min_tx_age: 0,
			challenging_periods: _challenging_periods,
			large_challenging_periods: _large_challenging_periods,
			large_threshold: _large_threshold
		});
	}

	/*
	modifier onlyETH(){
		require(settings.tokenAddress == address(0), "ETH only");
		_;
	}

	modifier onlyERC20(){
		require(settings.tokenAddress != address(0), "ERC20 only");
		_;
	}*/

	modifier onlyVotedValueContract(){
		require(governance.addressBelongsToGovernance(msg.sender), "not from voted value contract");
		_;
	}

	// would be happy to call this from the constructor but unfortunately `this` is not set at that time yet
	function setupCounterstakeGovernance(GovernanceFactory governanceFactory, VotedValueFactory votedValueFactory, address votingTokenAddress) internal {
		require(address(governance) == address(0), "already initialized");
		governance = governanceFactory.createGovernance(address(this), votingTokenAddress);

		governance.addVotedValue("ratio100", votedValueFactory.createVotedValueUint(governance, settings.ratio100, this.validateRatio, this.setRatio));
		governance.addVotedValue("counterstake_coef100", votedValueFactory.createVotedValueUint(governance, settings.counterstake_coef100, this.validateCounterstakeCoef, this.setCounterstakeCoef));
		governance.addVotedValue("min_stake", votedValueFactory.createVotedValueUint(governance, settings.min_stake, this.validateMinStake, this.setMinStake));
		governance.addVotedValue("min_tx_age", votedValueFactory.createVotedValueUint(governance, settings.min_tx_age, this.validateMinTxAge, this.setMinTxAge));
		governance.addVotedValue("large_threshold", votedValueFactory.createVotedValueUint(governance, settings.large_threshold, this.validateLargeThreshold, this.setLargeThreshold));
		governance.addVotedValue("challenging_periods", votedValueFactory.createVotedValueUintArray(governance, settings.challenging_periods, this.validateChallengingPeriods, this.setChallengingPeriods));
		governance.addVotedValue("large_challenging_periods", votedValueFactory.createVotedValueUintArray(governance, settings.large_challenging_periods, this.validateChallengingPeriods, this.setLargeChallengingPeriods));
	}

	function validateRatio(uint _ratio100) pure public {
		require(_ratio100 > 0 && _ratio100 < 64000, "bad ratio");
	}

	function setRatio(uint _ratio100) onlyVotedValueContract external {
		settings.ratio100 = uint16(_ratio100);
	}

	
	function validateCounterstakeCoef(uint _counterstake_coef100) pure public {
		require(_counterstake_coef100 > 100 && _counterstake_coef100 < 64000, "bad counterstake coef");
	}

	function setCounterstakeCoef(uint _counterstake_coef100) onlyVotedValueContract external {
		settings.counterstake_coef100 = uint16(_counterstake_coef100);
	}

	
	function validateMinStake(uint _min_stake) pure external {
		// anything goes
	}

	function setMinStake(uint _min_stake) onlyVotedValueContract external {
		settings.min_stake = _min_stake;
	}


	function validateMinTxAge(uint _min_tx_age) pure external {
		require(_min_tx_age < 4 weeks, "min tx age too large");
	}

	function setMinTxAge(uint _min_tx_age) onlyVotedValueContract external {
		settings.min_tx_age = uint32(_min_tx_age);
	}


	function validateLargeThreshold(uint _large_threshold) pure external {
		// anything goes
	}

	function setLargeThreshold(uint _large_threshold) onlyVotedValueContract external {
		settings.large_threshold = _large_threshold;
	}


	function validateChallengingPeriods(uint[] memory periods) pure public {
		CounterstakeLibrary.validateChallengingPeriods(periods);
	}

	function setChallengingPeriods(uint[] memory _challenging_periods) onlyVotedValueContract external {
		settings.challenging_periods = _challenging_periods;
	}

	function setLargeChallengingPeriods(uint[] memory _large_challenging_periods) onlyVotedValueContract external {
		settings.large_challenging_periods = _large_challenging_periods;
	}


	function getChallengingPeriod(uint16 period_number, bool bLarge) external view returns (uint) {
		return CounterstakeLibrary.getChallengingPeriod(settings, period_number, bLarge);
	}

	function getRequiredStake(uint amount) public view virtual returns (uint);

	function getMissingStake(uint claim_num, CounterstakeLibrary.Side stake_on) external view returns (uint) {
		CounterstakeLibrary.Claim storage c = claims[claim_num];
		require(c.yes_stake > 0, "no such claim");
		uint current_stake = (stake_on == CounterstakeLibrary.Side.yes) ? c.yes_stake : c.no_stake;
		return (c.current_outcome == CounterstakeLibrary.Side.yes ? c.yes_stake : c.no_stake) * settings.counterstake_coef100/100 - current_stake;
	}



	function claim(string memory txid, uint32 txts, uint amount, int reward, uint stake, string memory sender_address, address payable recipient_address, string memory data) nonReentrant payable external {
		if (recipient_address == address(0))
			recipient_address = payable(msg.sender);
		bool bThirdPartyClaiming = (recipient_address != payable(msg.sender) && reward >= 0);
		uint paid_amount;
		if (bThirdPartyClaiming) {
			require(amount > uint(reward), "reward too large");
			paid_amount = amount - uint(reward);
		}
		receiveMoneyInClaim(stake, paid_amount);
		uint required_stake = getRequiredStake(amount);
		CounterstakeLibrary.ClaimRequest memory req = CounterstakeLibrary.ClaimRequest({
			txid: txid,
			txts: txts,
			amount: amount,
			reward: reward,
			stake: stake,
			required_stake: required_stake,
			recipient_address: recipient_address,
			sender_address: sender_address,
			data: data
		});
		last_claim_num++;
		ongoing_claim_nums.push(last_claim_num);
		num2index[last_claim_num] = ongoing_claim_nums.length - 1;

		CounterstakeLibrary.claim(settings, claim_nums, claims, stakes, last_claim_num, req);
		
		if (bThirdPartyClaiming){
			sendToClaimRecipient(recipient_address, paid_amount);
			notifyPaymentRecipient(recipient_address, paid_amount, 0, last_claim_num);
		}
	}
	

	function challenge(string calldata claim_id, CounterstakeLibrary.Side stake_on, uint stake) payable external {
		challenge(claim_nums[claim_id], stake_on, stake);
	}

	function challenge(uint claim_num, CounterstakeLibrary.Side stake_on, uint stake) nonReentrant payable public {
		receiveStakeAsset(stake);
		CounterstakeLibrary.Claim storage c = claims[claim_num];
		require(c.amount > 0, "no such claim");
		CounterstakeLibrary.challenge(settings, c, stakes, claim_num, stake_on, stake);
	}

	function withdraw(string memory claim_id) external {
		withdraw(claim_nums[claim_id], payable(0));
	}

	function withdraw(uint claim_num) external {
		withdraw(claim_num, payable(0));
	}

	function withdraw(string memory claim_id, address payable to_address) external {
		withdraw(claim_nums[claim_id], to_address);
	}

	function withdraw(uint claim_num, address payable to_address) nonReentrant public {
		if (to_address == address(0))
			to_address = payable(msg.sender);
		require(claim_num > 0, "no such claim num");
		CounterstakeLibrary.Claim storage c = claims[claim_num];
		require(c.amount > 0, "no such claim");

		(bool finished, bool is_winning_claimant, uint won_stake) = CounterstakeLibrary.finish(c, stakes, claim_num, to_address);
		
		if (finished){
			uint index = num2index[claim_num];
			uint last_index = ongoing_claim_nums.length - 1;
			if (index != last_index){ // move the last element in place of our removed element
				require(index < last_index, "BUG index after last");
				uint64 claim_num_of_last_element = ongoing_claim_nums[last_index];
				num2index[claim_num_of_last_element] = index;
				ongoing_claim_nums[index] = claim_num_of_last_element;
			}
			ongoing_claim_nums.pop();
			delete num2index[claim_num];
		}

		uint claimed_amount_to_be_paid = is_winning_claimant ? c.amount : 0;
		sendWithdrawals(to_address, claimed_amount_to_be_paid, won_stake);
		notifyPaymentRecipient(to_address, claimed_amount_to_be_paid, won_stake, claim_num);
	}

//	event ExternalCall(bool res, string errtype, uint initial_gas, uint gas, address payment_recipient_address);

	function notifyPaymentRecipient(address payable payment_recipient_address, uint net_claimed_amount, uint won_stake, uint claim_num) private {
		if (CounterstakeLibrary.isContract(payment_recipient_address) && _supportsERC165Interface(payment_recipient_address, type(CounterstakeReceiver).interfaceId)){
			CounterstakeLibrary.Claim storage c = claims[claim_num];
			CounterstakeReceiver(payment_recipient_address).onReceivedFromClaim(claim_num, net_claimed_amount, won_stake, c.sender_address, c.recipient_address, c.data);
			/*
			uint initial_gas = gasleft();
			// Goal: ignore if the function does not exist, otherwise bubble up all errors.
			// Unfortunately, there is no easy way to check if the function exists
			// There are 4 possible outcomes:
			// 1. The called function exists and succeeds.
			// 2. The called function exists and reverts (failed require(), division by 0, etc). We revert.
			// 3. The called function exists but runs out of gas. Otherwise it could succeed or revert. We revert.
			// 4. The called function does not exist. We ignore the error.
			try CounterstakeReceiver(payment_recipient_address).onReceivedFromClaim(claim_num, net_claimed_amount, won_stake, c.sender_address, c.recipient_address, c.data) {
				// all is good
			//	emit ExternalCall(true, "", initial_gas, gasleft(), payment_recipient_address);
			}
			catch Error(string memory reason){
			//	emit ExternalCall(false, "error", initial_gas, gasleft(), payment_recipient_address);
				revert(reason);
			}
			catch Panic(uint){
			//	emit ExternalCall(false, "panic", initial_gas, gasleft(), payment_recipient_address);
				revert("panic from onReceivedFromClaim");
			}
			catch{
			//	emit ExternalCall(false, "catchall", initial_gas, gasleft(), payment_recipient_address);
				// both OOG and non-existent function get us here
				// if only 1/64th is left, all forwarded gas has been consumed, which indicates OOG
				require(gasleft() > initial_gas/64, "probably out-of-gas");
				// otherwise probably non-existent function - ignore
				// Not perfect: the callee could make another external call (with 63/64 of gas), which OOGed, but our callee has retained 1/64 of its gas
			}
			*/
			/*
			(bool res, ) = payment_recipient_address.call(abi.encodeWithSignature("onReceivedFromClaim(uint256,uint256,uint256,string,address,string)", claim_num, net_claimed_amount, won_stake, c.sender_address, c.recipient_address, c.data));
		//	emit ExternalCall(res, payment_recipient_address);
		//	require(res || claim_num > 0, "unres");
			if (!res){
				// ignore
			}
			*/
		}
	}

	// copied from OZ's ERC165Checker. No point calling ERC165Checker.supportsInterface() which makes 2 more calls to determine if EIP165 itself is supported
	function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
		bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
		(bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
		if (result.length < 32) return false;
		return success && abi.decode(result, (bool));
	}

	function receiveStakeAsset(uint stake_asset_amount) internal {
		if (settings.tokenAddress == address(0))
			require(msg.value == stake_asset_amount, "wrong amount received");
		else {
			require(msg.value == 0, "don't send ETH");
			IERC20(settings.tokenAddress).safeTransferFrom(msg.sender, address(this), stake_asset_amount);
		}
	}

	function sendWithdrawals(address payable to_address, uint claimed_amount_to_be_paid, uint won_stake) internal virtual;
	
	function sendToClaimRecipient(address payable to_address, uint paid_amount) internal virtual;

	function receiveMoneyInClaim(uint stake, uint paid_amount) internal virtual;

}





contract Export is Counterstake {

	using SafeERC20 for IERC20;

	event NewExpatriation(address sender_address, uint amount, int reward, string foreign_address, string data);

	string public foreign_network;
	string public foreign_asset;

	constructor (string memory _foreign_network, string memory _foreign_asset, address _tokenAddr, uint16 _counterstake_coef100, uint16 _ratio100, uint _large_threshold, uint[] memory _challenging_periods, uint[] memory _large_challenging_periods)
	Counterstake(_tokenAddr, _counterstake_coef100, _ratio100, _large_threshold, _challenging_periods, _large_challenging_periods)
	{
		foreign_network = _foreign_network;
		foreign_asset = _foreign_asset;
	}

	function initExport(string memory _foreign_network, string memory _foreign_asset) public
	{
		require(address(governance) == address(0), "already initialized");
		foreign_network = _foreign_network;
		foreign_asset = _foreign_asset;
	}

	function setupGovernance(GovernanceFactory governanceFactory, VotedValueFactory votedValueFactory) external {
		setupCounterstakeGovernance(governanceFactory, votedValueFactory, settings.tokenAddress);
	}


	function transferToForeignChain(string memory foreign_address, string memory data, uint amount, int reward) payable nonReentrant external {
		receiveStakeAsset(amount);
		if (reward >= 0)
			require(uint(reward) < amount, "reward too big");
		emit NewExpatriation(msg.sender, amount, reward, foreign_address, data);
	}


	function getRequiredStake(uint amount) public view override returns (uint) {
		return Math.max(amount * settings.ratio100 / 100, settings.min_stake);
	}


	function sendWithdrawals(address payable to_address, uint paid_claimed_amount, uint won_stake) internal override {
		uint total = won_stake + paid_claimed_amount;
		if (settings.tokenAddress == address(0)) {
			to_address.transfer(total);
		}
		else {
			IERC20(settings.tokenAddress).safeTransfer(to_address, total);
		}
	}

	function receiveMoneyInClaim(uint stake, uint paid_amount) internal override {
		receiveStakeAsset(stake + paid_amount);
	}

	function sendToClaimRecipient(address payable to_address, uint paid_amount) internal override {
		if (settings.tokenAddress == address(0)) {
			to_address.transfer(paid_amount);
		}
		else {
			IERC20(settings.tokenAddress).safeTransfer(to_address, paid_amount);
		}
	}

}