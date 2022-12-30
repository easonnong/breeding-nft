// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

//0xAf067CEF0eC46c1d098d81Ac6B5a614129bc1E2c
contract EyeColor is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  enum ContractMintState {
    PAUSED,
    ALLOWLIST
  }

  ContractMintState public state = ContractMintState.PAUSED;

  uint256 public maxSupply = 3;
  uint256 public maxMintAmountPerTx = 1;
  uint256 public maxPerWalletAllowlist = 1;

  string public uriPrefix = "";

  bytes32 public whitelistMerkleRoot;

  mapping(address => uint256) public allowlistMinted;

  constructor() ERC721A("Eye Color", "EYECOLOR") {}

  // OVERRIDES
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return uriPrefix;
  }

  // MODIFIERS
  modifier mintCompliance(uint256 amount) {
    require(amount > 0 && amount <= maxMintAmountPerTx, "Invalid mint amount");
    require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
    _;
  }

  // MERKLE TREE
  function _verify(bytes32 leaf, bytes32[] calldata proof) private view returns (bool) {
    return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
  }

  function _leaf(address account) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(account));
  }

  // MINTING FUNCTIONS
  function colorMint(uint256 amount, bytes32[] calldata proof) external mintCompliance(amount) {
    require(state == ContractMintState.ALLOWLIST, "Allow list mint is disabled");
    require(allowlistMinted[msg.sender] + amount <= maxPerWalletAllowlist, "Cannot mint that many");
    require(_verify(_leaf(msg.sender), proof), "verify error");
    allowlistMinted[msg.sender] += amount;
    _safeMint(msg.sender, amount);
  }

  function mintForAddress(address receiver, uint256 amount) external onlyOwner {
    require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
    _safeMint(receiver, amount);
  }

  // GETTERS
  function numberMinted(address minter) external view returns (uint256) {
    return _numberMinted(minter);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
        : "ipfs://";
  }

  // SETTERS
  function setState(ContractMintState _state) external onlyOwner {
    state = _state;
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxMintAmountPerTx(uint256 _amount) external onlyOwner {
    maxMintAmountPerTx = _amount;
  }

  function setMaxPerWalletAllowlist(uint256 _amount) external onlyOwner {
    maxPerWalletAllowlist = _amount;
  }

  function setUriPrefix(string calldata _uri) external onlyOwner {
    uriPrefix = _uri;
  }

  function setWhitelistMerkleRoot(bytes32 _root) external onlyOwner {
    whitelistMerkleRoot = _root;
  }
}
