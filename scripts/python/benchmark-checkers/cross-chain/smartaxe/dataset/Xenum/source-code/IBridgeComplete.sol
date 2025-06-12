//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBridge.sol";
import "./IBridgeFungible.sol";
import "./IBridgeNonFungible.sol";
import "./IBridgeMixedFungible.sol";

/**
 * @dev Interface for bridge contract with extra functions for bridging tokens
 */
interface IBridgeComplete is IBridgeFungible, IBridgeNonFungible, IBridgeMixedFungible {}
