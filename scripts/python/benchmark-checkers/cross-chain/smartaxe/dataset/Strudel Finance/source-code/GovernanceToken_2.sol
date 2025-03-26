// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "./erc20/ITokenRecipient.sol";
import "./StrudelToken.sol";
import "./IGovBridge.sol";

/// @title  Strudel Governance Token.
/// @notice This is an ERC20 contract that mints by locking another token.
contract GovernanceToken is ERC20UpgradeSafe, OwnableUpgradeSafe {
  using SafeMath for uint256;

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32
    public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint256) public nonces;

  StrudelToken private strudel;
  uint256 public intervalLength;
  IGovBridge public bridge;
  mapping(address => uint256) private lockData;

  function initialize(
    address _strudelAddr,
    address _bridgeAddr,
    uint256 _intervalLength
  ) external initializer {
    __ERC20_init("Strudel Governance Token", "g$TRDL");
    __Ownable_init();
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("g$TRDL")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
    require(_strudelAddr != address(0), "zero strudel");
    strudel = StrudelToken(_strudelAddr);
    require(_bridgeAddr != address(0), "zero bridge");
    bridge = IGovBridge(_bridgeAddr);
    _approve(address(this), _bridgeAddr, uint256(-1));
    require(_intervalLength > 0, "zero interval");
    intervalLength = _intervalLength;
  }

  function _parse(uint256 lockData)
    internal
    pure
    returns (
      uint256 endBlock,
      uint256 locked,
      uint256 minted
    )
  {
    endBlock = lockData >> 224;
    locked = uint256(uint112(lockData >> 112));
    minted = uint256(uint112(lockData));
  }

  function _compact(
    uint256 endBlock,
    uint256 locked,
    uint256 minted
  ) internal pure returns (uint256 lockData) {
    lockData = (endBlock << 224) | (locked << 112) | minted;
  }

  function getLock(address owner)
    external
    view
    returns (
      uint256 endBlock,
      uint256 lockTotal,
      uint256 mintTotal
    )
  {
    (endBlock, lockTotal, mintTotal) = _parse(lockData[owner]);
  }

  function _lock(
    address owner,
    address recipient,
    uint256 amount,
    uint256 lockDuration
  ) internal returns (uint256 mintAmount) {
    require(owner != address(0), "owner 0");
    require(recipient != address(0), "recipient 0");
    require(amount >= 1e15, "small deposit");
    require(lockDuration >= intervalLength, "lock too short");
    uint256 maxInterval = intervalLength * 52;
    require(lockDuration <= maxInterval, "lock too long");
    strudel.transferFrom(_msgSender(), address(this), amount);

    mintAmount = maxInterval.mul(2).sub(lockDuration).mul(lockDuration).mul(amount).div(
      maxInterval.mul(maxInterval)
    );

    uint256 endBlock;
    uint256 lockTotal;
    uint256 mintTotal;
    (endBlock, lockTotal, mintTotal) = _parse(lockData[owner]);

    // return previous lock, if matured
    if (lockTotal > 0 && block.number >= endBlock) {
      unlock();
      endBlock = block.number;
      lockTotal = 0;
      mintTotal = 0;
    }

    uint256 remainingLock = endBlock - block.number;
    // TODO: arithmetic mean here is not apropriate. should follow mintAmount formula
    uint256 averageDuration = remainingLock.mul(lockTotal).add(amount.mul(lockDuration)).div(
      amount.add(lockTotal)
    );

    lockData[owner] = _compact(
      block.number + averageDuration,
      lockTotal + amount,
      mintAmount + mintTotal
    );

    _mint(recipient, mintAmount);
  }

  function lock(
    address recipient,
    uint256 amount,
    uint256 blocks,
    bool deposit
  ) public returns (bool) {
    if (deposit) {
      uint256 mintAmount = _lock(recipient, address(this), amount, blocks);
      bridge.deposit(address(this), mintAmount, recipient);
    } else {
      _lock(recipient, recipient, amount, blocks);
    }
    return true;
  }

  function lockWithPermit(
    uint256 value,
    uint256 blocks,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bool deposit
  ) external returns (bool) {
    strudel.permit(_msgSender(), address(this), value, deadline, v, r, s);
    return lock(_msgSender(), value, blocks, deposit);
  }

  function unlock() public returns (bool) {
    uint256 endBlock;
    uint256 locked;
    uint256 minted;
    (endBlock, locked, minted) = _parse(lockData[_msgSender()]);
    require(locked > 0, "nothing to unlock");
    require(endBlock <= block.number, "lock has not passed yet");
    lockData[_msgSender()] = 0;
    _burn(_msgSender(), minted);
    strudel.transfer(_msgSender(), locked);
  }

  /// @notice           Set allowance for other address and notify.
  ///                   Allows `_spender` to spend no more than `_value`
  ///                   tokens on your behalf and then ping the contract about
  ///                   it.
  /// @dev              The `_spender` should implement the `ITokenRecipient`
  ///                   interface to receive approval notifications.
  /// @param _spender   Address of contract authorized to spend.
  /// @param _value     The max amount they can spend.
  /// @param _extraData Extra information to send to the approved contract.
  /// @return true if the `_spender` was successfully approved and acted on
  ///         the approval, false (or revert) otherwise.
  function approveAndCall(
    ITokenRecipient _spender,
    uint256 _value,
    bytes calldata _extraData
  ) external returns (bool) {
    // not external to allow bytes memory parameters
    if (approve(address(_spender), _value)) {
      _spender.receiveApproval(_msgSender(), _value, address(this), _extraData);
      return true;
    }
    return false;
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(deadline >= block.timestamp, "Strudel Gov: EXPIRED");
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
      )
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(
      recoveredAddress != address(0) && recoveredAddress == owner,
      "Strudel Gov: INVALID_SIGNATURE"
    );
    _approve(owner, spender, value);
  }

  function updateBridge(address _bridgeAddr) external onlyOwner {
    require(_bridgeAddr != address(0), "zero bridge");
    _approve(address(this), _bridgeAddr, uint256(-1));
    bridge = IGovBridge(_bridgeAddr);
  }
}