/**
 *Submitted for verification at Etherscan.io on 2020-03-25
*/

/**

Deployed by Ren Project, https://renproject.io

Commit hash: 9068f80
Repository: https://github.com/renproject/darknode-sol
Issues: https://github.com/renproject/darknode-sol/issues

Licenses
@openzeppelin/contracts: (MIT) https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/LICENSE
darknode-sol: (GNU GPL V3) https://github.com/renproject/darknode-sol/blob/master/LICENSE

*/

pragma solidity 0.5.16;


contract Proxy {
  
  function () payable external {
    _fallback();
  }

  
  function _implementation() internal view returns (address);

  
  function _delegate(address implementation) internal {
    assembly {
      
      
      
      calldatacopy(0, 0, calldatasize)

      
      
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

      
      returndatacopy(0, 0, returndatasize)

      switch result
      
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

  
  function _willFallback() internal {
  }

  
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

library OpenZeppelinUpgradesAddress {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        
        
        
        
        
        
        
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract BaseUpgradeabilityProxy is Proxy {
  
  event Upgraded(address indexed implementation);

  
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  
  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  
  function _setImplementation(address newImplementation) internal {
    require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}

contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  
  event AdminChanged(address previousAdmin, address newAdmin);

  

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  
  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  
  function _willFallback() internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    super._willFallback();
  }
}

contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}

contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {
  
  function initialize(address _logic, address _admin, bytes memory _data) public payable {
    require(_implementation() == address(0));
    InitializableUpgradeabilityProxy.initialize(_logic, _data);
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
}

contract Initializable {

  
  bool private initialized;

  
  bool private initializing;

  
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  
  function isConstructor() private view returns (bool) {
    
    
    
    
    
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  
  uint256[50] private ______gap;
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context is Initializable {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    uint256[50] private ______gap;
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        
        
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        
        
        
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        
        

        
        
        
        
        
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library Math {
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library ERC20WithFees {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    
    
    function safeTransferFromWithFees(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal returns (uint256) {
        uint256 balancesBefore = token.balanceOf(to);
        token.safeTransferFrom(from, to, value);
        uint256 balancesAfter = token.balanceOf(to);
        return Math.min(value, balancesAfter.sub(balancesBefore));
    }
}

contract ERC20Detailed is Initializable, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    
    function initialize(string memory name, string memory symbol, uint8 decimals) public initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    
    function name() public view returns (string memory) {
        return _name;
    }

    
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[50] private ______gap;
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract PauserRole is Initializable, Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    function initialize(address sender) public initializer {
        if (!isPauser(sender)) {
            _addPauser(sender);
        }
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }

    uint256[50] private ______gap;
}

contract Pausable is Initializable, Context, PauserRole {
    
    event Paused(address account);

    
    event Unpaused(address account);

    bool private _paused;

    
    function initialize(address sender) public initializer {
        PauserRole.initialize(sender);

        _paused = false;
    }

    
    function paused() public view returns (bool) {
        return _paused;
    }

    
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[50] private ______gap;
}

contract ERC20Pausable is Initializable, ERC20, Pausable {
    function initialize(address sender) public initializer {
        Pausable.initialize(sender);
    }

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    uint256[50] private ______gap;
}

contract ERC20Burnable is Initializable, Context, ERC20 {
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }

    uint256[50] private ______gap;
}

contract RenToken is Ownable, ERC20Detailed, ERC20Pausable, ERC20Burnable {
    string private constant _name = "REN";
    string private constant _symbol = "REN";
    uint8 private constant _decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1000000000 *
        10**uint256(_decimals);

    
    constructor() public {
        ERC20Pausable.initialize(msg.sender);
        ERC20Detailed.initialize(_name, _symbol, _decimals);
        Ownable.initialize(msg.sender);
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function transferTokens(address beneficiary, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        
        
        require(amount > 0);

        _transfer(msg.sender, beneficiary, amount);
        emit Transfer(msg.sender, beneficiary, amount);

        return true;
    }
}

contract Claimable is Initializable, Ownable {
    address public pendingOwner;

    function initialize(address _nextOwner) public initializer {
        Ownable.initialize(_nextOwner);
    }

    modifier onlyPendingOwner() {
        require(
            _msgSender() == pendingOwner,
            "Claimable: caller is not the pending owner"
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != owner() && newOwner != pendingOwner,
            "Claimable: invalid new owner"
        );
        pendingOwner = newOwner;
    }

    function claimOwnership() public onlyPendingOwner {
        _transferOwnership(pendingOwner);
        delete pendingOwner;
    }
}

library LinkedList {

    
    address public constant NULL = address(0);

    
    struct Node {
        bool inList;
        address previous;
        address next;
    }

    
    struct List {
        mapping (address => Node) list;
    }

    
    function insertBefore(List storage self, address target, address newNode) internal {
        require(newNode != address(0), "LinkedList: invalid address");
        require(!isInList(self, newNode), "LinkedList: already in list");
        require(isInList(self, target) || target == NULL, "LinkedList: not in list");

        
        address prev = self.list[target].previous;

        self.list[newNode].next = target;
        self.list[newNode].previous = prev;
        self.list[target].previous = newNode;
        self.list[prev].next = newNode;

        self.list[newNode].inList = true;
    }

    
    function insertAfter(List storage self, address target, address newNode) internal {
        require(newNode != address(0), "LinkedList: invalid address");
        require(!isInList(self, newNode), "LinkedList: already in list");
        require(isInList(self, target) || target == NULL, "LinkedList: not in list");

        
        address n = self.list[target].next;

        self.list[newNode].previous = target;
        self.list[newNode].next = n;
        self.list[target].next = newNode;
        self.list[n].previous = newNode;

        self.list[newNode].inList = true;
    }

    
    function remove(List storage self, address node) internal {
        require(isInList(self, node), "LinkedList: not in list");
        
        address p = self.list[node].previous;
        address n = self.list[node].next;

        self.list[p].next = n;
        self.list[n].previous = p;

        
        
        self.list[node].inList = false;
        delete self.list[node];
    }

    
    function prepend(List storage self, address node) internal {
        

        insertBefore(self, begin(self), node);
    }

    
    function append(List storage self, address node) internal {
        

        insertAfter(self, end(self), node);
    }

    function swap(List storage self, address left, address right) internal {
        

        address previousRight = self.list[right].previous;
        remove(self, right);
        insertAfter(self, left, right);
        remove(self, left);
        insertAfter(self, previousRight, left);
    }

    function isInList(List storage self, address node) internal view returns (bool) {
        return self.list[node].inList;
    }

    
    function begin(List storage self) internal view returns (address) {
        return self.list[NULL].next;
    }

    
    function end(List storage self) internal view returns (address) {
        return self.list[NULL].previous;
    }

    function next(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "LinkedList: not in list");
        return self.list[node].next;
    }

    function previous(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "LinkedList: not in list");
        return self.list[node].previous;
    }

    function elements(List storage self, address _start, uint256 _count) internal view returns (address[] memory) {
        require(_count > 0, "LinkedList: invalid count");
        require(isInList(self, _start) || _start == address(0), "LinkedList: not in list");
        address[] memory elems = new address[](_count);

        
        uint256 n = 0;
        address nextItem = _start;
        if (nextItem == address(0)) {
            nextItem = begin(self);
        }

        while (n < _count) {
            if (nextItem == address(0)) {
                break;
            }
            elems[n] = nextItem;
            nextItem = next(self, nextItem);
            n += 1;
        }
        return elems;
    }
}

contract CanReclaimTokens is Claimable {
    using SafeERC20 for ERC20;

    mapping(address => bool) private recoverableTokensBlacklist;

    function initialize(address _nextOwner) public initializer {
        Claimable.initialize(_nextOwner);
    }

    function blacklistRecoverableToken(address _token) public onlyOwner {
        recoverableTokensBlacklist[_token] = true;
    }

    
    
    function recoverTokens(address _token) external onlyOwner {
        require(
            !recoverableTokensBlacklist[_token],
            "CanReclaimTokens: token is not recoverable"
        );

        if (_token == address(0x0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_token).safeTransfer(
                msg.sender,
                ERC20(_token).balanceOf(address(this))
            );
        }
    }
}

contract DarknodeRegistryStore is Claimable, CanReclaimTokens {
    using SafeMath for uint256;

    string public VERSION; 

    
    
    
    
    
    struct Darknode {
        
        
        
        
        address payable owner;
        
        
        
        uint256 bond;
        
        uint256 registeredAt;
        
        uint256 deregisteredAt;
        
        
        
        
        bytes publicKey;
    }

    
    mapping(address => Darknode) private darknodeRegistry;
    LinkedList.List private darknodes;

    
    RenToken public ren;

    
    
    
    
    constructor(string memory _VERSION, RenToken _ren) public {
        Claimable.initialize(msg.sender);
        CanReclaimTokens.initialize(msg.sender);
        VERSION = _VERSION;
        ren = _ren;
        blacklistRecoverableToken(address(ren));
    }

    
    
    
    
    
    
    
    
    
    function appendDarknode(
        address _darknodeID,
        address payable _darknodeOperator,
        uint256 _bond,
        bytes calldata _publicKey,
        uint256 _registeredAt,
        uint256 _deregisteredAt
    ) external onlyOwner {
        Darknode memory darknode = Darknode({
            owner: _darknodeOperator,
            bond: _bond,
            publicKey: _publicKey,
            registeredAt: _registeredAt,
            deregisteredAt: _deregisteredAt
        });
        darknodeRegistry[_darknodeID] = darknode;
        LinkedList.append(darknodes, _darknodeID);
    }

    
    function begin() external view onlyOwner returns (address) {
        return LinkedList.begin(darknodes);
    }

    
    
    function next(address darknodeID)
        external
        view
        onlyOwner
        returns (address)
    {
        return LinkedList.next(darknodes, darknodeID);
    }

    
    
    function removeDarknode(address darknodeID) external onlyOwner {
        uint256 bond = darknodeRegistry[darknodeID].bond;
        delete darknodeRegistry[darknodeID];
        LinkedList.remove(darknodes, darknodeID);
        require(
            ren.transfer(owner(), bond),
            "DarknodeRegistryStore: bond transfer failed"
        );
    }

    
    
    function updateDarknodeBond(address darknodeID, uint256 decreasedBond)
        external
        onlyOwner
    {
        uint256 previousBond = darknodeRegistry[darknodeID].bond;
        require(
            decreasedBond < previousBond,
            "DarknodeRegistryStore: bond not decreased"
        );
        darknodeRegistry[darknodeID].bond = decreasedBond;
        require(
            ren.transfer(owner(), previousBond.sub(decreasedBond)),
            "DarknodeRegistryStore: bond transfer failed"
        );
    }

    
    function updateDarknodeDeregisteredAt(
        address darknodeID,
        uint256 deregisteredAt
    ) external onlyOwner {
        darknodeRegistry[darknodeID].deregisteredAt = deregisteredAt;
    }

    
    function darknodeOperator(address darknodeID)
        external
        view
        onlyOwner
        returns (address payable)
    {
        return darknodeRegistry[darknodeID].owner;
    }

    
    function darknodeBond(address darknodeID)
        external
        view
        onlyOwner
        returns (uint256)
    {
        return darknodeRegistry[darknodeID].bond;
    }

    
    function darknodeRegisteredAt(address darknodeID)
        external
        view
        onlyOwner
        returns (uint256)
    {
        return darknodeRegistry[darknodeID].registeredAt;
    }

    
    function darknodeDeregisteredAt(address darknodeID)
        external
        view
        onlyOwner
        returns (uint256)
    {
        return darknodeRegistry[darknodeID].deregisteredAt;
    }

    
    function darknodePublicKey(address darknodeID)
        external
        view
        onlyOwner
        returns (bytes memory)
    {
        return darknodeRegistry[darknodeID].publicKey;
    }
}

interface IDarknodePaymentStore {}

interface IDarknodePayment {
    function changeCycle() external returns (uint256);
    function store() external view returns (IDarknodePaymentStore);
}

interface IDarknodeSlasher {}

contract DarknodeRegistryStateV1 {
    using SafeMath for uint256;

    string public VERSION; 

    
    
    
    struct Epoch {
        uint256 epochhash;
        uint256 blocktime;
    }

    uint256 public numDarknodes;
    uint256 public numDarknodesNextEpoch;
    uint256 public numDarknodesPreviousEpoch;

    
    uint256 public minimumBond;
    uint256 public minimumPodSize;
    uint256 public minimumEpochInterval;
    uint256 public deregistrationInterval;

    
    
    
    uint256 public nextMinimumBond;
    uint256 public nextMinimumPodSize;
    uint256 public nextMinimumEpochInterval;

    
    Epoch public currentEpoch;
    Epoch public previousEpoch;

    
    RenToken public ren;

    
    DarknodeRegistryStore public store;

    
    IDarknodePayment public darknodePayment;

    
    IDarknodeSlasher public slasher;
    IDarknodeSlasher public nextSlasher;
}

contract DarknodeRegistryLogicV1 is
    Claimable,
    CanReclaimTokens,
    DarknodeRegistryStateV1
{
    
    
    
    
    event LogDarknodeRegistered(
        address indexed _darknodeOperator,
        address indexed _darknodeID,
        uint256 _bond
    );

    
    
    
    event LogDarknodeDeregistered(
        address indexed _darknodeOperator,
        address indexed _darknodeID
    );

    
    
    
    event LogDarknodeRefunded(
        address indexed _darknodeOperator,
        address indexed _darknodeID,
        uint256 _amount
    );

    
    
    
    
    
    event LogDarknodeSlashed(
        address indexed _darknodeOperator,
        address indexed _darknodeID,
        address indexed _challenger,
        uint256 _percentage
    );

    
    event LogNewEpoch(uint256 indexed epochhash);

    
    event LogMinimumBondUpdated(
        uint256 _previousMinimumBond,
        uint256 _nextMinimumBond
    );
    event LogMinimumPodSizeUpdated(
        uint256 _previousMinimumPodSize,
        uint256 _nextMinimumPodSize
    );
    event LogMinimumEpochIntervalUpdated(
        uint256 _previousMinimumEpochInterval,
        uint256 _nextMinimumEpochInterval
    );
    event LogSlasherUpdated(
        address indexed _previousSlasher,
        address indexed _nextSlasher
    );
    event LogDarknodePaymentUpdated(
        IDarknodePayment indexed _previousDarknodePayment,
        IDarknodePayment indexed _nextDarknodePayment
    );

    
    modifier onlyDarknodeOperator(address _darknodeID) {
        require(
            store.darknodeOperator(_darknodeID) == msg.sender,
            "DarknodeRegistry: must be darknode owner"
        );
        _;
    }

    
    modifier onlyRefunded(address _darknodeID) {
        require(
            isRefunded(_darknodeID),
            "DarknodeRegistry: must be refunded or never registered"
        );
        _;
    }

    
    modifier onlyRefundable(address _darknodeID) {
        require(
            isRefundable(_darknodeID),
            "DarknodeRegistry: must be deregistered for at least one epoch"
        );
        _;
    }

    
    
    modifier onlyDeregisterable(address _darknodeID) {
        require(
            isDeregisterable(_darknodeID),
            "DarknodeRegistry: must be deregisterable"
        );
        _;
    }

    
    modifier onlySlasher() {
        require(
            address(slasher) == msg.sender,
            "DarknodeRegistry: must be slasher"
        );
        _;
    }

    
    
    modifier onlyDarknode(address _darknodeID) {
        require(
            isRegistered(_darknodeID),
            "DarknodeRegistry: invalid darknode"
        );
        _;
    }

    
    
    
    
    
    
    
    
    
    function initialize(
        string memory _VERSION,
        RenToken _renAddress,
        DarknodeRegistryStore _storeAddress,
        uint256 _minimumBond,
        uint256 _minimumPodSize,
        uint256 _minimumEpochIntervalSeconds,
        uint256 _deregistrationIntervalSeconds
    ) public initializer {
        Claimable.initialize(msg.sender);
        CanReclaimTokens.initialize(msg.sender);
        VERSION = _VERSION;

        store = _storeAddress;
        ren = _renAddress;

        minimumBond = _minimumBond;
        nextMinimumBond = minimumBond;

        minimumPodSize = _minimumPodSize;
        nextMinimumPodSize = minimumPodSize;

        minimumEpochInterval = _minimumEpochIntervalSeconds;
        nextMinimumEpochInterval = minimumEpochInterval;
        deregistrationInterval = _deregistrationIntervalSeconds;

        uint256 epochhash = uint256(blockhash(block.number - 1));
        currentEpoch = Epoch({
            epochhash: epochhash,
            blocktime: block.timestamp
        });
        emit LogNewEpoch(epochhash);
    }

    
    
    
    
    
    
    
    
    
    
    function register(address _darknodeID, bytes calldata _publicKey)
        external
        onlyRefunded(_darknodeID)
    {
        require(
            _darknodeID != address(0),
            "DarknodeRegistry: darknode address cannot be zero"
        );

        
        require(
            ren.transferFrom(msg.sender, address(store), minimumBond),
            "DarknodeRegistry: bond transfer failed"
        );

        
        store.appendDarknode(
            _darknodeID,
            msg.sender,
            minimumBond,
            _publicKey,
            currentEpoch.blocktime.add(minimumEpochInterval),
            0
        );

        numDarknodesNextEpoch = numDarknodesNextEpoch.add(1);

        
        emit LogDarknodeRegistered(msg.sender, _darknodeID, minimumBond);
    }

    
    
    
    
    
    
    function deregister(address _darknodeID)
        external
        onlyDeregisterable(_darknodeID)
        onlyDarknodeOperator(_darknodeID)
    {
        deregisterDarknode(_darknodeID);
    }

    
    
    
    function epoch() external {
        if (previousEpoch.blocktime == 0) {
            
            require(
                msg.sender == owner(),
                "DarknodeRegistry: not authorized to call first epoch"
            );
        }

        
        require(
            block.timestamp >= currentEpoch.blocktime.add(minimumEpochInterval),
            "DarknodeRegistry: epoch interval has not passed"
        );
        uint256 epochhash = uint256(blockhash(block.number - 1));

        
        previousEpoch = currentEpoch;
        currentEpoch = Epoch({
            epochhash: epochhash,
            blocktime: block.timestamp
        });

        
        numDarknodesPreviousEpoch = numDarknodes;
        numDarknodes = numDarknodesNextEpoch;

        
        if (nextMinimumBond != minimumBond) {
            minimumBond = nextMinimumBond;
            emit LogMinimumBondUpdated(minimumBond, nextMinimumBond);
        }
        if (nextMinimumPodSize != minimumPodSize) {
            minimumPodSize = nextMinimumPodSize;
            emit LogMinimumPodSizeUpdated(minimumPodSize, nextMinimumPodSize);
        }
        if (nextMinimumEpochInterval != minimumEpochInterval) {
            minimumEpochInterval = nextMinimumEpochInterval;
            emit LogMinimumEpochIntervalUpdated(
                minimumEpochInterval,
                nextMinimumEpochInterval
            );
        }
        if (nextSlasher != slasher) {
            slasher = nextSlasher;
            emit LogSlasherUpdated(address(slasher), address(nextSlasher));
        }
        if (address(darknodePayment) != address(0x0)) {
            darknodePayment.changeCycle();
        }

        
        emit LogNewEpoch(epochhash);
    }

    
    
    
    function transferStoreOwnership(DarknodeRegistryLogicV1 _newOwner)
        external
        onlyOwner
    {
        store.transferOwnership(address(_newOwner));
        _newOwner.claimStoreOwnership();
    }

    
    
    
    function claimStoreOwnership() external {
        store.claimOwnership();

        
        
        (
            numDarknodesPreviousEpoch,
            numDarknodes,
            numDarknodesNextEpoch
        ) = getDarknodeCountFromEpochs();
    }

    
    
    
    
    function updateDarknodePayment(IDarknodePayment _darknodePayment)
        external
        onlyOwner
    {
        require(
            address(_darknodePayment) != address(0x0),
            "DarknodeRegistry: invalid Darknode Payment address"
        );
        IDarknodePayment previousDarknodePayment = darknodePayment;
        darknodePayment = _darknodePayment;
        emit LogDarknodePaymentUpdated(
            previousDarknodePayment,
            darknodePayment
        );
    }

    
    
    
    function updateMinimumBond(uint256 _nextMinimumBond) external onlyOwner {
        
        nextMinimumBond = _nextMinimumBond;
    }

    
    
    function updateMinimumPodSize(uint256 _nextMinimumPodSize)
        external
        onlyOwner
    {
        
        nextMinimumPodSize = _nextMinimumPodSize;
    }

    
    
    function updateMinimumEpochInterval(uint256 _nextMinimumEpochInterval)
        external
        onlyOwner
    {
        
        nextMinimumEpochInterval = _nextMinimumEpochInterval;
    }

    
    
    
    function updateSlasher(IDarknodeSlasher _slasher) external onlyOwner {
        require(
            address(_slasher) != address(0),
            "DarknodeRegistry: invalid slasher address"
        );
        nextSlasher = _slasher;
    }

    
    
    
    
    
    function slash(address _guilty, address _challenger, uint256 _percentage)
        external
        onlySlasher
        onlyDarknode(_guilty)
    {
        require(_percentage <= 100, "DarknodeRegistry: invalid percent");

        
        if (isDeregisterable(_guilty)) {
            deregisterDarknode(_guilty);
        }

        uint256 totalBond = store.darknodeBond(_guilty);
        uint256 penalty = totalBond.div(100).mul(_percentage);
        uint256 challengerReward = penalty.div(2);
        uint256 darknodePaymentReward = penalty.sub(challengerReward);
        if (challengerReward > 0) {
            
            store.updateDarknodeBond(_guilty, totalBond.sub(penalty));

            
            require(
                address(darknodePayment) != address(0x0),
                "DarknodeRegistry: invalid payment address"
            );
            require(
                ren.transfer(
                    address(darknodePayment.store()),
                    darknodePaymentReward
                ),
                "DarknodeRegistry: reward transfer failed"
            );
            require(
                ren.transfer(_challenger, challengerReward),
                "DarknodeRegistry: reward transfer failed"
            );
        }

        emit LogDarknodeSlashed(
            store.darknodeOperator(_guilty),
            _guilty,
            _challenger,
            _percentage
        );
    }

    
    
    
    
    
    function refund(address _darknodeID) external onlyRefundable(_darknodeID) {
        address darknodeOperator = store.darknodeOperator(_darknodeID);

        
        uint256 amount = store.darknodeBond(_darknodeID);

        
        store.removeDarknode(_darknodeID);

        
        require(
            ren.transfer(darknodeOperator, amount),
            "DarknodeRegistry: bond transfer failed"
        );

        
        emit LogDarknodeRefunded(darknodeOperator, _darknodeID, amount);
    }

    
    
    function getDarknodeOperator(address _darknodeID)
        external
        view
        returns (address payable)
    {
        return store.darknodeOperator(_darknodeID);
    }

    
    
    function getDarknodeBond(address _darknodeID)
        external
        view
        returns (uint256)
    {
        return store.darknodeBond(_darknodeID);
    }

    
    
    function getDarknodePublicKey(address _darknodeID)
        external
        view
        returns (bytes memory)
    {
        return store.darknodePublicKey(_darknodeID);
    }

    
    
    
    
    
    
    
    
    
    
    function getDarknodes(address _start, uint256 _count)
        external
        view
        returns (address[] memory)
    {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodes;
        }
        return getDarknodesFromEpochs(_start, count, false);
    }

    
    
    function getPreviousDarknodes(address _start, uint256 _count)
        external
        view
        returns (address[] memory)
    {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodesPreviousEpoch;
        }
        return getDarknodesFromEpochs(_start, count, true);
    }

    
    
    
    function isPendingRegistration(address _darknodeID)
        public
        view
        returns (bool)
    {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        return registeredAt != 0 && registeredAt > currentEpoch.blocktime;
    }

    
    
    function isPendingDeregistration(address _darknodeID)
        public
        view
        returns (bool)
    {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return deregisteredAt != 0 && deregisteredAt > currentEpoch.blocktime;
    }

    
    function isDeregistered(address _darknodeID) public view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return deregisteredAt != 0 && deregisteredAt <= currentEpoch.blocktime;
    }

    
    
    
    function isDeregisterable(address _darknodeID) public view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        
        
        return isRegistered(_darknodeID) && deregisteredAt == 0;
    }

    
    
    
    function isRefunded(address _darknodeID) public view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return registeredAt == 0 && deregisteredAt == 0;
    }

    
    
    function isRefundable(address _darknodeID) public view returns (bool) {
        return
            isDeregistered(_darknodeID) &&
            store.darknodeDeregisteredAt(_darknodeID) <=
            (previousEpoch.blocktime - deregistrationInterval);
    }

    
    function isRegistered(address _darknodeID) public view returns (bool) {
        return isRegisteredInEpoch(_darknodeID, currentEpoch);
    }

    
    function isRegisteredInPreviousEpoch(address _darknodeID)
        public
        view
        returns (bool)
    {
        return isRegisteredInEpoch(_darknodeID, previousEpoch);
    }

    
    
    
    
    function isRegisteredInEpoch(address _darknodeID, Epoch memory _epoch)
        private
        view
        returns (bool)
    {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        bool registered = registeredAt != 0 && registeredAt <= _epoch.blocktime;
        bool notDeregistered = deregisteredAt == 0 ||
            deregisteredAt > _epoch.blocktime;
        
        
        return registered && notDeregistered;
    }

    
    
    
    
    
    function getDarknodesFromEpochs(
        address _start,
        uint256 _count,
        bool _usePreviousEpoch
    ) private view returns (address[] memory) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodes;
        }

        address[] memory nodes = new address[](count);

        
        uint256 n = 0;
        address next = _start;
        if (next == address(0)) {
            next = store.begin();
        }

        
        while (n < count) {
            if (next == address(0)) {
                break;
            }
            
            bool includeNext;
            if (_usePreviousEpoch) {
                includeNext = isRegisteredInPreviousEpoch(next);
            } else {
                includeNext = isRegistered(next);
            }
            if (!includeNext) {
                next = store.next(next);
                continue;
            }
            nodes[n] = next;
            next = store.next(next);
            n += 1;
        }
        return nodes;
    }

    
    function deregisterDarknode(address _darknodeID) private {
        address darknodeOperator = store.darknodeOperator(_darknodeID);

        
        store.updateDarknodeDeregisteredAt(
            _darknodeID,
            currentEpoch.blocktime.add(minimumEpochInterval)
        );
        numDarknodesNextEpoch = numDarknodesNextEpoch.sub(1);

        
        emit LogDarknodeDeregistered(darknodeOperator, _darknodeID);
    }

    function getDarknodeCountFromEpochs()
        private
        view
        returns (uint256, uint256, uint256)
    {
        
        uint256 nPreviousEpoch = 0;
        uint256 nCurrentEpoch = 0;
        uint256 nNextEpoch = 0;
        address next = store.begin();

        
        while (true) {
            
            if (next == address(0)) {
                break;
            }

            if (isRegisteredInPreviousEpoch(next)) {
                nPreviousEpoch += 1;
            }

            if (isRegistered(next)) {
                nCurrentEpoch += 1;
            }

            
            
            if (
                ((isRegistered(next) && !isPendingDeregistration(next)) ||
                    isPendingRegistration(next))
            ) {
                nNextEpoch += 1;
            }
            next = store.next(next);
        }
        return (nPreviousEpoch, nCurrentEpoch, nNextEpoch);
    }
}

