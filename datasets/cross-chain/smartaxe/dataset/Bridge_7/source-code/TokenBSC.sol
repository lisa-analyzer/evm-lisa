pragma solidity ^0.8.6;

import "./TokenConfig.sol";

contract TokenBSC is TokenConfig {
    constructor() TokenConfig("TBSC Token", "TBSC") {}
}
