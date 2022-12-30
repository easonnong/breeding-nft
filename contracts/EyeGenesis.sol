// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

//0x19c012985bB3D31917F53529347d2d2E6793362c
contract EyeGenesis is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  enum ContractMintState {
    PAUSED,
    PUBLIC,
    REFUND
  }

  ContractMintState public state = ContractMintState.PAUSED;

  uint256 public maxSupply = 5;
  uint256 public publicCost = 0.01 ether;
  uint256 public maxMintAmountPerTx = 3;
  uint256 public maxPerWalletPublic = 3;

  string public uriPrefix = "";

  mapping(address => uint256) public publicPaid;
  mapping(address => uint256) public publicMinted;
  mapping(address => bool) public refunded;

  constructor() ERC721A("Eye Genesis", "EYEGENESIS") {}

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

  // MINTING FUNCTIONS
  function genesisMint(uint256 amount) external payable mintCompliance(amount) {
    require(state == ContractMintState.PUBLIC, "Public mint is disabled");
    require(totalSupply() + amount <= maxSupply, "Cannot mint that many");
    require(publicMinted[msg.sender] + amount <= maxPerWalletPublic, "Cannot mint that many");
    require(msg.value >= publicCost * amount, "Need more eth");
    publicPaid[msg.sender] += msg.value;
    publicMinted[msg.sender] += amount;
    _safeMint(msg.sender, amount);
  }

  function mintForAddress(address receiver, uint256 amount) external onlyOwner {
    require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
    _safeMint(receiver, amount);
  }

  function refundIfOver() external nonReentrant {
    require(state == ContractMintState.REFUND, "Refund is disabled");
    require(!refunded[msg.sender], "Already refunded");
    uint256 toRefund = getRefundAmount();
    refunded[msg.sender] = true;
    (bool success, ) = msg.sender.call{value: toRefund}("");
    require(success, "Refund failed");
  }

  // WITHDRAW
  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "Zero balance");
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Withdraw failed");
  }

  // GETTERS
  function getRefundAmount() private view returns (uint256) {
    return publicPaid[msg.sender] - publicMinted[msg.sender] * publicCost;
  }

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

  function setPublicCost(uint256 _price) external onlyOwner {
    publicCost = _price;
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxMintAmountPerTx(uint256 _amount) external onlyOwner {
    maxMintAmountPerTx = _amount;
  }

  function setMaxPerWalletPublic(uint256 _amount) external onlyOwner {
    maxPerWalletPublic = _amount;
  }

  function setUriPrefix(string calldata _uri) external onlyOwner {
    uriPrefix = _uri;
  }
}
