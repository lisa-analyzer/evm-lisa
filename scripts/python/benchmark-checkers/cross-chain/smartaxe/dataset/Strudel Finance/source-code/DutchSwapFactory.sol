pragma solidity 0.6.6;

//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//::::::::::: @#::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::::::::: ##::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::::::::: ##::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::: ########: ##:: jU* DUTCh>: ihD%Ky: #@Whdqy:::::::::::::::::::::
//::: ###... ###: ##:: #@j: @B... @@7...t: N@N.. R@K:::::::::::::::::::
//::: ##::::: ##: ##::.Q@t: @Q::: @Q.::::: N@j:: z@Q:::::::::::::::::::
//:::: ##DuTCH##: %@QQ@@S`: hQQQh <R@QN@Q* N@j:: z@Q:::::::::::::::::::
//::::::.......: =Q@y....:::....:::......::...:::...:::::::::::::::::::
//:::::::::::::: h@W? sWAP@! 'DW;::::::.KK. ydSWAP@t: NNKNQBdt:::::::::
//:::::::::::::: 'zqRqj*. L@R h@w: QQ: L@5 Q@z.. d@@: @@U... @Q::::::::
//:::::::::::::::::...... Q@^ ^@@N@wt@BQ@ <@Q^::: @@: @@}::: @@::::::::
//:::::::::::::::::: U@@QKt... D@@L...B@Q.. KDUTCH@Q: @@QQ#QQq:::::::::
//:::::::::::::::::::.....::::::...:::...::::.......: @@!.....:::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::: @@!::::::::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::: @@!::::::::::::::
//::::::::::::::01101100:01101111:01101111:01101011::::::::::::::::::::
//:::::01100100:01100101:01100101:01110000:01111001:01110010:::::::::::
//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//
// DutchSwap Factory
//
// Authors:
// * Adrian Guerrera / Deepyr Pty Ltd
//
// Appropriated from BokkyPooBah's Fixed Supply Token 👊 Factory
// https://www.ethervendingmachine.io
// Thanks Bokky!
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./CloneFactory.sol";
import "./IDutchAuction.sol";

contract DutchSwapFactory is OwnableUpgradeSafe, CloneFactory {
  using SafeMath for uint256;

  address public dutchAuctionTemplate;

  struct Auction {
    bool exists;
    uint256 index;
  }

  address public newAddress;
  uint256 public minimumFee = 0 ether;
  mapping(address => Auction) public isChildAuction;
  address[] public auctions;

  event DutchAuctionDeployed(
    address indexed owner,
    address indexed addr,
    address dutchAuction,
    uint256 fee
  );
  event CustomAuctionDeployed(address indexed owner, address indexed addr);

  event AuctionRemoved(address dutchAuction, uint256 index);
  event FactoryDeprecated(address newAddress);
  event MinimumFeeUpdated(uint256 oldFee, uint256 newFee);
  event AuctionTemplateUpdated(address oldDutchAuction, address newDutchAuction);

  function initDutchSwapFactory(address _dutchAuctionTemplate, uint256 _minimumFee) public {
    __Ownable_init();
    dutchAuctionTemplate = _dutchAuctionTemplate;
    minimumFee = _minimumFee;
  }

  function numberOfAuctions() public view returns (uint256) {
    return auctions.length;
  }

  function addCustomAuction(address _auction) public onlyOwner {
    require(!isChildAuction[_auction].exists);
    bool finalised = IDutchAuction(_auction).auctionEnded();
    require(!finalised);
    isChildAuction[address(_auction)] = Auction(true, auctions.length - 1);
    auctions.push(address(_auction));
    emit CustomAuctionDeployed(msg.sender, address(_auction));
  }

  function removeFinalisedAuction(address _auction) public {
    require(isChildAuction[_auction].exists);
    bool finalised = IDutchAuction(_auction).auctionEnded();
    require(finalised);
    uint256 removeIndex = isChildAuction[_auction].index;
    emit AuctionRemoved(_auction, auctions.length - 1);
    uint256 lastIndex = auctions.length - 1;
    address lastIndexAddress = auctions[lastIndex];
    auctions[removeIndex] = lastIndexAddress;
    isChildAuction[lastIndexAddress].index = removeIndex;
    if (auctions.length > 0) {
      auctions.pop();
    }
  }

  function deprecateFactory(address _newAddress) public onlyOwner {
    require(newAddress == address(0));
    emit FactoryDeprecated(_newAddress);
    newAddress = _newAddress;
  }

  function setMinimumFee(uint256 _minimumFee) public onlyOwner {
    emit MinimumFeeUpdated(minimumFee, _minimumFee);
    minimumFee = _minimumFee;
  }

  function setDutchAuctionTemplate(address _dutchAuctionTemplate) public onlyOwner {
    emit AuctionTemplateUpdated(dutchAuctionTemplate, _dutchAuctionTemplate);
    dutchAuctionTemplate = _dutchAuctionTemplate;
  }

  function deployDutchAuction(
    address _token,
    uint256 _tokenSupply,
    uint256 _startDate,
    uint256 _endDate,
    address _paymentCurrency,
    uint256 _startPrice,
    uint256 _minimumPrice,
    address payable _wallet
  ) public payable returns (address dutchAuction) {
    dutchAuction = createClone(dutchAuctionTemplate);
    isChildAuction[address(dutchAuction)] = Auction(true, auctions.length - 1);
    auctions.push(address(dutchAuction));
    require(IERC20(_token).transferFrom(msg.sender, address(this), _tokenSupply));
    require(IERC20(_token).approve(dutchAuction, _tokenSupply));
    IDutchAuction(dutchAuction).initDutchAuction(
      address(this),
      _token,
      _tokenSupply,
      _startDate,
      _endDate,
      _paymentCurrency,
      _startPrice,
      _minimumPrice,
      _wallet
    );
    emit DutchAuctionDeployed(msg.sender, address(dutchAuction), dutchAuctionTemplate, msg.value);
  }

  // footer functions
  function transferAnyERC20Token(address tokenAddress, uint256 tokens)
    public
    onlyOwner
    returns (bool success)
  {
    return IERC20(tokenAddress).transfer(owner(), tokens);
  }

  receive() external payable {
    revert();
  }
}