contract DarknodeRegistryProxy is InitializableAdminUpgradeabilityProxy {}

contract DarknodePaymentStore is Claimable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using ERC20WithFees for ERC20;

    string public VERSION; 

    
    address public constant ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    
    mapping(address => mapping(address => uint256)) public darknodeBalances;

    
    mapping(address => uint256) public lockedBalances;

    
    
    
    constructor(string memory _VERSION) public {
        Claimable.initialize(msg.sender);
        VERSION = _VERSION;
    }

    
    function() external payable {}

    
    
    
    
    function totalBalance(address _token) public view returns (uint256) {
        if (_token == ETHEREUM) {
            return address(this).balance;
        } else {
            return ERC20(_token).balanceOf(address(this));
        }
    }

    
    
    
    
    
    
    function availableBalance(address _token) public view returns (uint256) {
        return
            totalBalance(_token).sub(
                lockedBalances[_token],
                "DarknodePaymentStore: locked balance exceed total balance"
            );
    }

    
    
    
    
    
    
    function incrementDarknodeBalance(
        address _darknode,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        require(_amount > 0, "DarknodePaymentStore: invalid amount");
        require(
            availableBalance(_token) >= _amount,
            "DarknodePaymentStore: insufficient contract balance"
        );

        darknodeBalances[_darknode][_token] = darknodeBalances[_darknode][_token]
            .add(_amount);
        lockedBalances[_token] = lockedBalances[_token].add(_amount);
    }

    
    
    
    
    
    
    function transfer(
        address _darknode,
        address _token,
        uint256 _amount,
        address payable _recipient
    ) external onlyOwner {
        require(
            darknodeBalances[_darknode][_token] >= _amount,
            "DarknodePaymentStore: insufficient darknode balance"
        );
        darknodeBalances[_darknode][_token] = darknodeBalances[_darknode][_token]
            .sub(
            _amount,
            "DarknodePaymentStore: insufficient darknode balance for transfer"
        );
        lockedBalances[_token] = lockedBalances[_token].sub(
            _amount,
            "DarknodePaymentStore: insufficient token balance for transfer"
        );

        if (_token == ETHEREUM) {
            _recipient.transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(_recipient, _amount);
        }
    }

}

