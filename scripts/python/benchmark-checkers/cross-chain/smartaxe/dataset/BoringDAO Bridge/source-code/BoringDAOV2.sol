// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interface/IBoringDAO.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IAddressResolver.sol";
import "./interface/ITunnel.sol";
import "./ParamBook.sol";
import "./lib/SafeDecimalMath.sol";
import "./interface/IMintProposal.sol";
import "./interface/IOracle.sol";
import "./interface/ITrusteeFeePool.sol";

/**
@notice The BoringDAO contract is the entrance to the entire system, 
providing the functions of pledge BOR, redeem BOR, mint bBTC, and destroy bBTC
 */
contract BoringDAOV2 is AccessControl, IBoringDAO, Pausable {
    using SafeDecimalMath for uint256;
    using SafeMath for uint256;

    uint256 public amountByMint=12250000e18;

    bytes32 public constant MONITOR_ROLE = "MONITOR_ROLE ";
    bytes32 public constant GOV_ROLE = "GOV_ROLE";

    // bor => boring
    bytes32 public constant BOR = "BORING";
    bytes32 public constant PARAM_BOOK = "ParamBook";
    bytes32 public constant MINT_PROPOSAL = "MintProposal";
    bytes32 public constant ORACLE = "Oracle";
    bytes32 public constant TRUSTEE_FEE_POOL = "TrusteeFeePool";
    bytes32 public constant OTOKEN = "oToken";

    bytes32 public constant TUNNEL_MINT_FEE_RATE = "mint_fee";
    bytes32 public constant NETWORK_FEE = "network_fee";

    IAddressResolver public addrReso;

    // tunnels
    ITunnelV2[] public tunnels;

    uint256 public mintCap;

    address public mine;

    // The user may not provide the Ethereum address or the format of the Ethereum address is wrong when mint. 
    // this is for a transaction
    mapping(string=>bool) public approveFlag;

    uint public reductionAmount=100000000e18;
    mapping(bytes32=>uint) public minMintAmount;

    constructor(IAddressResolver _addrReso, uint _mintCap, address _mine) public {
        // set up resolver
        addrReso = _addrReso;
        mintCap = _mintCap;
        mine = _mine;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MONITOR_ROLE, msg.sender);
    }


    function tunnel(bytes32 tunnelKey) internal view returns (ITunnel) {
        return ITunnel(addrReso.key2address(tunnelKey));
    }

    function otoken(bytes32 _tunnelKey) internal view returns (IERC20) {
        return IERC20(addrReso.requireKKAddrs(_tunnelKey, OTOKEN, "oToken not exist"));
    }

    function borERC20() internal view returns (IERC20) {
        return IERC20(addrReso.key2address(BOR));
    }

    function paramBook() internal view returns (ParamBook) {
        return ParamBook(addrReso.key2address(PARAM_BOOK));
    }

    function mintProposal() internal view returns (IMintProposal) {
        return IMintProposal(addrReso.key2address(MINT_PROPOSAL));
    }

    function oracle() internal view returns (IOracle) {
        return IOracle(addrReso.key2address(ORACLE));
    }

    // trustee fee pool key
    function trusteeFeePool(bytes32 _tunnelKey) internal view returns (ITrusteeFeePool) {
        return ITrusteeFeePool(addrReso.requireKKAddrs(_tunnelKey, TRUSTEE_FEE_POOL, "BoringDAO::TrusteeFeePool is address(0)"));
    }

    // trustee fee pool key => tfpk
    function addTrustee(address account, bytes32 _tunnelKey) public onlyAdmin {
        _setupRole(_tunnelKey, account);
        trusteeFeePool(_tunnelKey).enter(account);

    }

    function addTrustees(address[] memory accounts, bytes32 _tunnelKey) external onlyAdmin{
        for (uint256 i = 0; i < accounts.length; i++) {
            addTrustee(accounts[i], _tunnelKey);
        }
    }

    function removeTrustee(address account, bytes32 _tunnelKey) public onlyAdmin {
        revokeRole(_tunnelKey, account);
        trusteeFeePool(_tunnelKey).exit(account);
    }

    function setMine(address _mine) public onlyAdmin {
        mine = _mine;
    }

    function setMintCap(uint256 amount) public onlyAdmin {
        mintCap = amount;
    }

    function setMinMintAmount(bytes32 _tunnelKey, uint _amount) public onlyAdmin {
        minMintAmount[_tunnelKey] = _amount;
    }

    /**
    @notice tunnelKey is byte32("symbol"), eg. bytes32("BTC")
     */
    function pledge(bytes32 _tunnelKey, uint256 _amount)
        public
        override
        whenNotPaused
        whenContractExist(_tunnelKey)
    {
        require(
            borERC20().allowance(msg.sender, address(this)) >= _amount,
            "not allow enough boring"
        );

        borERC20().transferFrom(
            msg.sender,
            address(tunnel(_tunnelKey)),
            _amount
        );
        tunnel(_tunnelKey).pledge(msg.sender, _amount);
    }

    /**
    @notice redeem bor from tunnel
     */
    function redeem(bytes32 _tunnelKey, uint256 _amount)
        public
        override
        whenNotPaused
        whenContractExist(_tunnelKey)
    {
        tunnel(_tunnelKey).redeem(msg.sender, _amount);
    }

    function burnBToken(bytes32 _tunnelKey, uint256 amount, string memory assetAddress)
        public
        override
        whenNotPaused
        whenContractExist(_tunnelKey)
        whenTunnelNotPause(_tunnelKey)
    {
        tunnel(_tunnelKey).burn(msg.sender, amount, assetAddress);
    }

    /**
    @notice trustee will call the function to approve mint bToken
    @param _txid the transaction id of bitcoin
    @param _amount the amount to mint, 1BTC = 1bBTC = 1*10**18 weibBTC
    @param to mint to the address
     */
    function approveMint(
        bytes32 _tunnelKey,
        string memory _txid,
        uint256 _amount,
        address to,
        string memory assetAddress
    ) public override whenNotPaused whenTunnelNotPause(_tunnelKey) onlyTrustee(_tunnelKey) shouldMoreThan(_tunnelKey, _amount){
        if(to == address(0)) {
            if (approveFlag[_txid] == false) {
                approveFlag[_txid] = true;
                emit ETHAddressNotExist(_tunnelKey, _txid, _amount, to, msg.sender, assetAddress);
            }
            return;
        }
        
        uint256 trusteeCount = getRoleMemberCount(_tunnelKey);
        bool shouldMint = mintProposal().approve(
            _tunnelKey,
            _txid,
            _amount,
            to,
            msg.sender,
            trusteeCount
        );
        if (!shouldMint) {
            return;
        }
        uint256 canIssueAmount = tunnel(_tunnelKey).canIssueAmount();
        if (_amount.add(otoken(_tunnelKey).totalSupply()) > canIssueAmount) {
            emit NotEnoughPledgeValue(
                _tunnelKey,
                _txid,
                _amount,
                to,
                msg.sender,
                assetAddress
            );
            return;
        }
        // fee calculate in tunnel
        tunnel(_tunnelKey).issue(to, _amount);

        uint borMintAmount = calculateMintBORAmount(_tunnelKey, _amount);
        if(borMintAmount != 0) {
            amountByMint = amountByMint.add(borMintAmount);
            borERC20().transferFrom(mine, to, borMintAmount);
        }
        emit ApproveMintSuccess(_tunnelKey, _txid, _amount, to, assetAddress);
    }

    function calculateMintBORAmount(bytes32 _tunnelKey, uint _amount) public view returns (uint) {
        if (amountByMint >= mintCap || _amount == 0) {
            return 0;
        }
        uint256 assetPrice = oracle().getPrice(_tunnelKey);
        uint256 borPrice = oracle().getPrice(BOR);
        uint256 reductionTimes = amountByMint.div(reductionAmount);
        uint256 mintFeeRate = paramBook().params2(
            _tunnelKey,
            TUNNEL_MINT_FEE_RATE
        );
        // for decimal calculation, so mul 1e18
        uint256 reductionFactor = (4**reductionTimes).mul(1e18).div(5**reductionTimes);
        uint networkFee = paramBook().params2(_tunnelKey, NETWORK_FEE);
        uint baseAmount = _amount.multiplyDecimalRound(mintFeeRate).mul(2).add(networkFee);
        uint borAmount = assetPrice.multiplyDecimalRound(baseAmount).multiplyDecimalRound(reductionFactor).divideDecimalRound(borPrice);
        if (amountByMint.add(borAmount) >= mintCap) {
            borAmount = mintCap.sub(amountByMint);
        }
        return borAmount;
    }

    function pause() public onlyMonitor{
        _pause();
    }

    function unpause() public onlyMonitor{
        _unpause();
    }

    modifier onlyTrustee(bytes32 _tunnelKey) {
        require(hasRole(_tunnelKey, msg.sender), "Caller is not trustee");
        _;
    }

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BoringDAO::caller is not admin");
        _;
    }

    modifier onlyMonitor {
        require(
            hasRole(MONITOR_ROLE, msg.sender),
            "Caller is not monitor"
        );
        _;
    }

    modifier whenContractExist(bytes32 key) {
        require(
            addrReso.key2address(key) != address(0),
            "Contract not exist"
        );
        _;
    }

    modifier whenTunnelNotPause(bytes32 _tunnelKey) {
        address tunnelAddress = addrReso.requireAndKey2Address(_tunnelKey, "tunnel not exist");
        require(IPaused(tunnelAddress).paused() == false, "tunnel is paused");
        _;
    }

    modifier shouldMoreThan(bytes32 _tunnelKey, uint amount) {
        require(amount >= minMintAmount[_tunnelKey], "Mint Amount should more than min amount");
        _;
    }

    event NotEnoughPledgeValue(
        bytes32 indexed _tunnelKey,
        string indexed _txid,
        uint256 _amount,
        address to,
        address trustee,
        string assetAddress
    );

    event ApproveMintSuccess(
        bytes32 _tunnelKey,
        string _txid,
        uint256 _amount,
        address to,
        string assetAddress
    );

    event ETHAddressNotExist(
        bytes32 _tunnelKey,
        string _txid,
        uint256 _amount,
        address to,
        address trustee,
        string assetAddress
    );

    event NotEnoughMintAmount(
        bytes32 indexed _tunnelKey,
        string indexed _txid,
        uint256 _amount,
        address to,
        address trustee,
        string assetAddress
    );

   
}

interface IPaused {
    function paused() external view returns (bool);
}