// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WOW_FIRST_DRAFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension;
  string public notRevealedUri; 
  uint256 public cost = 0.01 ether;
  uint256 public maxSupply = 15000;
  uint256 public maxMintAmount = 20;
  uint256 public nftPerAddressLimit = 3;
  uint256 public currentRelease = 0;
  uint256 public characterCount = 0;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  bool public isMale = false;
  mapping(address => uint256) public addressMintedBalance;
  mapping (uint => Character) public characters;
  address[] public whitelistedAddresses;
  Release[] public releases;

  struct Character {
    uint tokenId;
    uint release;
    bool isMale;
  }

  struct Release {
    string name;
    uint maleCount;
    uint femaleCount;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function createRelease(string memory _name) public {
    Release memory newRelease;
    newRelease.name = _name;
    releases.push(newRelease);
  }

  function getReleasesLength() public view returns (uint) {
    return releases.length;
  }

  function getReleaseInfo(uint _id) public view returns (Release memory) {
    return releases[_id];
  }

  function getCurrentReleaseInfo() public view returns (Release memory) {
    return releases[currentRelease];
  }

  function getCharacter(uint _tokenId) public view returns(Character memory) {
    return characters[_tokenId];
  }

  function mint(uint256 _mintAmount) public payable {
    // require(!paused, "the contract is paused");
    // uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    // require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");

    // require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
      if(onlyWhitelisted == true) {
          require(isWhitelisted(msg.sender), "user is not whitelisted");
          uint256 ownerMintedCount = addressMintedBalance[msg.sender];
          require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
      }
      require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint tokenId = generateTokenId();
      isMale ? releases[currentRelease].maleCount++ : releases[currentRelease].femaleCount++;
      Character memory newCharacter = Character(tokenId, currentRelease, isMale);
      characters[tokenId] = newCharacter;
      characterCount++;
      flipGender();
      _safeMint(msg.sender, tokenId);
    }
  }

  function generateTokenId() private view returns (uint256) {
    uint latestId = isMale ? releases[currentRelease].maleCount : releases[currentRelease].femaleCount;
    uint tokenId = isMale ? 3000 * currentRelease + latestId : 3000 * currentRelease + latestId + 1499;
    return tokenId;
  }

  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
    revealed = true;
  }

  function flipGender() public onlyOwner {
    isMale = !isMale;
  }

  function setRelease(uint _newReleaseId) public onlyOwner {
    currentRelease = _newReleaseId;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
}