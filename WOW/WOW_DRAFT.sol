// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WOW_FIRST_DRAFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseExtension = "/sample-token-uri.json";
  string public notRevealedUri; 
  uint256 public cost = 0.01 ether;
  uint256 public maxSupply = 15000;
  uint256 public maxReleaseSupply = 3000;
  uint256 public maxMintAmount = 1;
  uint256 public nftPerAddressLimit = 20;
  uint256 public currentRelease = 0;
  uint256 public characterCount = 0;
  bool public paused = false;
  bool public revealed = false;
  bool public presale = true;
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
    string baseUri;
    uint maleCount;
    uint femaleCount;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setNotRevealedURI(_initNotRevealedUri);
  }

  // public
  function getReleases() public view returns (Release[] memory) {
    return releases;
  }

  function getReleaseInfo(uint _id) public view returns (Release memory) {
    return releases[_id];
  }

  function getReleaseSupply(uint _releaseId) public view returns (uint) {
    uint releaseCount = releases[_releaseId].maleCount + releases[_releaseId].femaleCount;
    return releaseCount;
  }

  function mint(uint256 _mintAmount) public payable {
    uint256 supply = getReleaseSupply(currentRelease);
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];

    require(!paused, "the contract is paused");
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxReleaseSupply, "max NFT limit per release exceeded");
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");

    if (msg.sender != owner()) {
      if(presale == true) {
        require(isWhitelisted(msg.sender), "user is not whitelisted");
      }
      require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
      require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint tokenId = generateTokenId();
      
      // generate character and add to characters array
      Character memory newCharacter = Character(tokenId, currentRelease, isMale);
      characters[tokenId] = newCharacter;

      // update records
      isMale ? releases[currentRelease].maleCount++ : releases[currentRelease].femaleCount++;
      characterCount++;
      addressMintedBalance[msg.sender]++;
      flipGender();
      _safeMint(msg.sender, tokenId);
    }
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

    Character memory character = getCharacter(tokenId);
    string memory currentBaseURI = releases[currentRelease].baseUri;
    string memory gender = character.isMale ? "/males/" : "/females/";

    return string(abi.encodePacked(currentBaseURI, gender, tokenId.toString(), baseExtension));
  }

  // only owner
  function createRelease(string memory _name, string memory _baseUri) public onlyOwner {
    Release memory newRelease;
    newRelease.name = _name;
    newRelease.baseUri = _baseUri;
    releases.push(newRelease);
  }

  function reveal() public onlyOwner {
    revealed = true;
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
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setPresale(bool _state) public onlyOwner {
    presale = _state;
  }
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
  
  // internal
  function flipGender() internal {
    isMale = !isMale;
  }

  function generateTokenId() internal view returns (uint256) {
    uint latestId = isMale ? releases[currentRelease].maleCount : releases[currentRelease].femaleCount;
    uint tokenId = isMale ? 3000 * currentRelease + latestId : 3000 * currentRelease + latestId + 1499;
    return tokenId;
  }

  function getCharacter(uint _tokenId) internal view returns(Character memory) {
    return characters[_tokenId];
  }
}
