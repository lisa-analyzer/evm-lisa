// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../oz/utils/structs/EnumerableSet.sol";
import "../oz/access/Ownable.sol";
import "../oz/token/ERC20/ERC20.sol";
import "../oz/token/ERC20/IERC20.sol";
import "../oz/token/ERC20/utils/SafeERC20.sol";
import "../oz/token/ERC721/utils/ERC721Holder.sol";
import '../oz/token/ERC721/IERC721.sol';
import "../oz/utils/math/SafeMath.sol";
import "./GenToken.sol";


interface IProxy {
    function bonus(address user) external view returns (uint);
    function getNFTPowerBonusBlocks(uint nftId) external view returns (uint);
    function getNFTPowerBonus() external view returns (uint);
    function downgradeMyNFT(uint nftId) external;
}

interface IGenNFT is IERC721 {
    function changeType(uint tokenId, uint toTypeId) external;
}

contract MasterChef is Ownable, ERC721Holder {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    
    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 power;          // User power
        uint lastPoweredBlock;  // last powered Block
        uint lastClaimedBlock;  // last powered Block
    }
    
    IProxy proxy;

    // Info of each pool.
    struct PoolInfo {
        uint256 totalPower;
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Gens to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Gens distribution occurs.
        uint256 accGenPerPower;   // Accumulated Gens per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    GenToken public gen;
    IERC20 public busd;
    address public busdGenLP;
    IGenNFT public nft;
    // Dev address.
    address public devaddr;
    // GEN tokens created per block.
    uint256 public genPerBlock;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Gen mining starts.
    uint256 public startBlock;
    
    uint public topPrice = 100; // 10$
    uint public bottomPrice = 10; //100$
    uint public lastBlockUpdate = 0;
    uint public emissionUpdateInterval = 3600; // 3 hours

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        GenToken _gen,
        IERC20 _busd,
        IGenNFT _nft,
        address _busdGenLP,
        IProxy _proxy,
        address _devaddr,
        address _feeAddress,
        uint256 _genPerBlock,
        uint256 _startBlock
    ) public {
        require(_devaddr != address(0), "address can't be 0");
        require(_feeAddress != address(0), "address can't be 0");
        
        gen = _gen;
        busd = _busd;
        nft = _nft;
        busdGenLP = _busdGenLP;
        devaddr = _devaddr;
        proxy = _proxy;
        feeAddress = _feeAddress;
        genPerBlock = _genPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            totalPower:0,
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accGenPerPower: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's GEN allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // View function to see pending GENs on frontend.
    function pendingGen(uint256 _pid, address _user) external view returns (uint256) {
        return _pendingGen(_pid, _user);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.totalPower == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blockAmount = block.number.sub(pool.lastRewardBlock);
        uint256 genReward = blockAmount.mul(genPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        gen.mint(devaddr, genReward.div(10));
        gen.mint(address(this), genReward);
        pool.accGenPerPower = pool.accGenPerPower.add(genReward.mul(1e12).div(pool.totalPower));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for GEN allocation.
    //1.lack of check for uodate power
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        claim(_pid);
        
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }
        //1.lack of check for uodate power
        updatePower(_pid);
        
        user.rewardDebt = user.power.mul(pool.accGenPerPower).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        
        updatePool(_pid);
        claim(_pid);
        
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        
        updatePower(_pid);
        
        user.rewardDebt = user.power.mul(pool.accGenPerPower).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }
    
    function powerUpWithNFTs(uint256 _pid, uint[] memory _nftIds) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        updatePool(_pid);
        claim(_pid);
        
        for (uint i =0; i < _nftIds.length; i++) {
            uint nftId = _nftIds[i];
            if (nft.ownerOf(nftId) == msg.sender) {
                if (user.lastPoweredBlock >= block.number) {
                    user.lastPoweredBlock += proxy.getNFTPowerBonusBlocks(nftId);
                } else {
                    user.lastPoweredBlock = block.number + proxy.getNFTPowerBonusBlocks(nftId); 
                }
                
                nft.changeType(nftId,0);
            }
        }
        
            
        updatePower(_pid);
    
        user.rewardDebt = user.power.mul(pool.accGenPerPower).div(1e12);
        emit Deposit(msg.sender, _pid, 1);
    }
    // CCV vulnerabilities functions
    function updatePower(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        uint256 currentPower = user.power;
        uint powerBonus = 100;
        
        if (user.lastPoweredBlock >= block.number) {
            powerBonus += proxy.getNFTPowerBonus();
        }
        powerBonus += proxy.bonus(msg.sender);
        
        user.power = user.amount.mul(powerBonus).div(100);
        
        pool.totalPower = pool.totalPower.add(user.power).sub(currentPower);
    }
    
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        pool.totalPower = pool.totalPower.sub(user.power);
        uint256 amount = user.amount;
        user.power = 0;
        user.amount = 0;
        user.rewardDebt = 0;

        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
    
     function claim(uint256 _pid) internal {
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        user.lastClaimedBlock = block.number;
        
        if (user.amount > 0) {
            uint256 pending = _pendingGen(_pid, msg.sender);
            
            if (pending > 0) {
                safeGenTransfer(msg.sender, pending);
            }
        }
        updateEmissionIfNeeded();
    }
    
     function _pendingGen(uint256 _pid, address _user) internal view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGenPerPower = pool.accGenPerPower;
        
        
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0 && pool.totalPower != 0) {
            uint256 blockAmount = block.number.sub(pool.lastRewardBlock);
            uint256 genReward = blockAmount.mul(genPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accGenPerPower = accGenPerPower.add(genReward.mul(1e12).div(pool.totalPower));
        }
        
        if ((user.lastClaimedBlock < user.lastPoweredBlock) && (block.number > user.lastPoweredBlock) && (user.power > 0)) {
            uint powerBonus = 100;
            
            powerBonus += proxy.getNFTPowerBonus() * (user.lastPoweredBlock - user.lastClaimedBlock) / (block.number - user.lastClaimedBlock);
            powerBonus += proxy.bonus(msg.sender);
        
            uint truePower = user.amount.mul(powerBonus).div(100);
            return user.power.mul(accGenPerPower).div(1e12).sub(user.rewardDebt) * truePower / user.power;
        }
        
        return user.power.mul(accGenPerPower).div(1e12).sub(user.rewardDebt);
    }

    // Safe gen transfer function, just in case if rounding error causes pool to not have enough GENs.
    function safeGenTransfer(address _to, uint256 _amount) internal {
        uint256 genBal = gen.balanceOf(address(this));
        if (_amount > genBal) {
            gen.transfer(_to, genBal);
        } else {
            gen.transfer(_to, _amount);
        }
    }
    
    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) public{
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _genPerBlock) public onlyOwner {
        massUpdatePools();
        genPerBlock = _genPerBlock;
    }

    function updateEmissionIfNeeded() public {
        if (block.number - lastBlockUpdate > emissionUpdateInterval) { //every 3 hours
             lastBlockUpdate = block.number;
             
             uint genBalance = gen.balanceOf(busdGenLP);
             uint priceCents = bottomPrice * 100;
             if (genBalance > 0) {
                massUpdatePools();
                priceCents = busd.balanceOf(busdGenLP).mul(100).div(genBalance);    
             }

             if (priceCents < bottomPrice * 100) {
                massUpdatePools();
                genPerBlock = priceCents.mul(1e18).div(bottomPrice).div(100);
             } else
             if (priceCents > topPrice * 100) {
                 massUpdatePools();
                genPerBlock = priceCents.mul(1e18).div(topPrice).div(100);
             } else if (genPerBlock != 1e18) {
                 massUpdatePools();
                 genPerBlock = 1e18;
             }
        }
    }
    
    function updateEmissionParameters(uint _topPrice, uint _bottomPrice, uint _emissionUpdateInterval) public onlyOwner {
        topPrice = _topPrice;
        bottomPrice = _bottomPrice;
        emissionUpdateInterval = _emissionUpdateInterval;
    }
    
    function setProxy(IProxy _proxy) public onlyOwner {
        proxy = _proxy;
    }
}