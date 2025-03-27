pragma solidity 0.6.6;

interface IDutchSwapFactory {
  function deployDutchAuction(
    address _token,
    uint256 _tokenSupply,
    uint256 _startDate,
    uint256 _endDate,
    address _paymentCurrency,
    uint256 _startPrice,
    uint256 _minimumPrice,
    address _wallet
  ) external returns (address dutchAuction);
}