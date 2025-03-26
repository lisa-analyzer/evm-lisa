pragma solidity 0.6.6;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

interface IDutchAuction {
  function initDutchAuction(
    address _funder,
    address _token,
    uint256 _tokenSupply,
    uint256 _startDate,
    uint256 _endDate,
    address _paymentCurrency,
    uint256 _startPrice,
    uint256 _minimumPrice,
    address payable _wallet
  ) external;

  function auctionEnded() external view returns (bool);

  function tokensClaimed(address user) external view returns (uint256);

  function tokenSupply() external view returns (uint256);

  function wallet() external view returns (address);

  function minimumPrice() external view returns (uint256);

  function clearingPrice() external view returns (uint256);

  function auctionToken() external view returns (address);

  function endDate() external view returns (uint256);

  function finaliseAuction() external;

  function paymentCurrency() external view returns (address);
}