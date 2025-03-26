// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


interface IStaking {
    function balanceOf(address _account) external view returns (uint256);
    function stakingToken() external view returns (ERC20);
}


interface ILP {
    function balanceOf(address _account) external view returns (uint256);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function totalSupply() external view returns (uint256);
}


// This contracts calculates balance of target token, that was provided as liquidity and then staked
contract UniswapV2LPTokenCounter is ERC20 {
    // token which we want to track
    ERC20 public immutable token;

    // UniV2 pool, where `token` were used as liquidity
    ILP public immutable lpPool;

    // staking contracts, where LP tokens were staked
    IStaking[] public staking;

    constructor(address _token, address _lpPool, IStaking[] memory _staking)
        ERC20("UniV2LPTokenCounter", "UniV2LPTokenCounter")
    {
        token = ERC20(_token);
        lpPool = ILP(_lpPool);
        staking = _staking;
    }

    function totalSupply() public view override returns (uint256) {
        return token.totalSupply();
    }

    function balanceOf(address _account) public view override returns (uint256 total) {
        uint256 lpBalance = _lpBalanceOf(_account);
        uint256 lpShare = lpBalance * 1e18 / lpPool.totalSupply();

        (uint112 reserve0, uint112 reserve1, ) = lpPool.getReserves();
        bool isToken0 = lpPool.token0() == address(token);
        uint256 tokenReserves = isToken0 ? reserve0 : reserve1;

        return lpShare * tokenReserves / 1e18;
    }

    function _lpBalanceOf(address _account) internal view returns (uint256 lpBalance) {
        uint256 count = staking.length;

        lpBalance = lpPool.balanceOf(_account);

        for (uint256 i; i < count; i++) {
            lpBalance += staking[i].balanceOf(_account);
        }
    }

    function _beforeTokenTransfer(address, address, uint256) internal pure override {
        revert("Non-transferable");
    }
}