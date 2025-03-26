// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import {TypedMemView} from "./summa-tx/TypedMemView.sol";
import {ViewBTC} from "./summa-tx/ViewBTC.sol";
import {ViewSPV} from "./summa-tx/ViewSPV.sol";
import "./summa-tx/IRelay.sol";

interface IERC20 {
  function mint(address account, uint256 amount) external returns (bool);

  function transfer(address account, uint256 amount) external returns (bool);
}

/// @title  VBTC Token.
/// @notice This is the VBTC ERC20 contract.
contract BchBridge is OwnableUpgradeSafe {
  using SafeMath for uint256;
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using ViewBTC for bytes29;
  using ViewSPV for bytes29;

  event Crossing(
    bytes32 indexed btcTxHash,
    address indexed receiver,
    uint256 amount,
    uint32 outputIndex
  );

  uint8 constant ADDR_LEN = 20;
  uint256 constant BCH_CAP = 21 * 10**24;
  uint256 constant BCH_CAP_SQRT = 4582575700000; // sqrt(BCH_CAP)
  bytes3 constant PROTOCOL_ID = 0x07ffff; // a mersenne prime

  // immutable
  IERC20 private strudel;
  IERC20 private bch;

  // gov params
  IRelay public relay;
  uint256 public numConfs;
  uint256 public mintedSupply;

  // working memory
  // marking all sucessfully processed outputs
  mapping(bytes32 => bool) public knownOutpoints;

  constructor(
    address _relay,
    address _strudel,
    address _bch,
    uint256 _minConfs
  ) public {
    __Ownable_init();
    relay = IRelay(_relay);
    strudel = IERC20(_strudel);
    bch = IERC20(_bch);
    numConfs = _minConfs;
  }

  function makeCompressedOutpoint(bytes32 _txid, uint32 _index) internal pure returns (bytes32) {
    // sacrifice 4 bytes instead of hashing
    return ((_txid >> 32) << 32) | bytes32(uint256(_index));
  }

  /// @notice             Verifies inclusion of a tx in a header, and that header in the Relay chain
  /// @dev                Specifically we check that both the best tip and the heaviest common header confirm it
  /// @param  _header     The header containing the merkleroot committing to the tx
  /// @param  _proof      The merkle proof intermediate nodes
  /// @param  _index      The index of the tx in the merkle tree's leaves
  /// @param  _txid       The txid that is the proof leaf
  function _checkInclusion(
    bytes29 _header, // Header
    bytes29 _proof, // MerkleArray
    uint256 _index,
    bytes32 _txid
  ) internal view returns (bool) {
    // check the txn is included in the header
    require(ViewSPV.prove(_txid, _header.merkleRoot(), _proof, _index), "Bad inclusion proof");

    // check the header is included in the chain
    bytes32 headerHash = _header.hash256();
    bytes32 GCD = relay.getLastReorgCommonAncestor();
    require(relay.isAncestor(headerHash, GCD, 2500), "GCD does not confirm header");

    // check offset to tip
    bytes32 bestKnownDigest = relay.getBestKnownDigest();
    uint256 height = relay.findHeight(headerHash);
    require(height > 0, "height not found in relay");
    uint256 offset = relay.findHeight(bestKnownDigest).sub(height);
    require(offset >= numConfs, "Insufficient confirmations");

    return true;
  }

  /// @dev             Mints an amount of the token and assigns it to an account.
  ///                  Uses the internal _mint function.
  /// @param _header   header
  /// @param _proof    proof
  /// @param _version  version
  /// @param _locktime locktime
  /// @param _index    tx index in block
  /// @param _crossingOutputIndex    output index that
  /// @param _vin      vin
  /// @param _vout     vout
  function proofOpReturnAndMint(
    bytes calldata _header,
    bytes calldata _proof,
    bytes4 _version,
    bytes4 _locktime,
    uint256 _index,
    uint32 _crossingOutputIndex,
    bytes calldata _vin,
    bytes calldata _vout
  ) external returns (bool) {
    return
      _provideProof(
        _header,
        _proof,
        _version,
        _locktime,
        _index,
        _crossingOutputIndex,
        _vin,
        _vout
      );
  }

  function _provideProof(
    bytes memory _header,
    bytes memory _proof,
    bytes4 _version,
    bytes4 _locktime,
    uint256 _index,
    uint32 _crossingOutputIndex,
    bytes memory _vin,
    bytes memory _vout
  ) internal returns (bool) {
    bytes32 txId = abi.encodePacked(_version, _vin, _vout, _locktime).ref(0).hash256();
    bytes32 outpoint = makeCompressedOutpoint(txId, _crossingOutputIndex);
    require(!knownOutpoints[outpoint], "already processed outputs");

    _checkInclusion(
      _header.ref(0).tryAsHeader().assertValid(),
      _proof.ref(0).tryAsMerkleArray().assertValid(),
      _index,
      txId
    );

    // mark processed
    knownOutpoints[outpoint] = true;

    // do payouts
    address account;
    uint256 amount;
    (account, amount) = doPayouts(_vout.ref(0).tryAsVout(), _crossingOutputIndex);
    emit Crossing(txId, account, amount, _crossingOutputIndex);
    return true;
  }

  function doPayouts(bytes29 _vout, uint32 _crossingOutputIndex)
    internal
    returns (address account, uint256 amount)
  {
    bytes29 output = _vout.indexVout(_crossingOutputIndex);

    // extract receiver and address
    amount = output.value() * 10**10; // wei / satosh = 10^18 / 10^8 = 10^10
    require(amount > 0, "output has 0 value");

    bytes29 opReturnPayload = output.scriptPubkey().opReturnPayload();
    require(opReturnPayload.len() == ADDR_LEN + 3, "invalid op-return payload length");
    require(bytes3(opReturnPayload.index(0, 3)) == PROTOCOL_ID, "invalid protocol id");
    account = address(bytes20(opReturnPayload.index(3, ADDR_LEN)));

    uint256 sqrtVbtcBefore = Babylonian.sqrt(mintedSupply);
    bch.mint(account, amount);
    mintedSupply = mintedSupply.add(amount);
    //bch.transfer(account, amount);
    uint256 sqrtVbtcAfter = Babylonian.sqrt(mintedSupply);

    // calculate the reward as area h(x) = f(x) - g(x), where f(x) = x^2 and g(x) = |minted|
    // pay out only the delta to the previous claim: H(after) - H(before)
    // this caps all minting rewards to 2/3 of BCH_CAP
    uint256 rewardAmount =
      BCH_CAP
        .mul(3)
        .mul(sqrtVbtcAfter)
        .add(sqrtVbtcBefore**3)
        .sub(BCH_CAP.mul(3).mul(sqrtVbtcBefore))
        .sub(sqrtVbtcAfter**3)
        .div(3)
        .div(BCH_CAP_SQRT);
    strudel.mint(account, rewardAmount);
  }

  function setRelayAddress(address _newRelayAddr) external onlyOwner {
    require(_newRelayAddr != address(0), "!newRelayAddr-0");
    relay = IRelay(_newRelayAddr);
  }

  function setNumConfs(uint256 _numConfs) external onlyOwner {
    require(_numConfs > 0, "!newNumConfs-0");
    require(_numConfs < 100, "!newNumConfs-useless");
    numConfs = _numConfs;
  }
}