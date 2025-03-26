// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20{

    address immutable Owner;

    constructor() ERC20("Wrapped Ether","WETH") {
        Owner = msg.sender;
        _mint(Owner,(1)*(10**18) );
    }

}

contract ERC20TokenContractWETH is ERC20("Wrapped Ether","WETH") {}

contract MATIC is ERC20{

    address immutable Owner;

    constructor() ERC20("Matic","MATIC") {
        Owner = msg.sender;
        _mint(Owner,(1)*(10**18) );
    }

}

contract ERC20TokenContractMATIC is ERC20("Matic","MATIC") {}

contract MockGoerliBridgeERC20 {

    address public immutable Owner;

    error msgValueZero(); //Using custom errors with revert saves gas compared to using require.
    error msgValueNot1003();
    error notOwnerAddress();
    error bridgedAlready();
    error bridgeOnOtherSideNeedsLiqudity();
    error bridgeEmpty();
    error ownerBridgeUsersBeforeWithdraw();
    error queueIsEmpty();
    error queueNotEmpty();
    error notExternalBridge();

    ERC20TokenContractMATIC public callMATIC;
    ERC20TokenContractWETH  public callWETH;

    constructor(address addressWETH, address addressWMATIC) {
        Owner = msg.sender;
        callMATIC = ERC20TokenContractMATIC(addressWMATIC); //ERC20 token address goes here.
        callWETH = ERC20TokenContractWETH(addressWETH); //ERC20 token address goes here.
    }

    MockMumbaiBridge public mumbaiBridgeInstance;

    mapping(uint => address) public queue; //Modified from //https://programtheblockchain.com/posts/2018/03/23/storage-patterns-stacks-queues-and-deques/

    uint256 public last; //Do not declare 0 directly, will waste gas.
    uint256 public first = 1;

    function enqueue() private { //Should not be called outside of contract or by anyone else, private.
        last += 1;
        queue[last] = msg.sender;
    }

    function dequeue() external { //Gets called by the other bridge contract, external.
        if (address(mumbaiBridgeInstance) == address(0) || msg.sender != address(mumbaiBridgeInstance) || last < first) { revert notExternalBridge(); } //Protect function external with owner call
        // if (last < first) { revert queueIsEmpty(); } //Removed require for this since it costs less gas.
        delete queue[first];
        first += 1;
    }

    function lockTokensForOptimism() public payable {
        if (msg.value != 1003 ) { revert msgValueNot1003(); }
        if (address(mumbaiBridgeInstance) == address(0) || (((last+2)-first)*1000) > callWETH.balanceOf(address(mumbaiBridgeInstance))  ) { revert bridgeOnOtherSideNeedsLiqudity(); }
        enqueue();
        payable(Owner).transfer(msg.value);
    }

    function ownerUnlockGoerliETH() public {
        if (msg.sender != Owner) { revert notOwnerAddress(); }
        if (address(mumbaiBridgeInstance) == address(0) || mumbaiBridgeInstance.last() < mumbaiBridgeInstance.first()) { revert queueIsEmpty(); } //Removed require for this since it costs less gas.
        address userToBridge = mumbaiBridgeInstance.queue(mumbaiBridgeInstance.last());
        mumbaiBridgeInstance.dequeue(); //Only this contract address set from the other contract from owner can call this function.
        callMATIC.transfer(userToBridge,1000);
    }

    function ownerRemoveBridgeLiqudity() public  {
        if (msg.sender != Owner) { revert notOwnerAddress(); }
        if (callMATIC.balanceOf(address(this)) == 0) { revert bridgeEmpty(); }
        if (address(mumbaiBridgeInstance) == address(0) || mumbaiBridgeInstance.last() >= mumbaiBridgeInstance.first()) { revert queueNotEmpty(); } //Removed require for this since it costs less gas.
        callMATIC.transfer(Owner,callMATIC.balanceOf(address(this)));
    }

    function mockOwnerOptimismBridgeAddress(address _token) public{
        if (msg.sender != Owner) { revert notOwnerAddress(); }
        mumbaiBridgeInstance = MockMumbaiBridge(_token);
    }

}

contract MockMumbaiBridge {

    address public immutable Owner;

    error msgValueZero(); //Using custom errors with revert saves gas compared to using require.
    error msgValueNot1003();
    error notOwnerAddress();
    error bridgeEmpty();
    error queueIsEmpty();
    error queueNotEmpty();
    error notExternalBridge();
    error bridgeOnOtherSideNeedsLiqudity();

    MockGoerliBridgeERC20 public goerliBridgeInstance;

    mapping(uint => address) public queue;

    uint256 public last; //Do not declare 0 directly, will waste gas.
    uint256 public first = 1;

    function enqueue() private { //Should not be called outside of contract or by anyone else, private.
        last += 1;
        queue[last] = msg.sender;
    }

    function dequeue() external { //Removed return value, not needed.
        if (address(goerliBridgeInstance) == address(0) || msg.sender != address(goerliBridgeInstance) || last < first ) { revert notExternalBridge(); } //Protect function external with owner call
        // if (last < first) { revert queueIsEmpty(); } //Removed require for this since it costs less gas.
        delete queue[first];
        first += 1;
    }

    ERC20TokenContractMATIC public callMATIC;
    ERC20TokenContractWETH  public callWETH;

    constructor(address addressWETH, address addressWMATIC) {
        Owner = msg.sender;
        callMATIC = ERC20TokenContractMATIC(addressWMATIC); //ERC20 token address goes here.
        callWETH = ERC20TokenContractWETH(addressWETH); //ERC20 token address goes here.
    }

    function lockTokensForGoerli() public payable {
        if (msg.value != 1003 ) { revert msgValueNot1003(); }
        if (address(goerliBridgeInstance) == address(0) || (((last+2)-first)*1000) > callMATIC.balanceOf(address(goerliBridgeInstance))  ) { revert bridgeOnOtherSideNeedsLiqudity(); }
        enqueue();
        payable(Owner).transfer(msg.value);
    }

    function ownerUnlockOptimismETH() public {
        if (msg.sender != Owner) { revert notOwnerAddress(); }
        if (address(goerliBridgeInstance) == address(0) || goerliBridgeInstance.last() < goerliBridgeInstance.first()) { revert queueIsEmpty(); } //Removed require for this since it costs less gas.
        address userToBridge = goerliBridgeInstance.queue(goerliBridgeInstance.last());
        goerliBridgeInstance.dequeue(); //Only this contract address set from the other contract from owner can call this function.
        callWETH.transfer(userToBridge,1000);
    }

    function ownerRemoveBridgeLiqudity() public  {
        if (msg.sender != Owner) { revert notOwnerAddress(); }
        if (callWETH.balanceOf(address(this)) == 0) { revert bridgeEmpty(); }
        if (address(goerliBridgeInstance) == address(0) || goerliBridgeInstance.last() >= goerliBridgeInstance.first()) { revert queueNotEmpty(); } //Removed require for this since it costs less gas.
        callWETH.transfer(Owner,callWETH.balanceOf(address(this)));
    }

    function mockOwnerGoerliBridgeAddress(address _token) public{
        if (msg.sender != Owner) { revert notOwnerAddress(); }
        goerliBridgeInstance = MockGoerliBridgeERC20(_token);
    }

}
