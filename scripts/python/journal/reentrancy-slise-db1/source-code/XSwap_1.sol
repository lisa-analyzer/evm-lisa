// SPDX-License-Identifier: GPL-3.0-only
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.5.4;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
    event OwnerUpdate     (address indexed owner, address indexed newOwner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;
    address      public  newOwner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    // Warning: you should absolutely sure you want to give up authority!!!
    function disableOwnership() public onlyOwner {
        owner = address(0);
        emit OwnerUpdate(msg.sender, owner);
    }

    function transferOwnership(address newOwner_) public onlyOwner {
        require(newOwner_ != owner, "TransferOwnership: the same owner.");
        newOwner = newOwner_;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "AcceptOwnership: only new owner do this.");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }

    ///[snow] guard is Authority who inherit DSAuth.
    function setAuthority(DSAuthority authority_)
        public
        onlyOwner
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier onlyOwner {
        require(isOwner(msg.sender), "ds-auth-non-owner");
        _;
    }

    function isOwner(address src) internal view returns (bool) {
        return bool(src == owner);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}


interface IERC20Token {
    function balanceOf(address _owner) external view returns (uint);
    function allowance(address _owner, address _spender) external view returns (uint);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function totalSupply() external view returns (uint);
}

interface NonStandardIERC20Token {
    function balanceOf(address _owner) external view returns (uint);
    function allowance(address _owner, address _spender) external view returns (uint);
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function approve(address _spender, uint _value) external;
}

interface ILendFMe {
	function supply(address _token, uint _amounts) external returns (uint);
	function withdraw(address _token, uint _amounts) external returns (uint);
	function getSupplyBalance(address _user, address _token) external view returns (uint256);
}

interface IChai {
	function join(address dst, uint wad) external;
	function exit(address dst, uint wad) external;
	function draw(address src, uint wad) external;
}


library DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-overflow");
        z = x / y;
    }
}

