pragma solidity ^0.5.2;

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

contract IDSWrappedToken is IERC20Token {
    function mint(address _account, uint _value) public;
    function burn(address _account, uint _value) public;
    function wrap(address _dst, uint _amount) public returns (uint);
    function unwrap(address _dst, uint _amount) public returns (uint);
    function changeByMultiple(uint _amount) public view returns (uint);
    function reverseByMultiple(uint _xAmount) public view returns (uint);
    function getSrcERC20() public view returns (address);
}

contract DFStore is DSMath, DSAuth {
    // MEMBERS
    /// @dev  cw - The Weight of collateral
    struct Section {
        uint        minted;
        uint        burned;
        uint        backupIdx;
        address[]   colIDs;
        uint[]      cw;
    }

    Section[] public secList;

    mapping(address => address) public wrappedTokens;

    uint backupSeed = 1;
    mapping(uint => Section) public secListBackup;

    mapping(address => bool) public mintingTokens;
    mapping(address => bool) public mintedTokens;
    mapping(address => address) public tokenBackup;

    address[] public mintedTokenList;

    /// @dev The position of current secList
    uint private mintPosition;

    /// @dev The position of old secList
    uint private burnPosition;

    /// @dev  The total amount of minted.
    uint private totalMinted;

    /// @dev  The total amount of burned.
    uint private totalBurned;

    /// @dev  The minimal amount of burned.
    uint private minimalBurnAmount = 10 ** 14;

    /// @dev The total amount of collateral.
    uint private totalCol;

    mapping(uint => uint) public FeeRate;
    mapping(uint => address) public FeeToken;
    mapping(address => address) public TokenMedian;
    mapping(address => uint) public poolBalance;
    mapping(address => uint) public resUSDXBalance;
    mapping(address => mapping (address => uint)) public depositorsBalance;

    event UpdateSection(address[] _wrappedTokens, uint[] _number);

    constructor(address[] memory _wrappedTokens, uint[] memory _weights) public {
        _setSection(_wrappedTokens, _weights);
    }

    function getSectionMinted(uint _position) public view returns (uint) {
        return secList[_position].minted;
    }

    function addSectionMinted(uint _amount) public auth {
        require(_amount > 0, "AddSectionMinted: amount not correct.");
        secList[mintPosition].minted = add(secList[mintPosition].minted, _amount);
    }

    function addSectionMinted(uint _position, uint _amount) public auth {
        require(_amount > 0, "AddSectionMinted: amount not correct.");
        secList[_position].minted = add(secList[_position].minted, _amount);
    }

    function setSectionMinted(uint _amount) public auth {
        secList[mintPosition].minted = _amount;
    }

    function setSectionMinted(uint _position, uint _amount) public auth {
        secList[_position].minted = _amount;
    }

    function getSectionBurned(uint _position) public view returns (uint) {
        return secList[_position].burned;
    }

    function addSectionBurned(uint _amount) public auth {
        require(_amount > 0, "AddSectionBurned: amount not correct.");
        secList[burnPosition].burned = add(secList[burnPosition].burned, _amount);
    }

    function addSectionBurned(uint _position, uint _amount) public auth {
        require(_amount > 0, "AddSectionBurned: amount not correct.");
        secList[_position].burned = add(secList[_position].burned, _amount);
    }

    function setSectionBurned(uint _amount) public auth {
        secList[burnPosition].burned = _amount;
    }

    function setSectionBurned(uint _position, uint _amount) public auth {
        secList[_position].burned = _amount;
    }

    function getSectionToken(uint _position) public view returns (address[] memory) {
        return secList[_position].colIDs;
    }

    function getSectionWeight(uint _position) public view returns (uint[] memory) {
        return secList[_position].cw;
    }

    function getSectionData(uint _position) public view returns (uint, uint, uint, address[] memory, uint[] memory) {

        return (
            secList[_position].minted,
            secList[_position].burned,
            secList[_position].backupIdx,
            secList[_position].colIDs,
            secList[_position].cw
            );
    }

    function getBackupSectionData(uint _position) public view returns (uint, address[] memory, uint[] memory) {
        uint _backupIdx = getBackupSectionIndex(_position);
        return (secListBackup[_backupIdx].backupIdx, secListBackup[_backupIdx].colIDs, secListBackup[_backupIdx].cw);
    }

    function getBackupSectionIndex(uint _position) public view returns (uint) {
        return secList[_position].backupIdx;
    }

    function setBackupSectionIndex(uint _position, uint _backupIdx) public auth {
        secList[_position].backupIdx = _backupIdx;
    }
    //SWC-DoS with Failed Call: L138-L179
    function _setSection(address[] memory _wrappedTokens, uint[] memory _weight) internal {
        require(_wrappedTokens.length == _weight.length, "_SetSection: data not allow.");

        uint sum;
        uint factor = 10 ** 10;
        address[] memory _srcTokens = new address[](_weight.length);

        for (uint i = 0; i < _wrappedTokens.length; i++) {
            require(_weight[i] != 0, "_SetSection: invalid weight");
            require(_wrappedTokens[i] != address(0), "_SetSection: 0 address not allow.");
            _srcTokens[i] = IDSWrappedToken(_wrappedTokens[i]).getSrcERC20();
            require(_srcTokens[i] != address(0), "_SetSection: invalid address");
            sum = add(sum, _weight[i]);
        }

        secList.push(Section(0, 0, 0, new address[](_wrappedTokens.length), new uint[](_weight.length)));
        uint _mintPosition = secList.length - 1;

        if (_mintPosition > 0) {
            address[] memory _cruColIDs = getSectionToken(mintPosition);
            for (uint i = 0; i < _cruColIDs.length; i++)
                delete mintingTokens[_cruColIDs[i]];
        }

        for (uint i = 0; i < _wrappedTokens.length; i++) {
            require(mul(div(mul(_weight[i], factor), sum), sum) == mul(_weight[i], factor), "_SetSection: invalid weight");

            secList[_mintPosition].cw[i] = _weight[i];
            secList[_mintPosition].colIDs[i] = _wrappedTokens[i];
            mintingTokens[_wrappedTokens[i]] = true;
            wrappedTokens[_srcTokens[i]] = _wrappedTokens[i];

            if (mintedTokens[_wrappedTokens[i]])
                continue;

            mintedTokenList.push(_wrappedTokens[i]);
            mintedTokens[_wrappedTokens[i]] = true;
        }

        mintPosition = _mintPosition;
        emit UpdateSection(secList[mintPosition].colIDs, secList[mintPosition].cw);
    }

    function setSection(address[] memory _wrappedTokens, uint[] memory _weight) public auth {
        _setSection(_wrappedTokens, _weight);
    }

    function setBackupSection(uint _position, address[] memory _wrappedTokens, uint[] memory _weight) public auth {
        require(_wrappedTokens.length == _weight.length, "SetBackupSection: data not allow.");
        require(_position < mintPosition, "SetBackupSection: update mint section first.");

        uint _backupIdx = secList[_position].backupIdx;

        if (_backupIdx == 0){

            _backupIdx = backupSeed;
            secList[_position].backupIdx = _backupIdx;
            backupSeed = add(_backupIdx, 1);
        }

        secListBackup[_backupIdx] = Section(0, 0, _position, new address[](_wrappedTokens.length), new uint[](_weight.length));

        for (uint i = 0; i < _wrappedTokens.length; i++) {
            require(_wrappedTokens[i] != address(0), "SetBackupSection: token contract address invalid");
            require(_weight[i] > 0, "SetBackupSection: weight must greater than 0");

            secListBackup[_backupIdx].cw[i] = _weight[i];
            secListBackup[_backupIdx].colIDs[i] = _wrappedTokens[i];
            mintedTokens[_wrappedTokens[i]] = true;
        }
    }

    function burnSectionMoveon() public auth {
        require(
            secList[burnPosition].minted == secList[burnPosition].burned,
            "BurnSectionMoveon: burned not meet minted."
            );

        burnPosition = add(burnPosition, 1);
        assert(burnPosition <= mintPosition);
    }

    function getMintingToken(address _token) public view returns (bool) {
        return mintingTokens[_token];
    }

    function setMintingToken(address _token, bool _flag) public auth {
        mintingTokens[_token] = _flag;
    }

    function getMintedToken(address _token) public view returns (bool) {
        return mintedTokens[_token];
    }

    function setMintedToken(address _token, bool _flag) public auth {
        mintedTokens[_token] = _flag;
    }

    function getBackupToken(address _token) public view returns (address) {
        return tokenBackup[_token];
    }

    function setBackupToken(address _token, address _backupToken) public auth {
        tokenBackup[_token] = _backupToken;
    }

    function getMintedTokenList() public view returns (address[] memory) {
        return mintedTokenList;
    }

    function getMintPosition() public view returns (uint) {
        return mintPosition;
    }

    function getBurnPosition() public view returns (uint) {
        return burnPosition;
    }

    function getTotalMinted() public view returns (uint) {
        return totalMinted;
    }

    function addTotalMinted(uint _amount) public auth {
        require(_amount > 0, "AddTotalMinted: minted amount is zero.");
        totalMinted = add(totalMinted, _amount);
    }

    function setTotalMinted(uint _amount) public auth {
        totalMinted = _amount;
    }

    function getTotalBurned() public view returns (uint) {
        return totalBurned;
    }

    function addTotalBurned(uint _amount) public auth {
        require(_amount > 0, "AddTotalBurned: minted amount is zero.");
        totalBurned = add(totalBurned, _amount);
    }

    function setTotalBurned(uint _amount) public auth {
        totalBurned = _amount;
    }

    function getMinBurnAmount() public view returns (uint) {
        return minimalBurnAmount;
    }

    function setMinBurnAmount(uint _amount) public auth {
        _setMinBurnAmount(_amount);
    }

    function _setMinBurnAmount(uint _amount) internal {
        minimalBurnAmount = _amount;
    }

    function getTokenBalance(address _tokenID) public view returns (uint) {
        return poolBalance[_tokenID];
    }

    function setTokenBalance(address _tokenID, uint _amount) public auth {
        poolBalance[_tokenID] = _amount;
    }

    function getResUSDXBalance(address _tokenID) public view returns (uint) {
        return resUSDXBalance[_tokenID];
    }

    function setResUSDXBalance(address _tokenID, uint _amount) public auth {
        resUSDXBalance[_tokenID] = _amount;
    }

    function getDepositorBalance(address _depositor, address _tokenID) public view returns (uint) {
        return depositorsBalance[_depositor][_tokenID];
    }

    function setDepositorBalance(address _depositor, address _tokenID, uint _amount) public auth {
        depositorsBalance[_depositor][_tokenID] = _amount;
    }

    function setFeeRate(uint ct, uint rate) public auth {
        FeeRate[ct] = rate;
    }

    function getFeeRate(uint ct) public view returns (uint) {
        return FeeRate[ct];
    }

    function setTypeToken(uint tt, address _tokenID) public auth {
        FeeToken[tt] = _tokenID;
    }

    function getTypeToken(uint tt) public view returns (address) {
        return FeeToken[tt];
    }

    function setTokenMedian(address _tokenID, address _median) public auth {
        TokenMedian[_tokenID] = _median;
    }

    function getTokenMedian(address _tokenID) public view returns (address) {
        return TokenMedian[_tokenID];
    }

    function setTotalCol(uint _amount) public auth {
        totalCol = _amount;
    }

    function getTotalCol() public view returns (uint) {
        return totalCol;
    }

    function setWrappedToken(address _srcToken, address _wrappedToken) public auth {
        wrappedTokens[_srcToken] = _wrappedToken;
    }

    function getWrappedToken(address _srcToken) public view returns (address) {
        return  wrappedTokens[_srcToken];
    }
}
