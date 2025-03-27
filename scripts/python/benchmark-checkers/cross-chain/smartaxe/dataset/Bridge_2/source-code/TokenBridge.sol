//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

string constant NAME = "TokenForBridge";
string constant SYMBOL = "TFB";

contract TokenForBridge is ERC20 {
    address private bridge;
    address private owner;

    constructor(address _bridge) ERC20(NAME, SYMBOL) {
        owner = msg.sender;
        bridge = _bridge;
    }

    modifier onlyBridgeOrOwner() {
        require(
            bridge == msg.sender || owner == msg.sender,
            "Only a bridge can do that."
        );
        _;
    }

    function mint(address _account, uint256 _amount) external onlyBridgeOrOwner {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlyBridgeOrOwner {
        _burn(_account, _amount);
    }
}
