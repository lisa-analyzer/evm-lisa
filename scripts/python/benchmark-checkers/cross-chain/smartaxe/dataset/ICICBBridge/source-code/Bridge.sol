// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IRC20.sol";
import "./IBridge.sol";

contract Bridge is Ownable, IBridge {
	address admin;

	uint					public tokenCount;
	address[]				public tokens;
	mapping(address=>uint) 	public tokenIndexes;
	mapping(bytes32=>bool) 	public exists;

	constructor(address _admin) {
		admin = _admin;
	}

	modifier onlyAdmin() {
		require(msg.sender == admin || msg.sender == owner);
		_;
	}
	
	function addToken(address[] memory _tokens) external override onlyAdmin {
		address _this = address(this);
		for(uint i=0; i<_tokens.length; i++) {
			IRC20 _token = IRC20(_tokens[i]);
			require(_token.owner()==_this, "bridge: owner");
			require(_token.totalSupply()==0, "bridge: totalsupply");
			tokens.push(_tokens[i]);
			tokenIndexes[_tokens[i]] = ++tokenCount;
		}
	}
	
	function createToken(string[] memory _names, string[] memory _symbols, uint8[] memory _decimals) external override onlyAdmin {
		require(_names.length==_symbols.length && _symbols.length==_decimals.length,"bridge: array size");
		for(uint i=0; i<_names.length; i++) {
			IRC20 _tokenContract = new IRC20(_names[i], _symbols[i], _decimals[i]);
			address _token = address(_tokenContract);
			tokens.push(_token);
			tokenIndexes[_token] = ++tokenCount;
		}
	}

	function deposit(address _token, uint _amount, uint _targetChain) external override payable {
		address _account = msg.sender;
		uint256 size;
        assembly {size := extcodesize(_account)}
		require(size==0, "bridge: only personal");
		require(_account!=address(0), "bridge: zero sender");
		if (_token==address(0)) {
			require(msg.value==_amount, "bridge: amount");
		} else {
			bool isPegged = tokenIndexes[_token]!=0;
			if (isPegged) {
				IRC20(_token).burnFrom(_account, _amount);
			} else {
				IRC20(_token).transferFrom(_account, address(this), _amount);
			}
		}
		emit Deposit(_token, _account, _amount, _targetChain);
	}

    function transfer(uint[][] memory _args) external override payable onlyAdmin {
		for(uint i=0; i<_args.length; i++) {
			address _token 		= address(uint160(_args[i][0]));
			address _to			= address(uint160(_args[i][1]));
			uint _amount 		= _args[i][2];
			bytes32 _extra 		= bytes32(_args[i][3]);
			bool isPegged = false;
			if (!exists[_extra]) {
				if (_token==address(0)) {
					payable(_to).transfer(_amount);
				} else {
					isPegged = tokenIndexes[_token]!=0;
					if (isPegged) {
						IRC20(_token).mintTo(_to, _amount);
					} else {
						IRC20(_token).transfer(_to, _amount);
					}
				}
				exists[_extra] = true;
			}
		}
	}
}