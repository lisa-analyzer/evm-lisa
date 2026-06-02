pragma solidity ^0.4.24;

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    // prettier-ignore
    function allowance(address owner, address spender) external view returns (uint);

    // prettier-ignore
    function transferFrom(address from, address to, uint value) external returns (bool);

    // prettier-ignore
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
