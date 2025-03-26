pragma solidity 0.6.6;

interface IGovBridge {
  function deposit(
    address token,
    uint256 amountOrId,
    address receiver
  ) external;
}