// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract AcrossToken is ERC20, Ownable {
    constructor() ERC20("Across Protocol Token", "ACX") {}

    function mint(address _guy, uint256 _wad) external onlyOwner {
        _mint(_guy, _wad);
    }

    function burn(address _guy, uint256 _wad) external onlyOwner {
        _burn(_guy, _wad);
    }
}