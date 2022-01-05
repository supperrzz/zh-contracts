// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WOW_FIRST_DRAFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string private baseExtension = "/sample-token-uri.json";
  string private notRevealedUri;
  uint256 public cost = 0.01 ether;
  uint256 public maxEraSupply = 3000;
  uint256 public maxMintAmount = 3;
  uint256 public perAddressLimit = 25;
  uint256 public currentEra = 0;
  bool public paused = false;
  bool public presale = true;
  bool private isMale = false;
  mapping(address => uint256) public addressMintedBalance;
  mapping (uint => Character) public characters;
  address[] public whitelistedAddresses;
  address[] public partnerAddesses;
  Era[] public eras;

  struct Character {
    uint tokenId;
    uint era;
    bool isMale;
  }

  struct Era {
    string name;
    string baseUri;
    bool reveal;
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
  function getErasLength() public view returns (uint) {
    return eras.length;
  }

  function getEraSupply(uint _eraId) public view returns (uint) {
    uint eraCount = eras[_eraId].maleCount + eras[_eraId].femaleCount;
    return eraCount;
  }

  function mint(uint256 _mintAmount) public payable {
    uint256 supply = getEraSupply(currentEra);
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];

    require(!paused, "the contract is paused");
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxEraSupply, "max NFT limit per era exceeded");

    if (msg.sender != owner()) {
      if(presale == true) {
        if(!isPartner(msg.sender)) {
          require(isWhitelisted(msg.sender), "user is not whitelisted");
        }
      }
      require(ownerMintedCount + _mintAmount <= perAddressLimit, "max NFT per address exceeded");
      require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
      
      if(!isPartner(msg.sender)) {
        require(msg.value >= cost * _mintAmount, "insufficient funds");
      }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint tokenId = generateTokenId();
      
      // generate character and add to characters array
      Character memory newCharacter = Character(tokenId, currentEra, isMale);
      characters[tokenId] = newCharacter;

      // update records
      isMale ? eras[currentEra].maleCount++ : eras[currentEra].femaleCount++;
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

  function isPartner(address _user) public view returns (bool) {
    for (uint i = 0; i < partnerAddesses.length; i++) {
      if (partnerAddesses[i] == _user) {
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

    Character memory character = characters[tokenId];

    if(eras[character.era].reveal == false) {
      return notRevealedUri;
    }

    string memory baseUri = eras[character.era].baseUri;
    string memory gender = character.isMale ? "/males/" : "/females/";

    return string(abi.encodePacked(baseUri, gender, tokenId.toString(), baseExtension));
  }

  // only owner
  function createEra(string memory _name, string memory _baseUri) public onlyOwner {
    require(eras.length <= 4, "Max Eras reached.");
    Era memory newEra;
    newEra.name = _name;
    newEra.baseUri = _baseUri;
    eras.push(newEra);
  }

  function updateEraInfo(uint _eraId, string memory _name, string memory _baseUri) public onlyOwner {
    Era memory updatedEra = eras[_eraId];
    
    if(bytes(_name).length > 0) {
      updatedEra.name = _name;
    }
    if(bytes(_baseUri).length > 0) {
      updatedEra.baseUri = _baseUri;
    }

    eras[_eraId] = updatedEra;
  }

  function revealEra(uint _eraId) public onlyOwner {
    Era memory updatedEra = eras[_eraId];
    updatedEra.reveal = !updatedEra.reveal;

    eras[_eraId] = updatedEra;
  }

  function setEra(uint _newEraId) public onlyOwner {
    currentEra = _newEraId;
  }
  
  function setPerAddressLimit(uint256 _limit) public onlyOwner {
    perAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
    maxMintAmount = _newMaxMintAmount;
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

  function setPartnerAddesses(address[] calldata _partners) public onlyOwner {
    delete partnerAddesses;
    partnerAddesses = _partners;
  }
  
  // internal
  function flipGender() internal {
    isMale = !isMale;
  }

  function generateTokenId() internal view returns (uint256) {
    uint latestId = isMale ? eras[currentEra].maleCount : eras[currentEra].femaleCount;
    uint tokenId = isMale ? 3000 * currentEra + latestId : 3000 * currentEra + latestId + 1499;
    return tokenId;
  }
}
