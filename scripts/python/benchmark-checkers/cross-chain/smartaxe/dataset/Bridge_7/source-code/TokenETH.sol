pragma solidity ^0.8.6;

import "./TokenConfig.sol";

contract TokenETH is TokenConfig {
    constructor() TokenConfig("TETH Token", "TETH") {}
}
