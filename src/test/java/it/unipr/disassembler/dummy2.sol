pragma solidity ^0.8.0;
contract ExampleCoin {
   address public minter;
   address public receiver;

   mapping (address => uint) public balances;
   
   event Sent(address from, address to, uint amount);

   constructor() public {
      minter = msg.sender;
      }
   function mint(address receiver, uint amount) public {
      require(msg.sender == minter);
      require(amount < 1e60);
      balances[receiver] += amount;
   }

   function send(address received, uint amount) public {
      require(amount <= balances[msg.sender], "Insufficient balance.");
      balances[msg.sender] -= amount;
      balances[receiver] += amount;
      emit Sent(msg.sender, receiver, amount);
   }
}