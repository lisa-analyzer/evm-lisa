pragma solidity 0.5.11;

/**
 * @title OUSD InitializableGovernable Contract
 * @author Origin Protocol Inc
 */
import {
    Initializable
} from "@openzeppelin/upgrades/contracts/Initializable.sol";

import { Governable } from "./Governable.sol";

// SWC-Code With No Effects: L14 - L18
contract InitializableGovernable is Governable, Initializable {
    function _initialize(address _governor) internal {
        _changeGovernor(_governor);
    }
}
