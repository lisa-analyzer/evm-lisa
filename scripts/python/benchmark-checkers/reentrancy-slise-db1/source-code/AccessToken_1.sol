// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}





/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}





/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}




/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


// limited ContractRegistry definition
interface IRegistry {
  function owner() 
    external 
    returns(address);

  function updateContractAddress(
    string _name,
    address _address
  )
    external
    returns (address);

  function getContractAddress(
    string _name
  )
    external
    view
    returns (address);
}

// limited BrickblockToken definition
interface IBrickblockToken {
  function transfer(
    address _to,
    uint256 _value
  )
    external
    returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (bool);

  function balanceOf(
    address _address
  )
    external
    view
    returns (uint256);
  
  function approve(
    address _spender,
    uint256 _value
  )
    external
    returns (bool);
}

// SWC-Integer Overflow and Underflow: L2-308


/*
  glossary:
    dividendParadigm: the way of handling dividends, and the per token data structures
      * totalLockedBBK * (totalMintedPerToken - distributedPerBBK) / 1e18
      * this is the typical way of handling dividends.
      * per token data structures are stored * 1e18 (for more accuracy)
      * this works fine until BBK is locked or unlocked.
        * need to still know the amount they HAD locked before a change.
        * securedFundsParadigm solves this (read below)
      * when BBK is locked or unlocked, current funds for the relevant
        account are bumped to a new paradigm for balance tracking.
      * when bumped to new paradigm, dividendParadigm is essentially zeroed out
        by setting distributedPerBBK to totalMintedPerToken
          * (100 * (100 - 100) === 0)
      * all minting activity related balance increments are tracked through this

    securedFundsParadigm: funds that are bumped out of dividends during lock / unlock
      * securedTokenDistributions (mapping)
      * needed in order to track ACT balance after lock/unlockBBK
      * tracks funds that have been bumped from dividendParadigm
      * works as a regular balance (not per token)

    doubleEntryParadigm: taking care of transfer and transferFroms
      * receivedBalances[adr] - spentBalances[adr]
      * needed in order to track correct balance after transfer/transferFrom
      * receivedBalances used to increment any transfers to an account
        * increments balanceOf
        * needed to accurately track balanceOf after transfers and transferFroms
      * spentBalances
        * decrements balanceOf
        * needed to accurately track balanceOf after transfers and transferFroms

    dividendParadigm, securedFundsParadigm, doubleEntryParadigm combined
      * when all combined, should correctly:
        * show balance using balanceOf
          * balances is set to private (cannot guarantee accuracy of this)
          * balances not updated to correct values unless a
            transfer/transferFrom happens
      * dividendParadigm + securedFundsParadigm + doubleEntryParadigm
        * totalLockedBBK * (totalMintedPerToken - distributedPerBBK[adr]) / 1e18
          + securedTokenDistributions[adr]
          + receivedBalances[adr] - spentBalances[adr]
*/
contract AccessToken is PausableToken {
  uint8 public constant version = 1;
  // instance of registry contract to get contract addresses
  IRegistry internal registry;
  string public constant name = "AccessToken";
  string public constant symbol = "ACT";
  uint8 public constant decimals = 18;

  // total amount of minted ACT that a single BBK token is entitled to
  uint256 internal totalMintedPerToken;
  // total amount of BBK that is currently locked into ACT contract
  // used to calculate how much to increment totalMintedPerToken during minting
  uint256 public totalLockedBBK;

  // used to save information on who has how much BBK locked in
  // used in dividendParadigm (see glossary)
  mapping(address => uint256) internal lockedBBK;
  // used to decrement totalMintedPerToken by amounts that have already been moved to securedTokenDistributions
  // used in dividendParadigm (see glossary)
  mapping(address => uint256) internal distributedPerBBK;
  // used to store ACT balances that have been moved off of:
  // dividendParadigm (see glossary) to securedFundsParadigm
  mapping(address => uint256) internal securedTokenDistributions;
  // ERC20 override... keep private and only use balanceOf instead
  mapping(address => uint256) internal balances;
  // mapping tracking incoming balances in order to have correct balanceOf
  // used in doubleEntryParadigm (see glossary)
  mapping(address => uint256) public receivedBalances;
  // mapping tracking outgoing balances in order to have correct balanceOf
  // used in doubleEntryParadigm (see glossary)
  mapping(address => uint256) public spentBalances;


  event MintEvent(uint256 amount);
  event BurnEvent(address indexed burner, uint256 value);
  event BBKLockedEvent(
    address indexed locker, 
    uint256 lockedAmount, 
    uint256 totalLockedAmount
  );
  event BBKUnlockedEvent(
    address indexed locker, 
    uint256 lockedAmount, 
    uint256 totalLockedAmount
  );

  modifier onlyContract(string _contractName)
  {
    require(
      msg.sender == registry.getContractAddress(_contractName)
    );
    _;
  }

  constructor (
    address _registryAddress
  )
    public
  {
    require(_registryAddress != address(0));
    registry = IRegistry(_registryAddress);
  }

  // check an address for amount of currently locked BBK
  // works similar to basic ERC20 balanceOf
  function lockedBbkOf(
    address _address
  )
    external
    view
    returns (uint256)
  {
    return lockedBBK[_address];
  }

  // transfers BBK from an account to this contract
  // uses settlePerTokenToSecured to move funds in dividendParadigm to securedFundsParadigm
  // keeps a record of transfers in lockedBBK (securedFundsParadigm)
  function lockBBK(
    uint256 _amount
  )
    external
    returns (bool)
  {
    IBrickblockToken _bbk = IBrickblockToken(
      registry.getContractAddress("BrickblockToken")
    );

    require(settlePerTokenToSecured(msg.sender));
    lockedBBK[msg.sender] = lockedBBK[msg.sender].add(_amount);
    totalLockedBBK = totalLockedBBK.add(_amount);
    require(_bbk.transferFrom(msg.sender, this, _amount));
    emit BBKLockedEvent(msg.sender, _amount, totalLockedBBK);
    return true;
  }

  // transfers BBK from this contract to an account
  // uses settlePerTokenToSecured to move funds in dividendParadigm to securedFundsParadigm
  // keeps a record of transfers in lockedBBK (securedFundsParadigm)
  function unlockBBK(
    uint256 _amount
  )
    external
    returns (bool)
  {
    IBrickblockToken _bbk = IBrickblockToken(
      registry.getContractAddress("BrickblockToken")
    );
    require(_amount <= lockedBBK[msg.sender]);
    require(settlePerTokenToSecured(msg.sender));
    lockedBBK[msg.sender] = lockedBBK[msg.sender].sub(_amount);
    totalLockedBBK = totalLockedBBK.sub(_amount);
    require(_bbk.transfer(msg.sender, _amount));
    emit BBKUnlockedEvent(msg.sender, _amount, totalLockedBBK);
    return true;
  }

  // distribute tokens to all BBK token holders
  // uses dividendParadigm to distribute ACT to lockedBBK holders
  // adds delta (integer division remainders) to owner securedFundsParadigm balance
  function distribute(
    uint256 _amount
  )
    external
    onlyContract("FeeManager")
    returns (bool)
  {
    totalMintedPerToken = totalMintedPerToken
      .add(
        _amount
          .mul(1e18)
          .div(totalLockedBBK)
      );

    uint256 _delta = (_amount.mul(1e18) % totalLockedBBK).div(1e18);
    securedTokenDistributions[owner] = securedTokenDistributions[owner].add(_delta);
    totalSupply_ = totalSupply_.add(_amount);
    emit MintEvent(_amount);
    return true;
  }

  // bumps dividendParadigm balance to securedFundsParadigm
  // ensures that BBK transfers will not affect ACT balance accrued
  function settlePerTokenToSecured(
    address _address
  )
    private
    returns (bool)
  {

    securedTokenDistributions[_address] = securedTokenDistributions[_address]
      .add(
        lockedBBK[_address]
        .mul(totalMintedPerToken.sub(distributedPerBBK[_address]))
        .div(1e18)
      );
    distributedPerBBK[_address] = totalMintedPerToken;

    return true;
  }

  //
  // start ERC20 overrides
  //

  // combines dividendParadigm, securedFundsParadigm, and doubleEntryParadigm
  // in order to give a correct balance
  function balanceOf(
    address _address
  )
    public
    view
    returns (uint256)
  {

    return totalMintedPerToken == 0
      ? 0
      : lockedBBK[_address]
      .mul(totalMintedPerToken.sub(distributedPerBBK[_address]))
      .div(1e18)
      .add(securedTokenDistributions[_address])
      .add(receivedBalances[_address])
      .sub(spentBalances[_address]);
  }

  // does the same thing as ERC20 transfer but...
  // uses balanceOf rather than balances[adr] (balances is inaccurate see above)
  // sets correct values for doubleEntryParadigm (see glossary)
  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balanceOf(msg.sender));
    spentBalances[msg.sender] = spentBalances[msg.sender].add(_value);
    receivedBalances[_to] = receivedBalances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  // does the same thing as ERC20 transferFrom but...
  // uses balanceOf rather than balances[adr] (balances is inaccurate see above)
  // sets correct values for doubleEntryParadigm (see glossary)
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balanceOf(_from));
    require(_value <= allowed[_from][msg.sender]);
    spentBalances[_from] = spentBalances[_from].add(_value);
    receivedBalances[_to] = receivedBalances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  //
  // end ERC20 overrides
  //

  // callable only by FeeManager contract
  // burns tokens through incrementing spentBalances[adr] and decrements totalSupply
  // works with doubleEntryParadigm (see glossary)
  function burn(
    address _address,
    uint256 _value
  )
    external
    onlyContract("FeeManager")
    returns (bool)
  {
    require(_value <= balanceOf(_address));
    spentBalances[_address] = spentBalances[_address].add(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit BurnEvent(_address, _value);
    return true;
  }

  // prevent anyone from sending funds other than selfdestructs of course :)
  // SWC-Code With No Effects: L302-307
  function()
    public
    payable
  {
    revert();
  }
}
