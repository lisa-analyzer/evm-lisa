// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.5.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external;

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // This function is not a standard ERC20 interface, just for compitable with market.
    function decimals() external view returns (uint8);
}


/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    function balanceOf(address _owner) public view returns (uint);
    function allowance(address _owner, address _spender) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function totalSupply() public view returns (uint);
}


contract IDSToken is IERC20Token {
    function mint(address _account, uint _value) public;
    function burn(address _account, uint _value) public;
}


contract IDSWrappedToken is IERC20Token {
    function mint(address _account, uint _value) public;
    function burn(address _account, uint _value) public;
    function wrap(address _dst, uint _amount) public returns (uint);
    function unwrap(address _dst, uint _amount) public returns (uint);
    function changeByMultiple(uint _amount) public view returns (uint);
    function reverseByMultiple(uint _xAmount) public view returns (uint);
    function getSrcERC20() public view returns (address);
}


contract ERC20SafeTransfer {
    function doTransferOut(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool result;

        token.transfer(_to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return result;
    }

    function doTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool result;

        token.transferFrom(_from, _to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return result;
    }

    function doApprove(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool result;

        token.approve(_to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return result;
    }
}


contract IDFStore {

    function getSectionMinted(uint _position) public view returns (uint);
    function addSectionMinted(uint _amount) public;
    function addSectionMinted(uint _position, uint _amount) public;
    function setSectionMinted(uint _amount) public;
    function setSectionMinted(uint _position, uint _amount) public;

    function getSectionBurned(uint _position) public view returns (uint);
    function addSectionBurned(uint _amount) public;
    function addSectionBurned(uint _position, uint _amount) public;
    function setSectionBurned(uint _amount) public;
    function setSectionBurned(uint _position, uint _amount) public;

    function getSectionToken(uint _position) public view returns (address[] memory);
    function getSectionWeight(uint _position) public view returns (uint[] memory);
    function getSectionData(uint _position) public view returns (uint, uint, uint, address[] memory, uint[] memory);
    function getBackupSectionData(uint _position) public view returns (uint, address[] memory, uint[] memory);
    function getBackupSectionIndex(uint _position) public view returns (uint);
    function setBackupSectionIndex(uint _position, uint _backupIdx) public;

    function setSection(address[] memory _wrappedTokens, uint[] memory _weight) public;
    function setBackupSection(uint _position, address[] memory _tokens, uint[] memory _weight) public;
    function burnSectionMoveon() public;

    function getMintingToken(address _token) public view returns (bool);
    function setMintingToken(address _token, bool _flag) public;
    function getMintedToken(address _token) public view returns (bool);
    function setMintedToken(address _token, bool _flag) public;
    function getBackupToken(address _token) public view returns (address);
    function setBackupToken(address _token, address _backupToken) public;
    function getMintedTokenList() public view returns (address[] memory);

    function getMintPosition() public view returns (uint);
    function getBurnPosition() public view returns (uint);

    function getTotalMinted() public view returns (uint);
    function addTotalMinted(uint _amount) public;
    function setTotalMinted(uint _amount) public;
    function getTotalBurned() public view returns (uint);
    function addTotalBurned(uint _amount) public;
    function setTotalBurned(uint _amount) public;
    function getMinBurnAmount() public view returns (uint);
    function setMinBurnAmount(uint _amount) public;

    function getTokenBalance(address _tokenID) public view returns (uint);
    function setTokenBalance(address _tokenID, uint _amount) public;
    function getResUSDXBalance(address _tokenID) public view returns (uint);
    function setResUSDXBalance(address _tokenID, uint _amount) public;
    function getDepositorBalance(address _depositor, address _tokenID) public view returns (uint);
    function setDepositorBalance(address _depositor, address _tokenID, uint _amount) public;

    function getFeeRate(uint ct) public view returns (uint);
    function setFeeRate(uint ct, uint rate) public;
    function getTypeToken(uint tt) public view returns (address);
    function setTypeToken(uint tt, address _tokenID) public;
    function getTokenMedian(address _tokenID) public view returns (address);
    function setTokenMedian(address _tokenID, address _median) public;

    function setTotalCol(uint _amount) public;
    function getTotalCol() public view returns (uint);

    function setWrappedToken(address _srcToken, address _wrappedToken) public;
    function getWrappedToken(address _srcToken) public view returns (address);
}


contract IDFPoolV2 {
    function transferOut(address _tokenID, address _to, uint _amount) public returns (bool);
    function transferOutSrc(address _tokenID, address _to, uint _amount) public returns (bool);
    function transferFromSender(address _tokenID, address _from, uint _amount) public returns (bool);
    function transferFromSenderOneClick(address _tokenID, address _from, uint _amount) public returns (bool);
    function transferToCol(address _tokenID, uint _amount) public returns (bool);
    function transferFromSenderToCol(address _tokenID, address _from, uint _amount) public returns (bool);
    function approveToEngine(address _tokenIdx, address _engineAddress) public;
    function getInterestByXToken(address _xToken) public returns (address, uint256);
    function getUnderlying(address _underlying) public returns (uint256);
}


contract IMedianizer {
    function read() public view returns (bytes32);
}
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

/// math.sol -- mixin for inline numerical wizardry

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


contract DSMath {
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

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    // function imin(int x, int y) internal pure returns (int z) {
    //     return x <= y ? x : y;
    // }
    // function imax(int x, int y) internal pure returns (int z) {
    //     return x >= y ? x : y;
    // }

    uint constant WAD = 10 ** 18;
    // uint constant RAY = 10 ** 27;

    // function wmul(uint x, uint y) internal pure returns (uint z) {
    //     z = add(mul(x, y), WAD / 2) / WAD;
    // }
    // function rmul(uint x, uint y) internal pure returns (uint z) {
    //     z = add(mul(x, y), RAY / 2) / RAY;
    // }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    // function rdiv(uint x, uint y) internal pure returns (uint z) {
    //     z = add(mul(x, RAY), y / 2) / y;
    // }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    // function rpow(uint _x, uint n) internal pure returns (uint z) {
    //     uint x = _x;
    //     z = n % 2 != 0 ? x : RAY;

    //     for (n /= 2; n != 0; n /= 2) {
    //         x = rmul(x, x);

    //         if (n % 2 != 0) {
    //             z = rmul(z, x);
    //         }
    //     }
    // }

    /**
     * @dev x to the power of y power(base, exponent)
     */
    function pow(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) {
            return 1;
        }
        else if (exponent == 1) {
            return base;
        }
        else if (base == 0 && exponent != 0) {
            return 0;
        }
        else {
            uint256 z = base;
            for (uint256 i = 1; i < exponent; i++)
                z = mul(z, base);
            return z;
        }
    }
}



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    function initReentrancyStatus() internal {
        _status = _NOT_ENTERED;
    }
}

