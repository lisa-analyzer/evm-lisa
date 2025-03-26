pragma solidity ^0.8.0;




import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TokenBase is ERC721{
   using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

  address public admin;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    admin = msg.sender;
  }

  function updateAdmin(address newAdmin) external {
    require(msg.sender == admin, 'only admin');
    admin = newAdmin;
  }

  function mint(address to) external {
    // require(msg.sender == admin, 'only admin');

    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
  
    // _mint(to, amount);
  }

  function burn(address to,uint tokenId) external {
    // require(msg.sender == admin, 'only admin');
 
    // require(_isApprovedOrOwner(msg.sender, tokenId));
    _burn(tokenId);
   
    // _burn(owner, amount);
  }
}
