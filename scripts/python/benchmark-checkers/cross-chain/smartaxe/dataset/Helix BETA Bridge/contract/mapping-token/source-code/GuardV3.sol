// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.17;

import "@zeppelin-solidity/contracts/security/Pausable.sol";
import "@zeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "@zeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./GuardRegistryV3.sol";
import "../interfaces/IWToken.sol";

contract GuardV3 is GuardRegistryV3, Pausable {
    using SafeMath for uint256;

    mapping(uint256 => bytes32) public deposits;

    uint256 public maxUnclaimableTime;
    mapping(address => bool) public depositors;
    address public operator;

    event TokenDeposit(address sender, uint256 id, uint256 timestamp, address token, address recipient, uint256 amount);
    event TokenClaimed(uint256 id);

    constructor(address[] memory _guards, uint256 _threshold, uint256 _maxUnclaimableTime) {
        maxUnclaimableTime = _maxUnclaimableTime;
        operator = msg.sender;
        initialize(_guards, _threshold);
    }

    modifier onlyDepositor() {
        require(depositors[msg.sender] == true, "Guard: Invalid depositor");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Guard: Invalid operator");
        _;
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function pause() external onlyOperator {
        _pause();
    }

    function setOperator(address newOperator, bytes[] memory signatures) external {
        verifyGuardSignatures(msg.sig, abi.encode(newOperator), signatures);
        operator = newOperator;
    }

    function setDepositor(address depositor, bool enable) external onlyOperator {
        depositors[depositor] = enable;
    }

    function setMaxUnclaimableTime(uint256 _maxUnclaimableTime) external onlyOperator {
        maxUnclaimableTime = _maxUnclaimableTime;
    }

    /**
      * @dev deposit token to guard, waiting to claim, only allowed depositor
      * @param id the id of the operation, should be siged later by guards
      * @param token the erc20 token address
      * @param recipient the recipient of the token
      * @param amount the amount of the token
      */
    function deposit(
        uint256 id,
        address token,
        address recipient,
        uint256 amount
    ) public onlyDepositor whenNotPaused {
        deposits[id] = hash(abi.encodePacked(msg.sender, block.timestamp, token, recipient, amount));
        emit TokenDeposit(msg.sender, id, block.timestamp, token, recipient, amount);
    }

    function claimById(
        address from,
        uint256 id,
        uint256 timestamp,
        address token,
        address recipient,
        uint256 amount,
        bool isNative
    ) internal {
        require(hash(abi.encodePacked(from, timestamp, token, recipient, amount)) == deposits[id], "Guard: Invalid id to claim");
        require(amount > 0, "Guard: Invalid amount to claim");
        delete deposits[id];
        if (isNative) {
            require(IERC20(token).transferFrom(from, address(this), amount), "Guard: claim native token failed");
            uint256 balanceBefore = address(this).balance;
            IWToken(token).withdraw(amount);
            require(address(this).balance == balanceBefore.add(amount), "Guard: token is not wrapped by native token");
            payable(recipient).transfer(amount);
        } else {
            require(IERC20(token).transferFrom(from, recipient, amount), "Guard: claim token failed");
        }
        emit TokenClaimed(id);
    }

    /**
      * @dev claim the tokens in the contract saved by deposit, this acquire signatures from guards
      * @param id the id to be claimed
      * @param signatures the signatures of the guards which to claim tokens.
      */
    function claim(
        address from,
        uint256 id,
        uint256 timestamp,
        address token,
        address recipient,
        uint256 amount,
        bytes[] memory signatures
    ) public {
        verifyGuardSignaturesWithoutNonce(msg.sig, abi.encode(from, id, timestamp, token, recipient, amount), signatures);
        claimById(from, id, timestamp, token, recipient, amount, false);
    }

    /**
      * @dev claimNative the tokens in the contract saved by deposit, this acquire signatures from guards
      * @param id the id to be claimed
      * @param signatures the signatures of the guards which to claim tokens.
      */
    function claimNative(
        address from,
        uint256 id,
        uint256 timestamp,
        address token,
        address recipient,
        uint256 amount,
        bytes[] memory signatures
    ) public {
        verifyGuardSignaturesWithoutNonce(msg.sig, abi.encode(from, id, timestamp, token, recipient, amount), signatures);
        claimById(from, id, timestamp, token, recipient, amount, true);
    }

    /**
      * @dev claim the tokens without signatures, this only allowed when timeout
      * @param id the id to be claimed
      */
    function claimByTimeout(
        address from,
        uint256 id,
        uint256 timestamp,
        address token,
        address recipient,
        uint256 amount,
        bool isNative
    ) public whenNotPaused {
        require(timestamp < block.timestamp && block.timestamp - timestamp > maxUnclaimableTime, "Guard: claim at invalid time");
        claimById(from, id, timestamp, token, recipient, amount, isNative);
    }

    function hash(bytes memory value) public pure returns (bytes32) {
        return sha256(value);
    }
}