contract DarknodePayment is Claimable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using ERC20WithFees for ERC20;

    string public VERSION; 

    
    address public constant ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    DarknodeRegistryLogicV1 public darknodeRegistry; 

    
    
    DarknodePaymentStore public store; 

    
    
    address public cycleChanger;

    uint256 public currentCycle;
    uint256 public previousCycle;

    
    
    
    address[] public pendingTokens;

    
    
    address[] public registeredTokens;

    
    
    mapping(address => uint256) public registeredTokenIndex;

    
    
    
    mapping(address => uint256) public unclaimedRewards;

    
    
    mapping(address => uint256) public previousCycleRewardShare;

    
    uint256 public cycleStartTime;

    
    uint256 public nextCyclePayoutPercent;

    
    uint256 public currentCyclePayoutPercent;

    
    
    
    mapping(address => mapping(uint256 => bool)) public rewardClaimed;

    
    
    
    event LogDarknodeClaim(address indexed _darknode, uint256 _cycle);

    
    
    
    
    event LogPaymentReceived(
        address indexed _payer,
        address indexed _token,
        uint256 _amount
    );

    
    
    
    
    
    event LogDarknodeWithdrew(
        address indexed _darknodeOperator,
        address indexed _darknodeID,
        address indexed _token,
        uint256 _value
    );

    
    
    
    event LogPayoutPercentChanged(uint256 _newPercent, uint256 _oldPercent);

    
    
    
    event LogCycleChangerChanged(
        address indexed _newCycleChanger,
        address indexed _oldCycleChanger
    );

    
    
    event LogTokenRegistered(address indexed _token);

    
    
    event LogTokenDeregistered(address indexed _token);

    
    
    
    event LogDarknodeRegistryUpdated(
        DarknodeRegistryLogicV1 indexed _previousDarknodeRegistry,
        DarknodeRegistryLogicV1 indexed _nextDarknodeRegistry
    );

    
    modifier onlyDarknode(address _darknode) {
        require(
            darknodeRegistry.isRegistered(_darknode),
            "DarknodePayment: darknode is not registered"
        );
        _;
    }

    
    modifier validPercent(uint256 _percent) {
        require(_percent <= 100, "DarknodePayment: invalid percentage");
        _;
    }

    
    modifier onlyCycleChanger {
        require(
            msg.sender == cycleChanger,
            "DarknodePayment: not cycle changer"
        );
        _;
    }

    
    
    
    
    
    
    
    constructor(
        string memory _VERSION,
        DarknodeRegistryLogicV1 _darknodeRegistry,
        DarknodePaymentStore _darknodePaymentStore,
        uint256 _cyclePayoutPercent
    ) public validPercent(_cyclePayoutPercent) {
        Claimable.initialize(msg.sender);
        VERSION = _VERSION;
        darknodeRegistry = _darknodeRegistry;
        store = _darknodePaymentStore;
        nextCyclePayoutPercent = _cyclePayoutPercent;
        
        cycleChanger = msg.sender;

        
        (currentCycle, cycleStartTime) = darknodeRegistry.currentEpoch();
        currentCyclePayoutPercent = nextCyclePayoutPercent;
    }

    
    
    
    
    function updateDarknodeRegistry(DarknodeRegistryLogicV1 _darknodeRegistry)
        external
        onlyOwner
    {
        require(
            address(_darknodeRegistry) != address(0x0),
            "DarknodePayment: invalid Darknode Registry address"
        );
        DarknodeRegistryLogicV1 previousDarknodeRegistry = darknodeRegistry;
        darknodeRegistry = _darknodeRegistry;
        emit LogDarknodeRegistryUpdated(
            previousDarknodeRegistry,
            darknodeRegistry
        );
    }

    
    
    
    
    
    function withdraw(address _darknode, address _token) public {
        address payable darknodeOperator = darknodeRegistry.getDarknodeOperator(
            _darknode
        );
        require(
            darknodeOperator != address(0x0),
            "DarknodePayment: invalid darknode owner"
        );

        uint256 amount = store.darknodeBalances(_darknode, _token);

        
        if (amount > 0) {
            store.transfer(_darknode, _token, amount, darknodeOperator);
            emit LogDarknodeWithdrew(
                darknodeOperator,
                _darknode,
                _token,
                amount
            );
        }
    }

    function withdrawMultiple(
        address[] calldata _darknodes,
        address[] calldata _tokens
    ) external {
        for (uint256 i = 0; i < _darknodes.length; i++) {
            for (uint256 j = 0; j < _tokens.length; j++) {
                withdraw(_darknodes[i], _tokens[j]);
            }
        }
    }

    
    function() external payable {
        address(store).transfer(msg.value);
        emit LogPaymentReceived(msg.sender, ETHEREUM, msg.value);
    }

    
    
    function currentCycleRewardPool(address _token)
        external
        view
        returns (uint256)
    {
        uint256 total = store.availableBalance(_token).sub(
            unclaimedRewards[_token],
            "DarknodePayment: unclaimed rewards exceed total rewards"
        );
        return total.div(100).mul(currentCyclePayoutPercent);
    }

    function darknodeBalances(address _darknodeID, address _token)
        external
        view
        returns (uint256)
    {
        return store.darknodeBalances(_darknodeID, _token);
    }

    
    function changeCycle() external onlyCycleChanger returns (uint256) {
        
        uint256 arrayLength = registeredTokens.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            _snapshotBalance(registeredTokens[i]);
        }

        
        previousCycle = currentCycle;
        (currentCycle, cycleStartTime) = darknodeRegistry.currentEpoch();
        currentCyclePayoutPercent = nextCyclePayoutPercent;

        
        _updateTokenList();
        return currentCycle;
    }

    
    
    
    
    function deposit(uint256 _value, address _token) external payable {
        uint256 receivedValue;
        if (_token == ETHEREUM) {
            require(
                _value == msg.value,
                "DarknodePayment: mismatched deposit value"
            );
            receivedValue = msg.value;
            address(store).transfer(msg.value);
        } else {
            require(
                msg.value == 0,
                "DarknodePayment: unexpected ether transfer"
            );
            require(
                registeredTokenIndex[_token] != 0,
                "DarknodePayment: token not registered"
            );
            
            receivedValue = ERC20(_token).safeTransferFromWithFees(
                msg.sender,
                address(store),
                _value
            );
        }
        emit LogPaymentReceived(msg.sender, _token, receivedValue);
    }

    
    
    
    
    function forward(address _token) external {
        if (_token == ETHEREUM) {
            
            
            
            
            address(store).transfer(address(this).balance);
        } else {
            ERC20(_token).safeTransfer(
                address(store),
                ERC20(_token).balanceOf(address(this))
            );
        }
    }

    
    
    function claim(address _darknode) external onlyDarknode(_darknode) {
        require(
            darknodeRegistry.isRegisteredInPreviousEpoch(_darknode),
            "DarknodePayment: cannot claim for this epoch"
        );
        
        _claimDarknodeReward(_darknode);
        emit LogDarknodeClaim(_darknode, previousCycle);
    }

    
    
    
    
    function registerToken(address _token) external onlyOwner {
        require(
            registeredTokenIndex[_token] == 0,
            "DarknodePayment: token already registered"
        );
        require(
            !tokenPendingRegistration(_token),
            "DarknodePayment: token already pending registration"
        );
        pendingTokens.push(_token);
    }

    function tokenPendingRegistration(address _token)
        public
        view
        returns (bool)
    {
        uint256 arrayLength = pendingTokens.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (pendingTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    
    
    
    
    function deregisterToken(address _token) external onlyOwner {
        require(
            registeredTokenIndex[_token] > 0,
            "DarknodePayment: token not registered"
        );
        _deregisterToken(_token);
    }

    
    
    
    function updateCycleChanger(address _addr) external onlyOwner {
        require(
            _addr != address(0),
            "DarknodePayment: invalid contract address"
        );
        emit LogCycleChangerChanged(_addr, cycleChanger);
        cycleChanger = _addr;
    }

    
    
    
    function updatePayoutPercentage(uint256 _percent)
        external
        onlyOwner
        validPercent(_percent)
    {
        uint256 oldPayoutPercent = nextCyclePayoutPercent;
        nextCyclePayoutPercent = _percent;
        emit LogPayoutPercentChanged(nextCyclePayoutPercent, oldPayoutPercent);
    }

    
    
    
    
    function transferStoreOwnership(DarknodePayment _newOwner)
        external
        onlyOwner
    {
        store.transferOwnership(address(_newOwner));
        _newOwner.claimStoreOwnership();
    }

    
    
    
    function claimStoreOwnership() external {
        store.claimOwnership();
    }

    
    
    
    
    
    function _claimDarknodeReward(address _darknode) private {
        require(
            !rewardClaimed[_darknode][previousCycle],
            "DarknodePayment: reward already claimed"
        );
        rewardClaimed[_darknode][previousCycle] = true;
        uint256 arrayLength = registeredTokens.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            address token = registeredTokens[i];

            
            if (previousCycleRewardShare[token] > 0) {
                unclaimedRewards[token] = unclaimedRewards[token].sub(
                    previousCycleRewardShare[token],
                    "DarknodePayment: share exceeds unclaimed rewards"
                );
                store.incrementDarknodeBalance(
                    _darknode,
                    token,
                    previousCycleRewardShare[token]
                );
            }
        }
    }

    
    
    
    
    function _snapshotBalance(address _token) private {
        uint256 shareCount = darknodeRegistry.numDarknodesPreviousEpoch();
        if (shareCount == 0) {
            unclaimedRewards[_token] = 0;
            previousCycleRewardShare[_token] = 0;
        } else {
            
            uint256 total = store.availableBalance(_token);
            unclaimedRewards[_token] = total.div(100).mul(
                currentCyclePayoutPercent
            );
            previousCycleRewardShare[_token] = unclaimedRewards[_token].div(
                shareCount
            );
        }
    }

    
    
    
    
    function _deregisterToken(address _token) private {
        address lastToken = registeredTokens[registeredTokens.length.sub(
            1,
            "DarknodePayment: no tokens registered"
        )];
        uint256 deletedTokenIndex = registeredTokenIndex[_token].sub(1);
        
        registeredTokens[deletedTokenIndex] = lastToken;
        registeredTokenIndex[lastToken] = registeredTokenIndex[_token];
        
        
        registeredTokens.pop();
        registeredTokenIndex[_token] = 0;

        emit LogTokenDeregistered(_token);
    }

    
    
    function _updateTokenList() private {
        
        uint256 arrayLength = pendingTokens.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            address token = pendingTokens[i];
            registeredTokens.push(token);
            registeredTokenIndex[token] = registeredTokens.length;
            emit LogTokenRegistered(token);
        }
        pendingTokens.length = 0;
    }

}

