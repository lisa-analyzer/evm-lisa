// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice Registry for Curve Pools with Utility functions.

pragma solidity ^0.5.7;

import "../oz/ownership/Ownable.sol";
import "../oz/token/ERC20/SafeERC20.sol";

interface ICurveAddressProvider {
    function get_registry() external view returns (address);

    function get_address(uint256 _id) external view returns (address);
}

interface ICurveRegistry {
    function get_pool_from_lp_token(address lpToken)
        external
        view
        returns (address);

    function get_lp_token(address swapAddress) external view returns (address);

    function get_n_coins(address _pool)
        external
        view
        returns (uint256[2] memory);

    function get_coins(address _pool) external view returns (address[8] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);
}

interface ICurveFactoryRegistry {
    function get_n_coins(address _pool)
        external
        view
        returns (uint256, uint256);

    function get_coins(address _pool) external view returns (address[2] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);
}

contract Curve_Registry_V2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ICurveAddressProvider private constant CurveAddressProvider =
        ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);
    ICurveRegistry public CurveRegistry;

    ICurveFactoryRegistry public FactoryRegistry;

    address private constant wbtcToken =
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant sbtcCrvToken =
        0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
    address internal constant ETHAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address => bool) public shouldAddUnderlying;
    mapping(address => address) private depositAddresses;

    constructor() public {
        CurveRegistry = ICurveRegistry(CurveAddressProvider.get_registry());
        FactoryRegistry = ICurveFactoryRegistry(
            CurveAddressProvider.get_address(3)
        );
    }

    function isCurvePool(address swapAddress) public view returns (bool) {
        if (CurveRegistry.get_lp_token(swapAddress) != address(0)) {
            return true;
        }
        return false;
    }

    function isFactoryPool(address swapAddress) public view returns (bool) {
        if (FactoryRegistry.get_coins(swapAddress)[0] != address(0)) {
            return true;
        }
        return false;
    }

    /**
    @notice This function is used to get the curve pool deposit address
    @notice The deposit address is used for pools with wrapped (c, y) tokens
    @param swapAddress Curve swap address for the pool
    @return curve pool deposit address or the swap address not mapped
    */
    function getDepositAddress(address swapAddress)
        external
        view
        returns (address depositAddress)
    {
        depositAddress = depositAddresses[swapAddress];
        if (depositAddress == address(0)) return swapAddress;
    }

    /**
    @notice This function is used to get the curve pool swap address
    @notice The token and swap address is the same for metapool factory pools
    @param swapAddress Curve swap address for the pool
    @return curve pool swap address or address(0) if pool doesnt exist
    */
    function getSwapAddress(address tokenAddress)
        external
        view
        returns (address swapAddress)
    {
        swapAddress = CurveRegistry.get_pool_from_lp_token(tokenAddress);
        if (swapAddress != address(0)) {
            return swapAddress;
        }
        if (isFactoryPool(swapAddress)) {
            return tokenAddress;
        }
        return address(0);
    }

    /**
    @notice This function is used to check the curve pool token address
    @notice The token and swap address is the same for metapool factory pools
    @param swapAddress Curve swap address for the pool
    @return curve pool token address or address(0) if pool doesnt exist
    */
    function getTokenAddress(address swapAddress)
        external
        view
        returns (address tokenAddress)
    {
        tokenAddress = CurveRegistry.get_lp_token(swapAddress);
        if (tokenAddress != address(0)) {
            return tokenAddress;
        }
        if (isFactoryPool(swapAddress)) {
            return swapAddress;
        }
        return address(0);
    }

    /**
    @notice Checks the number of non-underlying tokens in a pool
    @param swapAddress Curve swap address for the pool
    @return number of underlying tokens in the pool
    */
    function getNumTokens(address swapAddress) public view returns (uint256) {
        if (isCurvePool(swapAddress)) {
            return CurveRegistry.get_n_coins(swapAddress)[0];
        } else {
            (uint256 numTokens, ) = FactoryRegistry.get_n_coins(swapAddress);
            return numTokens;
        }
    }

    /**
    @notice This function is used to check if the curve pool is a metapool
    @notice all factory pools are metapools
    @param swapAddress Curve swap address for the pool
    @return true if the pool is a metapool, false otherwise
    */
    function isMetaPool(address swapAddress) public view returns (bool) {
        if (isCurvePool(swapAddress)) {
            uint256[2] memory poolTokenCounts =
                CurveRegistry.get_n_coins(swapAddress);
            if (poolTokenCounts[0] == poolTokenCounts[1]) return false;
            else return true;
        }
        if (isFactoryPool(swapAddress)) return true;
    }

    /**
    @notice This function returns an array of underlying pool token addresses
    @param swapAddress Curve swap address for the pool
    @return returns 4 element array containing the addresses of the pool tokens (0 address if pool contains < 4 tokens)
    */
    function getPoolTokens(address swapAddress)
        public
        view
        returns (address[4] memory poolTokens)
    {
        if (isMetaPool(swapAddress)) {
            if (isFactoryPool(swapAddress)) {
                address[2] memory poolUnderlyingCoins =
                    FactoryRegistry.get_coins(swapAddress);
                for (uint256 i = 0; i < 2; i++) {
                    poolTokens[i] = poolUnderlyingCoins[i];
                }
            } else {
                address[8] memory poolUnderlyingCoins =
                    CurveRegistry.get_coins(swapAddress);
                for (uint256 i = 0; i < 2; i++) {
                    poolTokens[i] = poolUnderlyingCoins[i];
                }
            }

            return poolTokens;
        } else {
            address[8] memory poolUnderlyingCoins;
            if (isBtcPool(swapAddress) && !isMetaPool(swapAddress)) {
                poolUnderlyingCoins = CurveRegistry.get_coins(swapAddress);
            } else {
                poolUnderlyingCoins = CurveRegistry.get_underlying_coins(
                    swapAddress
                );
            }
            for (uint256 i = 0; i < 4; i++) {
                poolTokens[i] = poolUnderlyingCoins[i];
            }
        }
    }

    /**
    @notice This function checks if the curve pool contains WBTC
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains WBTC, false otherwise
    */
    function isBtcPool(address swapAddress) public view returns (bool) {
        address[8] memory poolTokens = CurveRegistry.get_coins(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == wbtcToken || poolTokens[i] == sbtcCrvToken)
                return true;
        }
        return false;
    }

    /**
    @notice This function checks if the curve pool contains ETH
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains ETH, false otherwise
    */
    function isEthPool(address swapAddress) external view returns (bool) {
        address[8] memory poolTokens = CurveRegistry.get_coins(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == ETHAddress) {
                return true;
            }
        }
        return false;
    }

    /**
    @notice This function is used to check if the pool contains the token
    @param swapAddress Curve swap address for the pool
    @param tokenContractAddress contract address of the token
    @return true if the pool contains the token, false otherwise
    @return index of the token in the pool, 0 if pool does not contain the token
    */
    function isUnderlyingToken(
        address swapAddress,
        address tokenContractAddress
    ) external view returns (bool, uint256) {
        address[4] memory poolTokens = getPoolTokens(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == address(0)) return (false, 0);
            if (poolTokens[i] == tokenContractAddress) return (true, i);
        }
    }

    /**
    @notice Updates to the latest curve registry from the address provider
    */
    function update_curve_registry() external onlyOwner {
        address new_address = CurveAddressProvider.get_registry();

        require(address(CurveRegistry) != new_address, "Already updated");

        CurveRegistry = ICurveRegistry(new_address);
    }

    /**
    @notice Updates to the latest curve registry from the address provider
    */
    function update_factory_registry() external onlyOwner {
        address new_address = CurveAddressProvider.get_address(3);

        require(address(FactoryRegistry) != new_address, "Already updated");

        FactoryRegistry = ICurveFactoryRegistry(new_address);
    }

    /**
    @notice Add new pools which use the _use_underlying bool
    @param swapAddresses Curve swap addresses for the pool
    @param addUnderlying True if underlying tokens are always added
    */
    function updateShouldAddUnderlying(
        address[] calldata swapAddresses,
        bool[] calldata addUnderlying
    ) external onlyOwner {
        require(
            swapAddresses.length == addUnderlying.length,
            "Mismatched arrays"
        );
        for (uint256 i = 0; i < swapAddresses.length; i++) {
            shouldAddUnderlying[swapAddresses[i]] = addUnderlying[i];
        }
    }

    /**
    @notice Add new pools which use uamounts for add_liquidity
    @param swapAddresses Curve swap addresses to map from
    @param _depositAddresses Curve deposit addresses to map to
    */
    function updateDepositAddresses(
        address[] calldata swapAddresses,
        address[] calldata _depositAddresses
    ) external onlyOwner {
        require(
            swapAddresses.length == _depositAddresses.length,
            "Mismatched arrays"
        );
        for (uint256 i = 0; i < swapAddresses.length; i++) {
            depositAddresses[swapAddresses[i]] = _depositAddresses[i];
        }
    }

    /**
    //@notice Add new pools which use the _use_underlying bool
    */
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == ETHAddress) {
                qty = address(this).balance;
                Address.sendValue(Address.toPayable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }
}