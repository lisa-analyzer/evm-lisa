pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./ReentrancyGuard.sol";

contract PolkaBridgeLaunchPad is Ownable, ReentrancyGuard {
    string public name = "PolkaBridge: LaunchPad v2";
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 polkaBridgeToken;

    address payable private ReceiveToken;

    struct IDOPool {
        uint256 Id;
        uint256 Begin;
        uint256 End;
        uint256 Type; //1:public, 2:private
        uint256 AmountPBRRequire; //must e18,important when init
        IERC20 IDOToken;
        uint256 MinPurchase;
        uint256 MaxPurchase;
        uint256 TotalCap;
        uint256 MinimumTokenSoldout;
        uint256 TotalToken; //total sale token for this pool
        uint256 RatePerETH;
        bool IsActived;
        bool IsStoped;
        uint256 ActivedDate;
        uint256 StopDate;
        uint256 LockDuration; //lock after purchase
        uint256 TotalSold; //total number of token sold
    }

    struct User {
        uint256 Id;
        address UserAddress;
        bool IsWhitelist;
        uint256 WhitelistDate;
        uint256 TotalTokenPurchase;
        uint256 TotalETHPurchase;
        uint256 PurchaseTime;
        bool IsActived;
        bool IsClaimed;
    }

    mapping(uint256 => mapping(address => User)) public whitelist; //poolid - listuser

    IDOPool[] pools;

    constructor(address payable receiveTokenAdd, IERC20 polkaBridge) public {
        ReceiveToken = receiveTokenAdd;
        polkaBridgeToken = polkaBridge;
    }

    function addWhitelist(address user, uint256 pid) public onlyOwner {
        whitelist[pid][user].Id = pid;
        whitelist[pid][user].UserAddress = user;
        whitelist[pid][user].IsWhitelist = true;
        whitelist[pid][user].WhitelistDate = block.timestamp;
        whitelist[pid][user].IsActived = true;
    }

    function addMulWhitelist(address[] memory user, uint256 pid)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < user.length; i++) {
            whitelist[pid][user[i]].Id = pid;
            whitelist[pid][user[i]].UserAddress = user[i];
            whitelist[pid][user[i]].IsWhitelist = true;
            whitelist[pid][user[i]].WhitelistDate = block.timestamp;
            whitelist[pid][user[i]].IsActived = true;
        }
    }

    function updateWhitelist(
        address user,
        uint256 pid,
        bool isWhitelist,
        bool isActived
    ) public onlyOwner {
        whitelist[pid][user].IsWhitelist = isWhitelist;
        whitelist[pid][user].IsActived = isActived;
    }

    function IsWhitelist(address user, uint256 pid) public view returns (bool) {
        return whitelist[pid][user].IsWhitelist;
    }

    function addPool(
        uint256 begin,
        uint256 end,
        uint256 _type,
        IERC20 idoToken,
        uint256 minPurchase,
        uint256 maxPurchase,
        uint256 totalCap,
        uint256 totalToken,
        uint256 amountPBRRequire,
        uint256 ratePerETH,
        uint256 lockDuration,
        uint256 minimumTokenSoldout
    ) public onlyOwner {
        uint256 id = pools.length.add(1);
        pools.push(
            IDOPool({
                Id: id,
                Begin: begin,
                End: end,
                Type: _type,
                AmountPBRRequire: amountPBRRequire,
                IDOToken: idoToken,
                MinPurchase: minPurchase,
                MaxPurchase: maxPurchase,
                TotalCap: totalCap,
                TotalToken: totalToken,
                RatePerETH: ratePerETH,
                IsActived: true,
                IsStoped: false,
                ActivedDate: block.timestamp,
                StopDate: 0,
                LockDuration: lockDuration,
                TotalSold: 0,
                MinimumTokenSoldout: minimumTokenSoldout
            })
        );
    }

    function updatePool(
        uint256 pid,
        uint256 begin,
        uint256 end,
        uint256 amountPBRRequire,
        uint256 minPurchase,
        uint256 maxPurchase,
        uint256 totalCap,
        uint256 totalToken,
        uint256 ratePerETH,
        uint256 lockDuration,
        IERC20 idoToken,
        uint256 minimumTokenSoldout
    ) public onlyOwner {
        uint256 poolIndex = pid.sub(1);
        if (begin > 0) {
            pools[poolIndex].Begin = begin;
        }
        if (end > 0) {
            pools[poolIndex].End = end;
        }
        if (amountPBRRequire > 0) {
            pools[poolIndex].AmountPBRRequire = amountPBRRequire;
        }
        if (minPurchase > 0) {
            pools[poolIndex].MinPurchase = minPurchase;
        }
        if (maxPurchase > 0) {
            pools[poolIndex].MaxPurchase = maxPurchase;
        }
        if (totalCap > 0) {
            pools[poolIndex].TotalCap = totalCap;
        }
        if (totalToken > 0) {
            pools[poolIndex].TotalToken = totalToken;
        }
        if (ratePerETH > 0) {
            pools[poolIndex].RatePerETH = ratePerETH;
        }
        if (lockDuration > 0) {
            pools[poolIndex].LockDuration = lockDuration;
        }
        if (minimumTokenSoldout > 0) {
            pools[poolIndex].MinimumTokenSoldout = minimumTokenSoldout;
        }
        pools[poolIndex].IDOToken = idoToken;
    }

    function stopPool(uint256 pid) public onlyOwner {
        uint256 poolIndex = pid.sub(1);
        pools[poolIndex].IsActived = false;
        pools[poolIndex].IsStoped = true;

        pools[poolIndex].StopDate = block.timestamp;
    }

    function activePool(uint256 pid) public onlyOwner {
        uint256 poolIndex = pid.sub(1);
        pools[poolIndex].IsActived = true;
        pools[poolIndex].IsStoped = false;

        pools[poolIndex].StopDate = 0;
    }

    //withdraw contract token
    //use for someone send token to contract
    //recuse wrong user

    function withdrawErc20(IERC20 token) public onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    //withdraw ETH after IDO
    function withdrawPoolFund() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough fund");
        ReceiveToken.transfer(balance);
    }

    function purchaseIDO(uint256 pid) public payable nonReentrant {
        uint256 poolIndex = pid.sub(1);

        require(
            pools[poolIndex].IsActived && !pools[poolIndex].IsStoped,
            "invalid pool"
        );
        require(
            block.timestamp >= pools[poolIndex].Begin &&
                block.timestamp <= pools[poolIndex].End,
            "invalid time"
        );
        //check user
        require(
            whitelist[pid][msg.sender].IsWhitelist &&
                whitelist[pid][msg.sender].IsActived,
            "invalid user"
        );

        //check amount
        uint256 ethAmount = msg.value;
        uint256 tokenAmount =
            ethAmount.mul(pools[poolIndex].RatePerETH).div(1e18);

        require(
            ethAmount <= pools[poolIndex].MaxPurchase,
            "invalid maximum contribute"
        );

        whitelist[pid][msg.sender].TotalETHPurchase = whitelist[pid][msg.sender]
            .TotalETHPurchase
            .add(ethAmount);
        if (
            whitelist[pid][msg.sender].TotalETHPurchase >
            pools[poolIndex].MaxPurchase
        ) {
            revert("invalid maximum contribute"); //already revert state
        }

        uint256 remainToken = getRemainIDOToken(pid);
        require(
            remainToken > pools[poolIndex].MinimumTokenSoldout,
            "IDO sold out"
        );
        require(remainToken >= tokenAmount, "IDO sold out");

        if (pools[poolIndex].Type == 2) //private, check hold PBR
        {
            require(
                polkaBridgeToken.balanceOf(msg.sender) >=
                    pools[poolIndex].AmountPBRRequire,
                "must hold enough PBR"
            );
        }

       

        whitelist[pid][msg.sender].TotalTokenPurchase = whitelist[pid][
            msg.sender
        ]
            .TotalTokenPurchase
            .add(tokenAmount);

        pools[poolIndex].TotalSold = pools[poolIndex].TotalSold.add(
            tokenAmount
        );
    }

    function claimToken(uint256 pid) public nonReentrant {
        require(!whitelist[pid][msg.sender].IsClaimed, "user already claimed");
        uint256 poolIndex = pid.sub(1);

        require(
            block.timestamp >=
                pools[poolIndex].End.add(pools[poolIndex].LockDuration),
            "not on time for claiming token"
        );

        uint256 userBalance = getUserTotalPurchase(pid);

        require(userBalance > 0, "invalid claim");

        pools[poolIndex].IDOToken.transfer(msg.sender, userBalance);
        whitelist[pid][msg.sender].IsClaimed = true;
    }

    function getUserTotalPurchase(uint256 pid) public view returns (uint256) {
        return whitelist[pid][msg.sender].TotalTokenPurchase;
    }

    function getRemainIDOToken(uint256 pid) public view returns (uint256) {
        uint256 poolIndex = pid.sub(1);
        uint256 tokenBalance = getBalanceTokenByPoolId(pid);
        if (pools[poolIndex].TotalSold > tokenBalance) {
            return 0;
        }

        return tokenBalance.sub(pools[poolIndex].TotalSold);
    }

    function getBalanceTokenByPoolId(uint256 pid)
        public
        view
        returns (uint256)
    {
        uint256 poolIndex = pid.sub(1);
        //return pools[poolIndex].IDOToken.balanceOf(address(this));
        return pools[poolIndex].TotalToken;
    }

    function getPoolInfo(uint256 pid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            IERC20
        )
    {
        uint256 poolIndex = pid.sub(1);
        return (
            pools[poolIndex].Begin,
            pools[poolIndex].End,
            pools[poolIndex].Type,
            pools[poolIndex].AmountPBRRequire,
            pools[poolIndex].MaxPurchase,
            pools[poolIndex].RatePerETH,
            pools[poolIndex].LockDuration,
            pools[poolIndex].TotalSold,
            pools[poolIndex].IsActived,
            pools[poolIndex].IDOToken
        );
    }

    function getPoolSoldInfo(uint256 pid)
        public
        view
        returns (uint256, uint256)
    {
        uint256 poolIndex = pid.sub(1);
        return (pools[poolIndex].LockDuration, pools[poolIndex].TotalSold);
    }

    function getWhitelistfo(uint256 pid)
        public
        view
        returns (
            address,
            bool,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            whitelist[pid][msg.sender].UserAddress,
            whitelist[pid][msg.sender].IsWhitelist,
            whitelist[pid][msg.sender].WhitelistDate,
            whitelist[pid][msg.sender].TotalTokenPurchase,
            whitelist[pid][msg.sender].TotalETHPurchase,
            whitelist[pid][msg.sender].IsClaimed
        );
    }

    function getUserInfo(uint256 pid, address user)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            whitelist[pid][user].IsWhitelist,
            whitelist[pid][user].WhitelistDate,
            whitelist[pid][user].TotalTokenPurchase,
            whitelist[pid][user].TotalETHPurchase,
            whitelist[pid][user].IsClaimed
        );
    }
}