library ECDSA {
    
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        
        if (signature.length != 65) {
            revert("ECDSA: signature length is invalid");
        }

        
        bytes32 r;
        bytes32 s;
        uint8 v;

        
        
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        
        
        
        
        
        
        
        
        
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: signature.s is in the wrong range");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: signature.v is in the wrong range");
        }

        
        return ecrecover(hash, v, r, s);
    }

    
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        
        
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

library String {
    
    
    function fromUint(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    
    function fromBytes32(bytes32 _value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(32 * 2 + 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 32; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(_value[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(_value[i] & 0x0f))];
        }
        return string(str);
    }

    
    function fromAddress(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(20 * 2 + 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    
    function add8(
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e,
        string memory f,
        string memory g,
        string memory h
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e, f, g, h));
    }
}

library Compare {

    function bytesEqual(bytes memory a, bytes memory b) internal pure returns (bool) {
        if (a.length != b.length) {
            return false;
        }
        for (uint i = 0; i < a.length; i ++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }
}

library Validate {
    
    
    
    
    
    function duplicatePropose(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash1,
        uint256 _validRound1,
        bytes memory _signature1,
        bytes memory _blockhash2,
        uint256 _validRound2,
        bytes memory _signature2
    ) internal pure returns (address) {
        require(
            !Compare.bytesEqual(_signature1, _signature2),
            "Validate: same signature"
        );
        address signer1 = recoverPropose(
            _height,
            _round,
            _blockhash1,
            _validRound1,
            _signature1
        );
        address signer2 = recoverPropose(
            _height,
            _round,
            _blockhash2,
            _validRound2,
            _signature2
        );
        require(signer1 == signer2, "Validate: different signer");
        return signer1;
    }

    function recoverPropose(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash,
        uint256 _validRound,
        bytes memory _signature
    ) internal pure returns (address) {
        return
            ECDSA.recover(
                sha256(
                    proposeMessage(_height, _round, _blockhash, _validRound)
                ),
                _signature
            );
    }

    function proposeMessage(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash,
        uint256 _validRound
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "Propose(Height=",
                String.fromUint(_height),
                ",Round=",
                String.fromUint(_round),
                ",BlockHash=",
                string(_blockhash),
                ",ValidRound=",
                String.fromUint(_validRound),
                ")"
            );
    }

    
    
    
    
    
    function duplicatePrevote(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash1,
        bytes memory _signature1,
        bytes memory _blockhash2,
        bytes memory _signature2
    ) internal pure returns (address) {
        require(
            !Compare.bytesEqual(_signature1, _signature2),
            "Validate: same signature"
        );
        address signer1 = recoverPrevote(
            _height,
            _round,
            _blockhash1,
            _signature1
        );
        address signer2 = recoverPrevote(
            _height,
            _round,
            _blockhash2,
            _signature2
        );
        require(signer1 == signer2, "Validate: different signer");
        return signer1;
    }

    function recoverPrevote(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash,
        bytes memory _signature
    ) internal pure returns (address) {
        return
            ECDSA.recover(
                sha256(prevoteMessage(_height, _round, _blockhash)),
                _signature
            );
    }

    function prevoteMessage(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "Prevote(Height=",
                String.fromUint(_height),
                ",Round=",
                String.fromUint(_round),
                ",BlockHash=",
                string(_blockhash),
                ")"
            );
    }

    
    
    
    
    
    function duplicatePrecommit(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash1,
        bytes memory _signature1,
        bytes memory _blockhash2,
        bytes memory _signature2
    ) internal pure returns (address) {
        require(
            !Compare.bytesEqual(_signature1, _signature2),
            "Validate: same signature"
        );
        address signer1 = recoverPrecommit(
            _height,
            _round,
            _blockhash1,
            _signature1
        );
        address signer2 = recoverPrecommit(
            _height,
            _round,
            _blockhash2,
            _signature2
        );
        require(signer1 == signer2, "Validate: different signer");
        return signer1;
    }

    function recoverPrecommit(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash,
        bytes memory _signature
    ) internal pure returns (address) {
        return
            ECDSA.recover(
                sha256(precommitMessage(_height, _round, _blockhash)),
                _signature
            );
    }

    function precommitMessage(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "Precommit(Height=",
                String.fromUint(_height),
                ",Round=",
                String.fromUint(_round),
                ",BlockHash=",
                string(_blockhash),
                ")"
            );
    }

    function recoverSecret(
        uint256 _a,
        uint256 _b,
        uint256 _c,
        uint256 _d,
        uint256 _e,
        uint256 _f,
        bytes memory _signature
    ) internal pure returns (address) {
        return
            ECDSA.recover(
                sha256(secretMessage(_a, _b, _c, _d, _e, _f)),
                _signature
            );
    }

    function secretMessage(
        uint256 _a,
        uint256 _b,
        uint256 _c,
        uint256 _d,
        uint256 _e,
        uint256 _f
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "Secret(",
                "ShamirShare(",
                String.fromUint(_a),
                ",",
                String.fromUint(_b),
                ",S256N(",
                String.fromUint(_c),
                "),",
                "S256PrivKey(",
                "S256N(",
                String.fromUint(_d),
                "),",
                "S256P(",
                String.fromUint(_e),
                "),",
                "S256P(",
                String.fromUint(_f),
                ")",
                ")",
                ")",
                ")"
            );
    }
}

