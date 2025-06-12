// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IERC20 {
  function approve(address _spender, uint256 _value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address _who) external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function mint(address _to, uint256 _value) external;
  function burn(address _from, uint256 _value) external;
  function decimals() external view returns(uint8);
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IMappingToken {
    function initialize(string memory name, string memory symbol, uint8 decimal) external;
}
