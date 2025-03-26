// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./lib/OracleLibrary.sol";


contract UniswapV3Helper {
    address public immutable uniswapV3Factory;

    bytes4 public constant SYMBOL_SELECTOR = bytes4(keccak256("symbol()"));
    bytes4 public constant DECIMALS_SELECTOR = bytes4(keccak256("decimals()"));
    bytes4 public constant GET_POOL_SELECTOR = bytes4(keccak256("getPool(address,address,uint24)"));

    struct PriceData {
        address tokenA;
        address tokenB;
        uint24 fee;
    }

    struct Price {
        uint256 price;
        bool success;
    }

    constructor(address _factory) public {
        bytes4 selector = bytes4(keccak256("feeAmountTickSpacing(uint24)"));
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _factory.staticcall(abi.encode(selector, 500));
        require(success, "UniswapV3Oracle: invalid factory");

        uniswapV3Factory = _factory;
    }

    function tokensSymbols(address[] memory _tokens) external view returns (string[] memory symbols) {
        uint256 n = _tokens.length;
        symbols = new string[](n);

        for (uint256 i = 0; i < n; i++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory data) = _tokens[i].staticcall(abi.encode(SYMBOL_SELECTOR));

            symbols[i] = success
                ? data.length == 32 ? string(abi.encodePacked(data)) : abi.decode(data, (string))
                : "";
        }
    }

    function getPrices(
        PriceData[] calldata _data,
        uint32 _periodForAvgPrice
    )
        external
        view
        returns (Price[] memory prices, uint256 timestamp)
    {
        timestamp = block.timestamp;
        uint256 n = _data.length;
        prices = new Price[](n);

        for (uint256 i = 0; i < n; i++) {
            (
                prices[i].success,
                prices[i].price
            ) = getPrice(_data[i].tokenA, _data[i].tokenB, _data[i].fee, _periodForAvgPrice);
        }
    }

    /// @param _tokenA address
    /// @param _tokenB address
    /// @param _fee fee, based on which we can resolve a pool
    /// @param _periodForAvgPrice Number of seconds in the past to start calculating time-weighted average
    ///         in our case it might be the best, to set it to the Chain.padding
    function getPrice(
        address _tokenA,
        address _tokenB,
        uint24 _fee,
        uint32 _periodForAvgPrice
    ) public view returns (bool success, uint256 price) {
        address pool = resolvePool(_tokenA, _tokenB, _fee);
        if (pool == address(0)) return (false, 0);

        int24 arithmeticMeanTick;
        (success, arithmeticMeanTick, ) = OracleLibrary.consult(pool, _periodForAvgPrice);
        if (!success) return (false, 0);

        bytes memory data;

        // solhint-disable-next-line avoid-low-level-calls
        (success, data) = _tokenA.staticcall(abi.encode(DECIMALS_SELECTOR));
        if (!success) return (false, 0);

        uint256 decimals = abi.decode(data, (uint256));
        uint256 baseAmountA = 10 ** decimals;

        if (_tokenA == _tokenB) return (true, baseAmountA);

        price = OracleLibrary.getQuoteAtTick(arithmeticMeanTick, uint128(baseAmountA), _tokenA, _tokenB);
    }

    function resolvePool(address _tokenA, address _tokenB, uint24 _fee) public view returns (address pool) {
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);

        (bool success, bytes memory data) =
            // solhint-disable-next-line avoid-low-level-calls
            uniswapV3Factory.staticcall(abi.encodeWithSelector(GET_POOL_SELECTOR, token0, token1, _fee));

        return success ? abi.decode(data, (address)) : address(0);
    }
}