contract DarknodeSlasher is Claimable {
    DarknodeRegistryLogicV1 public darknodeRegistry;

    uint256 public blacklistSlashPercent;
    uint256 public maliciousSlashPercent;
    uint256 public secretRevealSlashPercent;

    
    
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public slashed;

    
    mapping(address => bool) public secretRevealed;

    
    mapping(address => bool) public blacklisted;

    
    
    
    event LogDarknodeRegistryUpdated(
        DarknodeRegistryLogicV1 indexed _previousDarknodeRegistry,
        DarknodeRegistryLogicV1 indexed _nextDarknodeRegistry
    );

    
    modifier validPercent(uint256 _percent) {
        require(_percent <= 100, "DarknodeSlasher: invalid percentage");
        _;
    }

    constructor(DarknodeRegistryLogicV1 _darknodeRegistry) public {
        Claimable.initialize(msg.sender);
        darknodeRegistry = _darknodeRegistry;
    }

    
    
    
    
    function updateDarknodeRegistry(DarknodeRegistryLogicV1 _darknodeRegistry)
        external
        onlyOwner
    {
        require(
            address(_darknodeRegistry) != address(0x0),
            "DarknodeSlasher: invalid Darknode Registry address"
        );
        DarknodeRegistryLogicV1 previousDarknodeRegistry = darknodeRegistry;
        darknodeRegistry = _darknodeRegistry;
        emit LogDarknodeRegistryUpdated(
            previousDarknodeRegistry,
            darknodeRegistry
        );
    }

    function setBlacklistSlashPercent(uint256 _percentage)
        public
        validPercent(_percentage)
        onlyOwner
    {
        blacklistSlashPercent = _percentage;
    }

    function setMaliciousSlashPercent(uint256 _percentage)
        public
        validPercent(_percentage)
        onlyOwner
    {
        maliciousSlashPercent = _percentage;
    }

    function setSecretRevealSlashPercent(uint256 _percentage)
        public
        validPercent(_percentage)
        onlyOwner
    {
        secretRevealSlashPercent = _percentage;
    }

    function slash(address _guilty, address _challenger, uint256 _percentage)
        external
        onlyOwner
    {
        darknodeRegistry.slash(_guilty, _challenger, _percentage);
    }

    function blacklist(address _guilty) external onlyOwner {
        require(!blacklisted[_guilty], "DarknodeSlasher: already blacklisted");
        blacklisted[_guilty] = true;
        darknodeRegistry.slash(_guilty, owner(), blacklistSlashPercent);
    }

    function slashDuplicatePropose(
        uint256 _height,
        uint256 _round,
        bytes calldata _blockhash1,
        uint256 _validRound1,
        bytes calldata _signature1,
        bytes calldata _blockhash2,
        uint256 _validRound2,
        bytes calldata _signature2
    ) external {
        address signer = Validate.duplicatePropose(
            _height,
            _round,
            _blockhash1,
            _validRound1,
            _signature1,
            _blockhash2,
            _validRound2,
            _signature2
        );
        require(
            !slashed[_height][_round][signer],
            "DarknodeSlasher: already slashed"
        );
        slashed[_height][_round][signer] = true;
        darknodeRegistry.slash(signer, msg.sender, maliciousSlashPercent);
    }

    function slashDuplicatePrevote(
        uint256 _height,
        uint256 _round,
        bytes calldata _blockhash1,
        bytes calldata _signature1,
        bytes calldata _blockhash2,
        bytes calldata _signature2
    ) external {
        address signer = Validate.duplicatePrevote(
            _height,
            _round,
            _blockhash1,
            _signature1,
            _blockhash2,
            _signature2
        );
        require(
            !slashed[_height][_round][signer],
            "DarknodeSlasher: already slashed"
        );
        slashed[_height][_round][signer] = true;
        darknodeRegistry.slash(signer, msg.sender, maliciousSlashPercent);
    }

    function slashDuplicatePrecommit(
        uint256 _height,
        uint256 _round,
        bytes calldata _blockhash1,
        bytes calldata _signature1,
        bytes calldata _blockhash2,
        bytes calldata _signature2
    ) external {
        address signer = Validate.duplicatePrecommit(
            _height,
            _round,
            _blockhash1,
            _signature1,
            _blockhash2,
            _signature2
        );
        require(
            !slashed[_height][_round][signer],
            "DarknodeSlasher: already slashed"
        );
        slashed[_height][_round][signer] = true;
        darknodeRegistry.slash(signer, msg.sender, maliciousSlashPercent);
    }

    function slashSecretReveal(
        uint256 _a,
        uint256 _b,
        uint256 _c,
        uint256 _d,
        uint256 _e,
        uint256 _f,
        bytes calldata _signature
    ) external {
        address signer = Validate.recoverSecret(
            _a,
            _b,
            _c,
            _d,
            _e,
            _f,
            _signature
        );
        require(!secretRevealed[signer], "DarknodeSlasher: already slashed");
        secretRevealed[signer] = true;
        darknodeRegistry.slash(signer, msg.sender, secretRevealSlashPercent);
    }
}

