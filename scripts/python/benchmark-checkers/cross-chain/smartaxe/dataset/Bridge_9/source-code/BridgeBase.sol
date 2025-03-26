pragma solidity ^0.8.0;


import './IToken.sol';

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract BridgeBase {
  address public admin;
  IToken public token;
  uint public nonce;
  mapping(uint => bool) public processedNonces;

  enum Step { Burn, Mint }
  event Transfer(
    address from,
    address to,
    uint tokenId,
    uint date,
    uint nonce,
    Step indexed step
  );

  constructor(address _token) {
    admin = msg.sender;
    token = IToken(_token);
  }

  
  function burn(address to,uint256 tokenId) external {
    // require(_isApprovedOrOwner(msg.sender, tokenId));
    
    token.burn(to,tokenId);
    
    emit Transfer(
      msg.sender,
      to,
      tokenId,
      block.timestamp,
      nonce,
      Step.Burn
    );
  nonce++;
  }
 

 function mint(address to, uint otherChainNonce,uint tokenId) external  {
    // require(msg.sender == admin, 'only admin');
    require(processedNonces[otherChainNonce] == false, 'transfer already processed');
    processedNonces[otherChainNonce] = true;
    
    
    token.mint(to);
    
    emit Transfer(
      msg.sender,
      to,
      tokenId,
      block.timestamp,
      otherChainNonce,
      Step.Mint
    );
     nonce++;
    }
  

   // function burn(address to, uint amount) external {
  //   token.burn(msg.sender, amount);
  //   emit Transfer(
  //     msg.sender,
  //     to,
  //     amount,
  //     block.timestamp,
  //     nonce,
  //     Step.Burn
  //   );
  //   nonce++;
  // }


  // function mint(address to, uint amount, uint otherChainNonce) external {
  //   require(msg.sender == admin, 'only admin');
  //   require(processedNonces[otherChainNonce] == false, 'transfer already processed');
  //   processedNonces[otherChainNonce] = true;
  //   token.mint(to, amount);
  //   emit Transfer(
  //     msg.sender,
  //     to,
  //     amount,
  //     block.timestamp,
  //     otherChainNonce,
  //     Step.Mint
  //   );
  // }
}