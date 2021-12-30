// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ░█████╗░██╗░░██╗███████╗███████╗███████╗░█████╗░
// ██╔══██╗██║░░██║██╔════╝██╔════╝██╔════╝██╔══██╗
// ██║░░╚═╝███████║█████╗░░█████╗░░█████╗░░██║░░██║
// ██║░░██╗██╔══██║██╔══╝░░██╔══╝░░██╔══╝░░██║░░██║
// ╚█████╔╝██║░░██║███████╗██║░░░░░██║░░░░░╚█████╔╝
// ░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝░░░░░░╚════╝░
// COOKIE BOX NFT COLLECTION

contract CHEFFO_COOKIE_BOX is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string _contractURI;
  uint256 public cost = 0.01 ether;
  uint256 public maxSupply = 4321;
  uint256 public maxMintAmount = 8;
  bool public paused = false;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initContractURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setContractURI(_initContractURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
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

    return _baseURI();
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setContractURI(string memory URI) public onlyOwner {
    _contractURI = URI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner {
    // This will pay address 2% of the account balance
    (bool ks, ) = payable(0x6Ba131c677762a2652e354E23101CB73157fD352).call{value: address(this).balance * 2 / 100}("");
    require(ks);

    // This will pay address 5% of the account balance
    (bool hs, ) = payable(0xA3042Eb8cAEee4faD4A421aD506E1E2c82DA6D84).call{value: address(this).balance * 5 / 100}("");
    require(hs);

    // This will pay address 40% of the account balance
    (bool js, ) = payable(0xBb9B3d4E7A48c715f45B2924C1792dC77cF058D8).call{value: address(this).balance * 40 / 100}("");
    require(js);

    // This will pay remaining balance to owner
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}