contract ERC20WithRate is Initializable, Ownable, ERC20 {
    using SafeMath for uint256;

    uint256 public constant _rateScale = 1e18;
    uint256 internal _rate;

    event LogRateChanged(uint256 indexed _rate);

    
    function initialize(address _nextOwner, uint256 _initialRate)
        public
        initializer
    {
        Ownable.initialize(_nextOwner);
        _setRate(_initialRate);
    }

    function setExchangeRate(uint256 _nextRate) public onlyOwner {
        _setRate(_nextRate);
    }

    function exchangeRateCurrent() public view returns (uint256) {
        require(_rate != 0, "ERC20WithRate: rate has not been initialized");
        return _rate;
    }

    function _setRate(uint256 _nextRate) internal {
        require(_nextRate > 0, "ERC20WithRate: rate must be greater than zero");
        _rate = _nextRate;
    }

    function balanceOfUnderlying(address _account)
        public
        view
        returns (uint256)
    {
        return toUnderlying(balanceOf(_account));
    }

    function toUnderlying(uint256 _amount) public view returns (uint256) {
        return _amount.mul(_rate).div(_rateScale);
    }

    function fromUnderlying(uint256 _amountUnderlying)
        public
        view
        returns (uint256)
    {
        return _amountUnderlying.mul(_rateScale).div(_rate);
    }
}

