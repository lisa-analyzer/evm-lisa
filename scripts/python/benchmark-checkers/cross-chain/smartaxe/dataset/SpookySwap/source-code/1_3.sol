// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// copied from https://etherscan.io/address/0xbd3531da5cf5857e7cfaa92426877b022e612cf8#code
// modified ERC721Pausable to use @openzeppelin contract
// modified PRICE to 150
// removed reveal_timestamp, creatorAddress, devAddress

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import './interfaces/IWFTM.sol';

interface IERC2981 is IERC165 {
  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for _salePrice
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);
}

contract Magicats is ERC721Enumerable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    mapping (address => uint) public claimWhitelist;
    string public MAGICATS_PROVENANCE = "";
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public revealTimestamp;
    uint256 public claimTimestampEnd;
    uint256 public saleStart;
    uint256 public whitelistedElements;
    uint256 public constant MAX_ELEMENTS = 5000;
    uint256 public constant PRICE = 100 * 10**18;
    uint256 public constant MAX_BY_MINT = 5;
    address public constant creatorAddress = 0x2B43f12E31C6C03956930f0642cc49BA7Ca5BADE;
    address public constant aceLandAddress = 0x2352b745561e7e6FCD03c093cE7220e3e126ace0;
    address public constant wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    string public baseTokenURI;

    bool public saleOpen = false;
    bool public canChangeURI = true;
    bool public canChangeProv = true;

    event CreateCat(uint256 indexed id);
    constructor(string memory baseURI) ERC721("Magicats", "MGC") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(saleOpen, "saleIsOpen: sale not open");
        }
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function _setStartingIndexBlock() internal {
        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (_totalSupply() == MAX_ELEMENTS || block.timestamp >= revealTimestamp)) {
            startingIndexBlock = block.number;
        } 
    }
    function _maxNonWhitelistElements() internal view returns (uint) {
        if (block.timestamp <= claimTimestampEnd) {
            return MAX_ELEMENTS - whitelistedElements;
        }

        return MAX_ELEMENTS;
    }
    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= _maxNonWhitelistElements(), "Max limit");
        require(total <= _maxNonWhitelistElements(), "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }

        _setStartingIndexBlock();
    }
    function claim(address _to) public saleIsOpen {
        require(claimWhitelist[msg.sender] > 0, "Address not whitelisted");
        require(block.timestamp <= claimTimestampEnd, "Claim window has expired");

        for (uint256 i = 0; i < claimWhitelist[msg.sender]; i++) {
            _mintAnElement(_to);
        }

        whitelistedElements -= claimWhitelist[msg.sender];
        claimWhitelist[msg.sender] = 0;

        _setStartingIndexBlock();
    }
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateCat(id);
    }
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    // Set the starting index for the collection
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_ELEMENTS;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_ELEMENTS;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }


    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint, uint _salePrice) external pure returns (address, uint) {
        uint royalty = 500;
        address receiver = 0xf4C90BBa1747Cac1CA332D9483Fa54845948E3C4;
        return (receiver, (_salePrice * royalty) / 10000);
    }

    // Admin functions
    // permanently revoke ability to change URI
    function revokeSetURIAbility() public onlyOwner {
        canChangeURI = false;
    }

    // permanently revoke ability to change prov
    function revokeSetProvAbility() public onlyOwner {
        canChangeProv = false;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(canChangeURI, "Ability to change URI was revoked");
        baseTokenURI = baseURI;
    }

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(canChangeProv, "Ability to change provenance hash was revoked");
        MAGICATS_PROVENANCE = provenanceHash;
    }

    function flipSaleStatus() public onlyOwner {
        saleOpen = !saleOpen;
    }

    function startSale() public onlyOwner {
        require(saleStart == 0, "cant re-start initial sale");
        saleStart = block.timestamp;
        revealTimestamp = block.timestamp + (86400 * 2) + (3600 * 2); // reveal in 2 days 2 hours
        claimTimestampEnd = block.timestamp + (86400 * 2); // claim window is 2 days
    }

    function withdrawAll(address _token) public onlyOwner {
        uint256 balance = address(this).balance;
        if(balance > 0){
            IWFTM(wftm).deposit{value: balance.mul(20).div(100)}();
            IERC20(wftm).transfer(aceLandAddress, IERC20(wftm).balanceOf(address(this)));
            _withdraw(creatorAddress, address(this).balance);
        }
        if (_token != address(0)){
            IERC20(_token).transfer(creatorAddress, IERC20(_token).balanceOf(address(this)));
        }
    }

    function setRevealTimestamp(uint256 newRevealTimestamp) public onlyOwner {
        revealTimestamp = newRevealTimestamp;
    }
    
    function addToWhitelist(address[] memory addrs, uint[] memory quantity) public onlyOwner {
        require(addrs.length == quantity.length, "Addrs and quantity should have the same number of elements");

        for (uint256 i = 0; i < addrs.length; i++) {
            claimWhitelist[addrs[i]] = quantity[i];
            whitelistedElements += quantity[i];
        }
    }
    function removeFromWhitelist(address addr) public onlyOwner {
        whitelistedElements -= claimWhitelist[addr];
        claimWhitelist[addr] = 0;
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }
}