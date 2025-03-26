pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "./mocks/MockERC20.sol";
import "./GovernanceToken.sol";
import "./dutchSwap/IDutchAuction.sol";
import "./dutchSwap/IDutchSwapFactory.sol";
import "./IPriceOracle.sol";

contract AuctionManager is OwnableUpgradeSafe, ERC20UpgradeSafe {
  using SafeMath for uint256;

  // used as factor when dealing with %
  uint256 constant ACCURACY = 1e4;
  // when 95% at market price, start selling
  uint256 public sellThreshold;
  // cap auctions at certain amount of $TRDL minted
  uint256 public dilutionBound;
  // stop selling when volume small
  // uint256 public dustThreshold; set at dilutionBound / 52
  // % start_price above estimate, and % min_price below estimate
  uint256 public priceSpan;
  // auction duration
  uint256 public auctionDuration;

  MockERC20 private strudel;
  IERC20 private vBtc;
  GovernanceToken private gStrudel;
  IPriceOracle private btcPriceOracle;
  IPriceOracle private vBtcPriceOracle;
  IPriceOracle private strudelPriceOracle;
  IDutchSwapFactory private auctionFactory;
  uint256 private govIntervalLength;

  IDutchAuction public currentAuction;
  mapping(address => uint256) public lockTimeForAuction;

  constructor(
    address _strudelAddr,
    address _gStrudel,
    address _vBtcAddr,
    address _btcPriceOracle,
    address _vBtcPriceOracle,
    address _strudelPriceOracle,
    address _auctionFactory
  ) public {
    __Ownable_init();
    __ERC20_init("Strudel Auction Token", "a$TRDL");
    strudel = MockERC20(_strudelAddr);
    gStrudel = GovernanceToken(_gStrudel);
    govIntervalLength = gStrudel.intervalLength();
    vBtc = IERC20(_vBtcAddr);
    btcPriceOracle = IPriceOracle(_btcPriceOracle);
    vBtcPriceOracle = IPriceOracle(_vBtcPriceOracle);
    strudelPriceOracle = IPriceOracle(_strudelPriceOracle);
    auctionFactory = IDutchSwapFactory(_auctionFactory);
    sellThreshold = 9500; // vBTC @ 95% of BTC price or above
    dilutionBound = 70; // 0.7% of $TRDL total supply
    priceSpan = 2500; // 25%
    auctionDuration = 84600; // ~23,5h
  }

  function _getDiff(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a > b) {
      return a - b;
    }
    return b - a;
  }

  function rotateAuctions() external {
    if (address(currentAuction) != address(0)) {
      require(currentAuction.auctionEnded(), "previous auction hasn't ended");
      try currentAuction.finaliseAuction() {
        // do nothing
      } catch Error(string memory) {
        // do nothing
      } catch (bytes memory) {
        // do nothing
      }
      uint256 studelReserves = strudel.balanceOf(address(this));
      if (studelReserves > 0) {
        strudel.burn(studelReserves);
      }
    }

    // get prices
    uint256 btcPriceInEth = btcPriceOracle.consult(1e18);
    uint256 vBtcPriceInEth = vBtcPriceOracle.consult(1e18);
    uint256 strudelPriceInEth = strudelPriceOracle.consult(1e18);

    // measure outstanding supply
    uint256 vBtcOutstandingSupply = vBtc.totalSupply();
    uint256 strudelSupply = strudel.totalSupply();
    uint256 vBtcAmount = vBtc.balanceOf(address(this));
    vBtcOutstandingSupply -= vBtcAmount;

    // calculate vBTC supply imbalance in ETH
    uint256 imbalance = _getDiff(btcPriceInEth, vBtcPriceInEth).mul(vBtcOutstandingSupply);

    uint256 cap = strudelSupply.mul(dilutionBound).mul(strudelPriceInEth).div(ACCURACY);
    // cap by dillution bound
    imbalance = Math.min(cap, imbalance);

    // pause if imbalance below dust threshold
    if (imbalance.div(strudelPriceInEth) < strudelSupply.mul(dilutionBound).div(52).div(ACCURACY)) {
      // pause auctions
      currentAuction = IDutchAuction(address(0));
      return;
    }

    // determine what kind of auction we want
    uint256 priceRelation = btcPriceInEth.mul(ACCURACY).div(vBtcPriceInEth);
    if (priceRelation < ACCURACY.mul(ACCURACY).div(sellThreshold)) {
      // cap vBtcAmount by imbalance in vBTC
      vBtcAmount = Math.min(vBtcAmount, imbalance.div(vBtcPriceInEth));
      // calculate vBTC price
      imbalance = vBtcPriceInEth.mul(1e18).div(strudelPriceInEth);
      // auction off some vBTC
      vBtc.approve(address(auctionFactory), vBtcAmount);
      currentAuction = IDutchAuction(
        auctionFactory.deployDutchAuction(
          address(vBtc),
          vBtcAmount,
          now,
          now + auctionDuration,
          address(strudel),
          imbalance.mul(ACCURACY.add(priceSpan)).div(ACCURACY), // startPrice
          imbalance.mul(ACCURACY.sub(priceSpan)).div(ACCURACY), // minPrice
          address(this)
        )
      );
    } else {
      // calculate price in vBTC
      vBtcAmount = strudelPriceInEth.mul(1e18).div(vBtcPriceInEth);
      // auction off some $TRDL
      currentAuction = IDutchAuction(
        auctionFactory.deployDutchAuction(
          address(this),
          imbalance.div(strudelPriceInEth), // calculate imbalance in $TRDL
          now,
          now + auctionDuration,
          address(vBtc),
          vBtcAmount.mul(ACCURACY.add(priceSpan)).div(ACCURACY), // startPrice
          vBtcAmount.mul(ACCURACY.sub(priceSpan)).div(ACCURACY), // minPrice
          address(this)
        )
      );

      // if imbalance >= dillution bound, use max lock (52 weeks)
      // if imbalance < dillution bound, lock shorter
      lockTimeForAuction[address(currentAuction)] = govIntervalLength.mul(52).mul(imbalance).div(
        cap
      );
    }
  }

  function setSellThreshold(uint256 _threshold) external onlyOwner {
    require(_threshold >= 6000, "threshold below 60% minimum");
    require(_threshold <= 12000, "threshold above 120% maximum");
    sellThreshold = _threshold;
  }

  function setDulutionBound(uint256 _dilutionBound) external onlyOwner {
    require(_dilutionBound <= 1000, "dilution bound above 10% max value");
    dilutionBound = _dilutionBound;
  }

  function setPriceSpan(uint256 _priceSpan) external onlyOwner {
    require(_priceSpan > 1000, "price span should have at least 10%");
    require(_priceSpan < ACCURACY, "price span larger accuracy");
    priceSpan = _priceSpan;
  }

  function setAuctionDuration(uint256 _auctionDuration) external onlyOwner {
    require(_auctionDuration >= 3600, "auctions should run at laest for 1 hour");
    require(_auctionDuration <= 604800, "auction duration should be less than week");
    auctionDuration = _auctionDuration;
  }

  function renounceMinter() external onlyOwner {
    strudel.renounceMinter();
  }

  function swipe(address tokenAddr) external onlyOwner {
    IERC20 token = IERC20(tokenAddr);
    token.transfer(owner(), token.balanceOf(address(this)));
  }

  // In deployDutchAuction, approve and transferFrom are called
  // In initDutchAuction, transferFrom is called again
  // In DutchAuction, transfer is called to either payout, or return money to AuctionManager

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public override returns (bool success) {
    return true;
  }

  function approve(address _spender, uint256 _value) public override returns (bool success) {
    return true;
  }

  function transfer(address to, uint256 amount) public override returns (bool success) {
    // require sender is our Auction
    address auction = _msgSender();
    require(lockTimeForAuction[auction] > 0, "Caller is not our auction");

    // if recipient is AuctionManager, it means we are doing a refund -> do nothing
    if (to == address(this)) return true;

    uint256 blocks = lockTimeForAuction[auction];
    strudel.mint(address(this), amount);
    strudel.approve(address(gStrudel), amount);
    gStrudel.lock(to, amount, blocks, false);
    return true;
  }
}