contract ERC20WithPermit is Initializable, ERC20, ERC20Detailed {
    using SafeMath for uint256;

    mapping(address => uint256) public nonces;

    
    
    string public version;

    
    bytes32 public DOMAIN_SEPARATOR;
    
    
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    function initialize(
        uint256 _chainId,
        string memory _version,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public initializer {
        ERC20Detailed.initialize(_name, _symbol, _decimals);
        version = _version;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes(version)),
                _chainId,
                address(this)
            )
        );
    }

    
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        holder,
                        spender,
                        nonce,
                        expiry,
                        allowed
                    )
                )
            )
        );

        require(holder != address(0), "ERC20WithRate: address must not be 0x0");
        require(
            holder == ecrecover(digest, v, r, s),
            "ERC20WithRate: invalid signature"
        );
        require(
            expiry == 0 || now <= expiry,
            "ERC20WithRate: permit has expired"
        );
        require(nonce == nonces[holder]++, "ERC20WithRate: invalid nonce");
        uint256 amount = allowed ? uint256(-1) : 0;
        _approve(holder, spender, amount);
    }
}

contract RenERC20LogicV1 is
    Initializable,
    ERC20,
    ERC20Detailed,
    ERC20WithRate,
    ERC20WithPermit,
    Claimable,
    CanReclaimTokens
{
    
    function initialize(
        uint256 _chainId,
        address _nextOwner,
        uint256 _initialRate,
        string memory _version,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public initializer {
        ERC20Detailed.initialize(_name, _symbol, _decimals);
        ERC20WithRate.initialize(_nextOwner, _initialRate);
        ERC20WithPermit.initialize(
            _chainId,
            _version,
            _name,
            _symbol,
            _decimals
        );
        Claimable.initialize(_nextOwner);
        CanReclaimTokens.initialize(_nextOwner);
    }

    
    
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    
    
    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        
        
        
        require(
            recipient != address(this),
            "RenERC20: can't transfer to token address"
        );
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        returns (bool)
    {
        
        
        require(
            recipient != address(this),
            "RenERC20: can't transfer to token address"
        );
        return super.transferFrom(sender, recipient, amount);
    }
}

contract RenBTC is InitializableAdminUpgradeabilityProxy {}

contract RenZEC is InitializableAdminUpgradeabilityProxy {}

contract RenBCH is InitializableAdminUpgradeabilityProxy {}

interface IMintGateway {
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);
    function mintFee() external view returns (uint256);
}

interface IBurnGateway {
    function burn(bytes calldata _to, uint256 _amountScaled)
        external
        returns (uint256);
    function burnFee() external view returns (uint256);
}

interface IGateway {
    
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);
    function mintFee() external view returns (uint256);
    
    function burn(bytes calldata _to, uint256 _amountScaled)
        external
        returns (uint256);
    function burnFee() external view returns (uint256);
}

