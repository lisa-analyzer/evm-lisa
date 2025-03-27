// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRC20.sol";

contract DeployTokens {
	address[] tokens;
	constructor(string[] memory symbols, address owner) {
		for(uint i=0; i<symbols.length; i++) {
			IRC20 token = new IRC20(symbols[i], symbols[i], 18);
			token.mintTo(owner, 1e24);
			token.transferOwnership(owner);
			tokens.push(address(token));
		}
	}
	function getTokens() public view returns(address[] memory) {
		return tokens;
	}
}