contract XSwap is DSAuth {
	using DSMath for uint256;

	uint256 constant internal OFFSET = 10 ** 18;
	//Mainnet
	// address private chai = 0x06AF07097C9Eeb7fD685c692751D5C66dB49c215;
	// address private dai  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

	//Rinkeby
	address private chai = 0x8a5C1BD4D75e168a4f65eB902c289400B90FD980;
	address private dai  = 0xA3A59273494BB5B8F0a8FAcf21B3f666A47d6140;

	bool private actived;
	address public lendFMe;
	bool public isOpen;
	mapping(address => mapping(address => uint256)) public prices; // 1 tokenA = ? tokenB
	mapping(address => mapping(address => uint256)) public fee;   // fee from tokenA to tokenB
	mapping(address => bool) public supportLending;
	mapping(address => uint256) public decimals;

	constructor() public {
	}

	function active(address _lendFMe) public {
		require(actived == false, "already actived.");
		owner = msg.sender;
		isOpen = true;
		lendFMe = _lendFMe;
		actived = true;
	}

	// trade _inputAmount of _input token to get _output token
	function trade(address _input, address _output, uint256 _inputAmount) public returns (bool) {
		return trade(_input, _output, _inputAmount, msg.sender);
	}

	function trade(address _input, address _output, uint256 _inputAmount, address _receiver) public returns (bool) {
		require(isOpen, "not open");
		require(prices[_input][_output] != 0, "invalid token address");
		require(decimals[_input] != 0, "input decimal not setteled");
		require(decimals[_output] != 0, "output decimal not setteled");

		NonStandardIERC20Token(_input).transferFrom(msg.sender, address(this), _inputAmount);
		if(supportLending[_input]) {
			if (_input == dai) {
				IChai(chai).join(address(this), _inputAmount);
				ILendFMe(lendFMe).supply(chai, IERC20Token(chai).balanceOf(address(this)));
			}
			else
				ILendFMe(lendFMe).supply(_input, _inputAmount);
		}
		uint256 _tokenAmount = normalizeToken(_input, _inputAmount).mul(prices[_input][_output]).div(OFFSET);
		uint256 _fee = _tokenAmount.mul(fee[_input][_output]).div(OFFSET);
		uint256 _amountToUser = _tokenAmount.sub(_fee);

		if(supportLending[_output]) {
			if (_output == dai) {
				ILendFMe(lendFMe).withdraw(chai, _amountToUser); //assume chai / dai >= 1;
				IChai(chai).draw(address(this), _amountToUser);
			}
			else
				ILendFMe(lendFMe).withdraw(_output, denormalizedToken(_output, _amountToUser));
		}
		NonStandardIERC20Token(_output).transfer(_receiver, denormalizedToken(_output, _amountToUser));
		return true;
	}

	function getTokenLiquidation(address _token) public view returns (uint256) {
		uint256 balanceInDefi = ILendFMe(lendFMe).getSupplyBalance(address(this), _token);
		return balanceInDefi.add(NonStandardIERC20Token(_token).balanceOf(address(this)));
	}

	function setLendFMe(address _lendFMe) public auth returns (bool) {
		lendFMe = _lendFMe;
		return true;
	}

	function enableLending(address _token) public auth returns (bool) {
		require(!supportLending[_token], "the token is already supported lending");
		supportLending[_token] = true;

		if (_token == dai) {
			IERC20Token(_token).approve(chai, uint256(-1));
			IERC20Token(chai).approve(lendFMe, uint256(-1));
		}
		else {
			NonStandardIERC20Token(_token).approve(lendFMe, uint256(-1));
		}

		uint256 _balance = NonStandardIERC20Token(_token).balanceOf(address(this));
		if(_balance > 0) {
			if (_token == dai) {
				IChai(chai).join(address(this), _balance);
				ILendFMe(lendFMe).supply(chai, IERC20Token(chai).balanceOf(address(this)));
			}
			else
				ILendFMe(lendFMe).supply(_token, _balance);
		}
		return true;
	}

	function disableLending(address _token) public auth returns (bool) {
		require(supportLending[_token], "the token doesnt support lending");
		supportLending[_token] = false;

		if (_token == dai) {
			ILendFMe(lendFMe).withdraw(chai, uint256(-1));
			IChai(chai).exit(address(this), IERC20Token(chai).balanceOf(address(this)));
		}
		else
			ILendFMe(lendFMe).withdraw(_token, uint256(-1));

		return true;
	}

	// create new pairs
	function createPair(address _input, address _output, uint256 _priceInOut, uint256 _priceOutIn, uint256 _fee) external auth returns (bool) {
		setPrices(_input, _output, _priceInOut, _priceOutIn);
		setFee(_input, _output, _fee);
		return true;
	}

	function setPrices(address _input, address _output, uint256 _priceInOut, uint256 _priceOutIn) public auth returns (bool) {
		setPrices(_input, _output, _priceInOut);
		setPrices(_output, _input, _priceOutIn);
		return true;
	}
	//SWC-Integer Overflow and Underflow: L152
	function setPrices(address _input, address _output, uint256 _price) public auth returns (bool) {
		prices[_input][_output] = _price;
		return true;
	}

	function setFee(address _input, address _output, uint256 _fee) public auth returns (bool) {
		fee[_input][_output] = _fee;
		fee[_output][_input] = _fee;
		return true;
	}

	function setTokenDecimals(address _token, uint256 _decimals) public auth returns (bool){
		require(_decimals <= 18, "not supported decimal");
		decimals[_token] = _decimals;
		return true;
	}

	function emergencyStop(bool _open) external auth returns (bool) {
		isOpen = _open;
		return true;
	}

	function transferOut(address _token, address _receiver, uint256 _amount) external auth returns (bool) {
		if(supportLending[_token]) {
			if (_token == dai) {
				ILendFMe(lendFMe).withdraw(chai, _amount);
				IChai(chai).draw(address(this), _amount);
			}
			else
				ILendFMe(lendFMe).withdraw(_token, _amount);
		}
		uint256 _balance = NonStandardIERC20Token(_token).balanceOf(address(this));
		if(_balance >= _amount) {
			NonStandardIERC20Token(_token).transfer(_receiver, _amount);
			return true;
		}
		return false;
	}

	function transferOutALL(address _token, address _receiver) external auth returns (bool) {
		if(supportLending[_token]) {
			if (_token == dai) {
				ILendFMe(lendFMe).withdraw(chai, uint256(-1));
				IChai(chai).exit(address(this), IERC20Token(chai).balanceOf(address(this)));
			}
			else
				ILendFMe(lendFMe).withdraw(_token, uint256(-1));
		}
		uint256 _balance = NonStandardIERC20Token(_token).balanceOf(address(this));
		if(_balance > 0) {
			NonStandardIERC20Token(_token).transfer(_receiver, _balance);
		}

		return true;
	}

	function transferIn(address _token, uint256 _amount) external auth returns (bool) {
		NonStandardIERC20Token(_token).transferFrom(msg.sender, address(this), _amount);
		if(supportLending[_token]) {
			if (_token == dai) {
				IChai(chai).join(address(this), NonStandardIERC20Token(dai).balanceOf(address(this)));
				ILendFMe(lendFMe).supply(chai, IERC20Token(chai).balanceOf(address(this)));
			}
			else
				ILendFMe(lendFMe).supply(_token, NonStandardIERC20Token(_token).balanceOf(address(this)));
		}
	    return true;
	}

	function normalizeToken(address _token, uint256 _amount) internal view returns (uint256) {
		uint256 n = 18;
		return _amount.mul((10 ** (n.sub(decimals[_token]))));
	}

	function denormalizedToken(address _token, uint256 _amount) internal view returns (uint256) {
		uint256 n = 18;
		return _amount.div((10 ** (n.sub(decimals[_token]))));
	}
}