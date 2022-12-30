// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EyeBaby is ERC721, Ownable {
  using Strings for uint256;

  address private immutable EYE_GENESIS;
  address private immutable EYE_COLOR;

  string public uriPrefix = "";

  mapping(uint256 => mapping(uint256 => bool)) public minted;

  constructor(address genesisAddr, address colorAddr) ERC721("EyeBaby", "EYEBABY") {
    EYE_GENESIS = genesisAddr;
    EYE_COLOR = colorAddr;
  }

  // Mint
  function airdropMint(uint256 eyeGenesisId, uint256 eyeColorId) external {
    address ownerGenesis = IERC721(EYE_GENESIS).ownerOf(eyeGenesisId);
    address ownerColor = IERC721(EYE_COLOR).ownerOf(eyeColorId);
    require(!minted[eyeGenesisId][eyeColorId], "Minted yet");
    require(ownerGenesis == msg.sender, "Not genesis owner");
    require(ownerColor == msg.sender, "Not color owner");
    uint256 babyId = eyeGenesisId * 10 + eyeColorId;
    minted[eyeGenesisId][eyeColorId] = true;
    _safeMint(msg.sender, babyId);
  }

  // Override
  function _baseURI() internal view override returns (string memory) {
    return uriPrefix;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
        : "";
  }

  // Setting
  function setUriPrefix(string calldata _uri) external onlyOwner {
    uriPrefix = _uri;
  }
}