contract GatewayRegistry is Claimable, CanReclaimTokens {
    constructor() public {
        Claimable.initialize(msg.sender);
        CanReclaimTokens.initialize(msg.sender);
    }

    
    
    event LogGatewayRegistered(
        string _symbol,
        string indexed _indexedSymbol,
        address indexed _token,
        address indexed _gatewayContract
    );
    event LogGatewayDeregistered(
        string _symbol,
        string indexed _indexedSymbol,
        address indexed _token,
        address indexed _gatewayContract
    );
    event LogGatewayUpdated(
        address indexed _token,
        address indexed _currentGatewayContract,
        address indexed _newGatewayContract
    );

    
    uint256 numGatewayContracts = 0;

    
    LinkedList.List private gatewayContractList;

    
    LinkedList.List private renTokenList;

    
    mapping(address => address) private gatewayByToken;

    
    mapping(string => address) private tokenBySymbol;

    
    
    
    
    
    function setGateway(string calldata _symbol, address _token, address _gatewayContract)
        external
        onlyOwner
    {
        require(symbolIsValid(_symbol), "GatewayRegistry: symbol must be alphanumeric");

        
        require(
            !LinkedList.isInList(gatewayContractList, _gatewayContract),
            "GatewayRegistry: gateway already registered"
        );
        require(
            gatewayByToken[_token] == address(0x0),
            "GatewayRegistry: token already registered"
        );
        require(
            tokenBySymbol[_symbol] == address(0x0),
            "GatewayRegistry: symbol already registered"
        );

        
        LinkedList.append(gatewayContractList, _gatewayContract);

        
        LinkedList.append(renTokenList, _token);

        tokenBySymbol[_symbol] = _token;
        gatewayByToken[_token] = _gatewayContract;
        numGatewayContracts += 1;

        emit LogGatewayRegistered(_symbol, _symbol, _token, _gatewayContract);
    }

    
    
    
    
    
    function updateGateway(address _token, address _newGatewayContract)
        external
        onlyOwner
    {
        
        address currentGateway = gatewayByToken[_token];
        require(
            currentGateway != address(0x0),
            "GatewayRegistry: token not registered"
        );

        
        LinkedList.remove(gatewayContractList, currentGateway);

        
        LinkedList.append(gatewayContractList, _newGatewayContract);

        gatewayByToken[_token] = _newGatewayContract;

        emit LogGatewayUpdated(_token, currentGateway, _newGatewayContract);
    }

    
    
    
    
    function removeGateway(string calldata _symbol) external onlyOwner {
        
        address tokenAddress = tokenBySymbol[_symbol];
        require(
            tokenAddress != address(0x0),
            "GatewayRegistry: symbol not registered"
        );

        
        address gatewayAddress = gatewayByToken[tokenAddress];

        
        delete gatewayByToken[tokenAddress];
        delete tokenBySymbol[_symbol];
        LinkedList.remove(gatewayContractList, gatewayAddress);
        LinkedList.remove(renTokenList, tokenAddress);
        numGatewayContracts -= 1;

        emit LogGatewayDeregistered(
            _symbol,
            _symbol,
            tokenAddress,
            gatewayAddress
        );
    }

    
    function getGateways(address _start, uint256 _count)
        external
        view
        returns (address[] memory)
    {
        return
            LinkedList.elements(
                gatewayContractList,
                _start,
                _count == 0 ? numGatewayContracts : _count
            );
    }

    
    function getRenTokens(address _start, uint256 _count)
        external
        view
        returns (address[] memory)
    {
        return
            LinkedList.elements(
                renTokenList,
                _start,
                _count == 0 ? numGatewayContracts : _count
            );
    }

    
    
    
    
    function getGatewayByToken(address _token)
        external
        view
        returns (IGateway)
    {
        return IGateway(gatewayByToken[_token]);
    }

    
    
    
    
    function getGatewayBySymbol(string calldata _tokenSymbol)
        external
        view
        returns (IGateway)
    {
        return IGateway(gatewayByToken[tokenBySymbol[_tokenSymbol]]);
    }

    
    
    
    
    function getTokenBySymbol(string calldata _tokenSymbol)
        external
        view
        returns (IERC20)
    {
        return IERC20(tokenBySymbol[_tokenSymbol]);
    }

    function symbolIsValid(string memory _tokenSymbol) public pure returns (bool) {
        for (uint i = 0; i < bytes(_tokenSymbol).length; i++) {
            uint8 char = uint8(bytes(_tokenSymbol)[i]);
            if (!(
                (char >= 65 && char <= 90) ||
                (char >= 97 && char <= 122) ||
                (char >= 48 && char <= 57)
            )) {
                return false;
            }
        }
        return true;
    }
}

interface IGatewayRegistry {
    
    
    event LogGatewayRegistered(
        string _symbol,
        string indexed _indexedSymbol,
        address indexed _tokenAddress,
        address indexed _gatewayAddress
    );
    event LogGatewayDeregistered(
        string _symbol,
        string indexed _indexedSymbol,
        address indexed _tokenAddress,
        address indexed _gatewayAddress
    );
    event LogGatewayUpdated(
        address indexed _tokenAddress,
        address indexed _currentGatewayAddress,
        address indexed _newGatewayAddress
    );

    
    function getGateways(address _start, uint256 _count)
        external
        view
        returns (address[] memory);

    
    function getRenTokens(address _start, uint256 _count)
        external
        view
        returns (address[] memory);

    
    
    
    
    function getGatewayByToken(address _tokenAddress)
        external
        view
        returns (IGateway);

    
    
    
    
    function getGatewayBySymbol(string calldata _tokenSymbol)
        external
        view
        returns (IGateway);

    
    
    
    
    function getTokenBySymbol(string calldata _tokenSymbol)
        external
        view
        returns (IERC20);
}

contract ProtocolStateV1 {
    

    
    

    
    
    DarknodeRegistryLogicV1 internal _darknodeRegistry;

    
    GatewayRegistry internal _gatewayRegistry;
}

contract ProtocolLogicV1 is
    Initializable,
    Claimable,
    ProtocolStateV1,
    IGatewayRegistry
{
    function initialize(address _nextOwner) public initializer {
        Claimable.initialize(_nextOwner);
    }

    

    function darknodeRegistry() public view returns (DarknodeRegistryLogicV1) {
        return ProtocolStateV1._darknodeRegistry;
    }

    function darknodeRegistryStore()
        public
        view
        returns (DarknodeRegistryStore)
    {
        return darknodeRegistry().store();
    }

    function renToken() public view returns (RenToken) {
        return darknodeRegistry().ren();
    }

    function darknodePayment() public view returns (DarknodePayment) {
        return
            DarknodePayment(
                _payableAddress(address(darknodeRegistry().darknodePayment()))
            );
    }

    function darknodePaymentStore() public view returns (DarknodePaymentStore) {
        return darknodePayment().store();
    }

    function darknodeSlasher() public view returns (DarknodeSlasher) {
        return
            DarknodeSlasher(
                _payableAddress(address(darknodeRegistry().slasher()))
            );
    }

    

    function gatewayRegistry() public view returns (GatewayRegistry) {
        return ProtocolStateV1._gatewayRegistry;
    }

    function getGateways(address _start, uint256 _count)
        external
        view
        returns (address[] memory)
    {
        return gatewayRegistry().getGateways(_start, _count);
    }

    function getRenTokens(address _start, uint256 _count)
        external
        view
        returns (address[] memory)
    {
        return gatewayRegistry().getRenTokens(_start, _count);
    }

    function getGatewayByToken(address _tokenAddress)
        external
        view
        returns (IGateway)
    {
        return gatewayRegistry().getGatewayByToken(_tokenAddress);
    }

    function getGatewayBySymbol(string calldata _tokenSymbol)
        external
        view
        returns (IGateway)
    {
        return gatewayRegistry().getGatewayBySymbol(_tokenSymbol);
    }

    function getTokenBySymbol(string calldata _tokenSymbol)
        external
        view
        returns (IERC20)
    {
        return gatewayRegistry().getTokenBySymbol(_tokenSymbol);
    }

    

    
    
    
    function _updateDarknodeRegistry(
        DarknodeRegistryLogicV1 _newDarknodeRegistry
    ) public onlyOwner {
        ProtocolStateV1._darknodeRegistry = _newDarknodeRegistry;
    }

    
    
    function _updateGatewayRegistry(GatewayRegistry _newGatewayRegistry)
        public
        onlyOwner
    {
        ProtocolStateV1._gatewayRegistry = _newGatewayRegistry;
    }

    

    
    function _payableAddress(address a)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(address(a)));
    }
}

contract ProtocolProxy is InitializableAdminUpgradeabilityProxy {}