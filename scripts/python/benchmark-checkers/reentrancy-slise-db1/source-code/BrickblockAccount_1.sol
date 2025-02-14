pragma solidity 0.4.23;



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

interface IFeeManager {
  function claimFee(
    uint256 _value
  )
    external
    returns (bool);

  function payFee()
    external
    payable
    returns (bool);
}


interface IAccessToken {
  function lockBBK(
    uint256 _value
  )
    external
    returns (bool);

  function unlockBBK(
    uint256 _value
  )
    external
    returns (bool);

  function transfer(
    address _to,
    uint256 _value
  )
    external
    returns (bool);

  function distribute(
    uint256 _amount
  )
    external
    returns (bool);

  function burn(
    address _address,
    uint256 _value
  )
    external
    returns (bool);
}


contract BrickblockAccount is Ownable {
  uint8 public constant version = 1;
  uint256 public fundsReleaseBlock;
  IRegistry private registry;

  constructor
  (
    address _registryAddress,
    uint256 _fundsReleaseBlock
  )
    public
  {
    registry = IRegistry(_registryAddress);
    fundsReleaseBlock = _fundsReleaseBlock;
  }

  function pullFunds()
    external
    onlyOwner
    returns (bool)
  {
    IBrickblockToken bbk = IBrickblockToken(
      registry.getContractAddress("BrickblockToken")
    );
    uint256 _companyFunds = bbk.balanceOf(address(bbk));
    return bbk.transferFrom(address(bbk), this, _companyFunds);
  }

  function lockBBK
  (
    uint256 _value
  )
    external
    onlyOwner
    returns (bool)
  {
    IAccessToken act = IAccessToken(
      registry.getContractAddress("AccessToken")
    );
    IBrickblockToken bbk = IBrickblockToken(
      registry.getContractAddress("BrickblockToken")
    );

    require(bbk.approve(address(act), _value));

    return act.lockBBK(_value);
  }

  function unlockBBK(
    uint256 _value
  )
    external
    onlyOwner
    returns (bool)
  {
    IAccessToken act = IAccessToken(
      registry.getContractAddress("AccessToken")
    );
    return act.unlockBBK(_value);
  }

  function claimFee(
    uint256 _value
  )
    external
    onlyOwner
    returns (bool)
  {
    IFeeManager fmr = IFeeManager(
      registry.getContractAddress("FeeManager")
    );
    return fmr.claimFee(_value);
  }
  // SWC-Unprotected Ether Withdrawal: L84-95
  function withdrawEthFunds(
    address _address,
    uint256 _value
  )
    external
    onlyOwner
    returns (bool)
  {
    require(address(this).balance > 0);
    _address.transfer(_value);
    return true;
  }

  function withdrawActFunds(
    address _address,
    uint256 _value
  )
    external
    onlyOwner
    returns (bool)
  {
    IAccessToken act = IAccessToken(
      registry.getContractAddress("AccessToken")
    );
    return act.transfer(_address, _value);
  }

  function withdrawBbkFunds(
    address _address,
    uint256 _value
  )
    external
    onlyOwner
    returns (bool)
  {
    require(fundsReleaseBlock < block.number);
    IBrickblockToken bbk = IBrickblockToken(
      registry.getContractAddress("BrickblockToken")
    );
    return bbk.transfer(_address, _value);
  }

  // ensure that we can be paid ether
  function()
    public
    payable
  {}
}
