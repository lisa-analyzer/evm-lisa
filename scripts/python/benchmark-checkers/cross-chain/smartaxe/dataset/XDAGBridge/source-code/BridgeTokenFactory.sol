// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BridgeToken.sol";

interface IBridgeTokenFactory {
    function createBridgeToken(
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external returns (address);

    event BridgeTokenCreated(
        address indexed token,
        string symbol,
        uint8 decimals
    );
}

contract BridgeTokenFactory is IBridgeTokenFactory, Ownable {
    constructor() {}

    function createBridgeToken(
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external override /*onlyOwner*/ returns (address) {
        address bridgeToken =
            address(new BridgeToken(name, symbol, owner(), decimals));
        emit BridgeTokenCreated(bridgeToken, symbol, decimals);
        return bridgeToken;
    }
}
