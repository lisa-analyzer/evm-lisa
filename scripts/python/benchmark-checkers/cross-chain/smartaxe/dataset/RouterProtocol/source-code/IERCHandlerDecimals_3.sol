// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
    @title Interface to be used with handlers that support ERC20s and ERC721s.
    @author Router Protocol.
 */
interface IERCHandlerDecimals {
    
    function setTokenDecimals(address tokenAddress, uint8 destinationChainID, uint8 decimals) external;

}