//SWC-DoS With Block Gas Limit: L2-L333


contract DFEngineV2 is DSMath, DSAuth, ReentrancyGuard, ERC20SafeTransfer {
    bool private initialized;
    IDFStore public dfStore;
    IDFPoolV2 public dfPool;
    IDSToken public usdxToken;
    address public dfCol;
    address public dfFunds;

    enum ProcessType {
        CT_DEPOSIT,
        CT_DESTROY,
        CT_CLAIM,
        CT_WITHDRAW
    }

    constructor (
        address _usdxToken,
        address _dfStore,
        address _dfPool,
        address _dfCol,
        address _dfFunds)
        public
    {
        initialize(_usdxToken, _dfStore, _dfPool, _dfCol, _dfFunds);
    }

    // --- Init ---
    function initialize(
        address _usdxToken,
        address _dfStore,
        address _dfPool,
        address _dfCol,
        address _dfFunds
    ) public {
        require(!initialized, "initialize: Already initialized!");
        owner = msg.sender;
        initReentrancyStatus();
        usdxToken = IDSToken(_usdxToken);
        dfStore = IDFStore(_dfStore);
        dfPool = IDFPoolV2(_dfPool);
        dfCol = _dfCol;
        dfFunds = _dfFunds;
        initialized = true;
    }

    function getPrice(address oracle) public view returns (uint) {
        bytes32 price = IMedianizer(oracle).read();
        return uint(price);
    }

    function _unifiedCommission(ProcessType ct, uint _feeTokenIdx, address depositor, uint _amount) internal {
        uint rate = dfStore.getFeeRate(uint(ct));
        if(rate > 0) {
            address _token = dfStore.getTypeToken(_feeTokenIdx);
            require(_token != address(0), "_UnifiedCommission: fee token not correct.");
            uint dfPrice = getPrice(dfStore.getTokenMedian(_token));
            uint dfFee = div(mul(mul(_amount, rate), WAD), mul(10000, dfPrice));
            require(
                doTransferFrom(
                    _token,
                    depositor,
                    dfFunds,
                    dfFee
                ),
                "_unifiedCommission: transferFrom fee failed"
            );
        }
    }

    function deposit(address _depositor, address _srcToken, uint _feeTokenIdx, uint _srcAmount) public auth nonReentrant returns (uint) {
        address _tokenID = dfStore.getWrappedToken(_srcToken);
        require(dfStore.getMintingToken(_tokenID), "Deposit: asset is not allowed.");

        uint _amount = IDSWrappedToken(_tokenID).wrap(address(dfPool), _srcAmount);
        require(_amount > 0, "Deposit: amount is invalid.");
        dfPool.transferFromSender(_srcToken, _depositor, IDSWrappedToken(_tokenID).reverseByMultiple(_amount));
        _unifiedCommission(ProcessType.CT_DEPOSIT, _feeTokenIdx, _depositor, _amount);

        address[] memory _tokens;
        uint[] memory _mintCW;
        (, , , _tokens, _mintCW) = dfStore.getSectionData(dfStore.getMintPosition());

        uint[] memory _tokenBalance = new uint[](_tokens.length);
        uint[] memory _resUSDXBalance = new uint[](_tokens.length);
        uint[] memory _depositorBalance = new uint[](_tokens.length);
        //For stack limit sake.
        uint _misc = uint(-1);

        for (uint i = 0; i < _tokens.length; i++) {
            _tokenBalance[i] = dfStore.getTokenBalance(_tokens[i]);
            _resUSDXBalance[i] = dfStore.getResUSDXBalance(_tokens[i]);
            _depositorBalance[i] = dfStore.getDepositorBalance(_depositor, _tokens[i]);
            if (_tokenID == _tokens[i]){
                _tokenBalance[i] = add(_tokenBalance[i], _amount);
                _depositorBalance[i] = add(_depositorBalance[i], _amount);
            }
            _misc = min(div(_tokenBalance[i], _mintCW[i]), _misc);
        }
        if (_misc > 0) {
            return _convert(_depositor, _tokens, _mintCW, _tokenBalance, _resUSDXBalance, _depositorBalance, _misc);
        }
        /** Just retrieve minting tokens here. If minted balance has USDX, call claim.*/
        /// @dev reuse _tokenBalance[0], _tokenBalance[1] to avoid stack too deep
        _tokenBalance[1] = 0;
        for (uint i = 0; i < _tokens.length; i++) {
            _tokenBalance[0] = min(_depositorBalance[i], _resUSDXBalance[i]);

            if (_tokenBalance[0] == 0) {
                if (_tokenID == _tokens[i]) {
                    dfStore.setDepositorBalance(_depositor, _tokens[i], _depositorBalance[i]);
                }
                continue;
            }

            dfStore.setDepositorBalance(_depositor, _tokens[i], sub(_depositorBalance[i], _tokenBalance[0]));
            dfStore.setResUSDXBalance(_tokens[i], sub(_resUSDXBalance[i], _tokenBalance[0]));
            _tokenBalance[1] = add(_tokenBalance[1], _tokenBalance[0]);
        }

        if (_tokenBalance[1] > 0)
            dfPool.transferOut(address(usdxToken), _depositor, _tokenBalance[1]);

        _misc = add(_amount, dfStore.getTokenBalance(_tokenID));
        dfStore.setTokenBalance(_tokenID, _misc);

        return (_tokenBalance[1]);
    }

    function withdraw(address _depositor, address _srcToken, uint _feeTokenIdx, uint _srcAmount) public auth nonReentrant returns (uint) {
        address _tokenID = dfStore.getWrappedToken(_srcToken);
        uint _amount = IDSWrappedToken(_tokenID).changeByMultiple(_srcAmount);
        require(_amount > 0, "Withdraw: amount is invalid.");

        uint _depositorBalance = dfStore.getDepositorBalance(_depositor, _tokenID);
        uint _tokenBalance = dfStore.getTokenBalance(_tokenID);
        uint _withdrawAmount = min(_amount, min(_tokenBalance, _depositorBalance));

        if (_withdrawAmount <= 0)
            return (0);

        _depositorBalance = sub(_depositorBalance, _withdrawAmount);
        dfStore.setDepositorBalance(_depositor, _tokenID, _depositorBalance);
        dfStore.setTokenBalance(_tokenID, sub(_tokenBalance, _withdrawAmount));
        _unifiedCommission(ProcessType.CT_WITHDRAW, _feeTokenIdx, _depositor, _withdrawAmount);
        IDSWrappedToken(_tokenID).unwrap(address(dfPool), _withdrawAmount);
        uint _srcWithdrawAmount = IDSWrappedToken(_tokenID).reverseByMultiple(_withdrawAmount);
        dfPool.transferOut(_srcToken, _depositor, _srcWithdrawAmount);

        return (_srcWithdrawAmount);
    }

    function claim(address _depositor, uint _feeTokenIdx) public auth nonReentrant returns (uint) {
        address[] memory _tokens = dfStore.getMintedTokenList();
        uint _resUSDXBalance;
        uint _depositorBalance;
        uint _depositorMintAmount;
        uint _mintAmount;

        for (uint i = 0; i < _tokens.length; i++) {
            _resUSDXBalance = dfStore.getResUSDXBalance(_tokens[i]);
            _depositorBalance = dfStore.getDepositorBalance(_depositor, _tokens[i]);

            _depositorMintAmount = min(_resUSDXBalance, _depositorBalance);
            _mintAmount = add(_mintAmount, _depositorMintAmount);

            if (_depositorMintAmount > 0){
                dfStore.setResUSDXBalance(_tokens[i], sub(_resUSDXBalance, _depositorMintAmount));
                dfStore.setDepositorBalance(_depositor, _tokens[i], sub(_depositorBalance, _depositorMintAmount));
            }
        }

        if (_mintAmount <= 0)
            return 0;

        _unifiedCommission(ProcessType.CT_CLAIM, _feeTokenIdx, _depositor, _mintAmount);
        dfPool.transferOut(address(usdxToken), _depositor, _mintAmount);
        return _mintAmount;
    }

    function destroy(address _depositor, uint _feeTokenIdx, uint _amount) public auth nonReentrant returns (bool) {
        require(_amount > 0 && (_amount % dfStore.getMinBurnAmount() == 0), "Destroy: amount not correct.");
        require(_amount <= usdxToken.balanceOf(_depositor), "Destroy: exceed max USDX balance.");
        require(_amount <= sub(dfStore.getTotalMinted(), dfStore.getTotalBurned()), "Destroy: not enough to burn.");
        address[] memory _tokens;
        uint[] memory _burnCW;
        uint _sumBurnCW;
        uint _burned;
        uint _minted;
        uint _burnedAmount;
        uint _amountTemp = _amount;
        uint _tokenAmount;

        _unifiedCommission(ProcessType.CT_DESTROY, _feeTokenIdx, _depositor, _amount);

        while(_amountTemp > 0) {
            (_minted, _burned, , _tokens, _burnCW) = dfStore.getSectionData(dfStore.getBurnPosition());

            _sumBurnCW = 0;
            for (uint i = 0; i < _burnCW.length; i++) {
                _sumBurnCW = add(_sumBurnCW, _burnCW[i]);
            }

            if (add(_burned, _amountTemp) <= _minted){
                dfStore.setSectionBurned(add(_burned, _amountTemp));
                _burnedAmount = _amountTemp;
                _amountTemp = 0;
            } else {
                _burnedAmount = sub(_minted, _burned);
                _amountTemp = sub(_amountTemp, _burnedAmount);
                dfStore.setSectionBurned(_minted);
                dfStore.burnSectionMoveon();
            }

            if (_burnedAmount == 0)
                continue;

            for (uint i = 0; i < _tokens.length; i++) {

                _tokenAmount = div(mul(_burnedAmount, _burnCW[i]), _sumBurnCW);
                IDSWrappedToken(_tokens[i]).unwrap(dfCol, _tokenAmount);
                dfPool.transferOutSrc(
                    IDSWrappedToken(_tokens[i]).getSrcERC20(),
                    _depositor,
                    IDSWrappedToken(_tokens[i]).reverseByMultiple(_tokenAmount));
                dfStore.setTotalCol(sub(dfStore.getTotalCol(), _tokenAmount));
            }
        }

        usdxToken.burn(_depositor, _amount);
        checkUSDXTotalAndColTotal();
        dfStore.addTotalBurned(_amount);

        return true;
    }

    function oneClickMinting(address _depositor, uint _feeTokenIdx, uint _amount) public auth nonReentrant {
        address[] memory _tokens;
        uint[] memory _mintCW;
        uint _sumMintCW;
        uint _srcAmount;

        (, , , _tokens, _mintCW) = dfStore.getSectionData(dfStore.getMintPosition());
        for (uint i = 0; i < _mintCW.length; i++) {
            _sumMintCW = add(_sumMintCW, _mintCW[i]);
        }
        require(_sumMintCW != 0, "OneClickMinting: minting section is empty");
        require(_amount > 0 && _amount % _sumMintCW == 0, "OneClickMinting: amount error");

        _unifiedCommission(ProcessType.CT_DEPOSIT, _feeTokenIdx, _depositor, _amount);

        for (uint i = 0; i < _mintCW.length; i++) {

            _srcAmount = IDSWrappedToken(_tokens[i]).reverseByMultiple(div(mul(_amount, _mintCW[i]), _sumMintCW));
            dfPool.transferFromSenderOneClick(IDSWrappedToken(_tokens[i]).getSrcERC20(), _depositor, _srcAmount);
            dfStore.setTotalCol(add(dfStore.getTotalCol(), div(mul(_amount, _mintCW[i]), _sumMintCW)));
            IDSWrappedToken(_tokens[i]).wrap(dfCol, _srcAmount);
        }

        dfStore.addTotalMinted(_amount);
        dfStore.addSectionMinted(_amount);
        usdxToken.mint(_depositor, _amount);
        checkUSDXTotalAndColTotal();
    }

    function _convert(
        address _depositor,
        address[] memory _tokens,
        uint[] memory _mintCW,
        uint[] memory _tokenBalance,
        uint[] memory _resUSDXBalance,
        uint[] memory _depositorBalance,
        uint _step)
        internal
        returns(uint)
    {
        uint _mintAmount;
        uint _mintTotal;
        uint _depositorMintAmount;
        uint _depositorMintTotal;

        for (uint i = 0; i < _tokens.length; i++) {
            _mintAmount = mul(_step, _mintCW[i]);
            _depositorMintAmount = min(_depositorBalance[i], add(_resUSDXBalance[i], _mintAmount));
            dfStore.setTokenBalance(_tokens[i], sub(_tokenBalance[i], _mintAmount));
            dfPool.transferToCol(_tokens[i], _mintAmount);
            dfStore.setTotalCol(add(dfStore.getTotalCol(), _mintAmount));
            _mintTotal = add(_mintTotal, _mintAmount);

            if (_depositorMintAmount == 0){
                dfStore.setResUSDXBalance(_tokens[i], add(_resUSDXBalance[i], _mintAmount));
                continue;
            }

            dfStore.setDepositorBalance(_depositor, _tokens[i], sub(_depositorBalance[i], _depositorMintAmount));
            dfStore.setResUSDXBalance(_tokens[i], sub(add(_resUSDXBalance[i], _mintAmount), _depositorMintAmount));
            _depositorMintTotal = add(_depositorMintTotal, _depositorMintAmount);
        }

        dfStore.addTotalMinted(_mintTotal);
        dfStore.addSectionMinted(_mintTotal);
        usdxToken.mint(address(dfPool), _mintTotal);
        checkUSDXTotalAndColTotal();
        dfPool.transferOut(address(usdxToken), _depositor, _depositorMintTotal);
        return _depositorMintTotal;
    }

    function checkUSDXTotalAndColTotal() internal view {
        address[] memory _tokens = dfStore.getMintedTokenList();
        address _dfCol = dfCol;
        uint _colTotal;
        for (uint i = 0; i < _tokens.length; i++) {
            _colTotal = add(_colTotal, IDSToken(_tokens[i]).balanceOf(_dfCol));
        }
        uint _usdxTotalSupply = usdxToken.totalSupply();
        require(_usdxTotalSupply <= _colTotal,
                "checkUSDXTotalAndColTotal : Amount of the usdx will be greater than collateral.");
        require(_usdxTotalSupply == dfStore.getTotalCol(),
                "checkUSDXTotalAndColTotal : Usdx and total collateral are not equal.");
    }
}
