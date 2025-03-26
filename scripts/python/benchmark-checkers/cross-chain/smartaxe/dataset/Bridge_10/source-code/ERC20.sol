//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC20 is AccessControl {
    string public name = "ExampleToken";
    string public symbol = "EXT";
    uint8 public decimals = 9;
    uint256 public totalSupply = 1000000000000000000000;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier enoughTokens(address addr, uint256 value){
        require(balances[addr] >= value, "Not enough tokens");
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);

        _setRoleAdmin(MINTER_ROLE, ADMIN);
        _setRoleAdmin(BURNER_ROLE, ADMIN);
  
        mint(msg.sender, totalSupply);
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
    
    function transfer(address to, uint256 value) public enoughTokens(msg.sender, value) returns (bool) {
        require(to != address(0), "Can't transfer to zero address");
        balances[to]+=value;
        balances[msg.sender]-=value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public enoughTokens(from, value) returns (bool) {
        require(to != address(0), "Can't transfer to zero address");
        require(allowances[from][msg.sender] >= value, "Not enough allowance to transfer");
        balances[to]+=value;
        balances[from]-=value;
        allowances[from][msg.sender]-=value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowances[msg.sender][spender]+=value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function burn(address account, uint256 amount) public onlyRole(BURNER_ROLE) enoughTokens(account, amount){
        balances[account]-=amount;
        totalSupply-=amount;
        emit Transfer(account, address(0), amount);
    }

    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE){
        balances[account]+=amount;
        totalSupply+=amount;
        emit Transfer(address(0), account, amount);
    }
}