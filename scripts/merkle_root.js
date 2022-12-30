const { MerkleTree } = require("merkletreejs")
const { keccak256 } = require("ethers/lib/utils")

// All whitelisted address
let whitelistedAddress = [
  "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
  "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
  "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
]

const findMerkleRoot = () => {
  let leafNode = whitelistedAddress.map((addr) => keccak256(addr))
  const merkleTree = new MerkleTree(leafNode, keccak256, { sortPairs: true })
  const rootHash = merkleTree.getHexRoot()
  console.log(rootHash, "roothash")
}

// Address you want to find merkle hex proof
let addr = "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"

// Find hex proof
const findHexProof = async () => {
  let indexOfArray = /*await*/ whitelistedAddress.indexOf(addr)
  let leafNode = whitelistedAddress.map((addr) => keccak256(addr))
  const merkleTree = /*await*/ new MerkleTree(leafNode, keccak256, { sortPairs: true })
  const clamingAddress = leafNode[indexOfArray]
  const hexProof = merkleTree.getHexProof(clamingAddress)
  console.log(hexProof, "hexProof")
}

// find merkle root by addrs
const findMerkleRootByAddr = (addrs) => {
  let leafNode = addrs.map((addr) => keccak256(addr))
  const merkleTree = new MerkleTree(leafNode, keccak256, { sortPairs: true })
  const rootHash = merkleTree.getHexRoot()
  return rootHash
}

// Find hex proof by addr
const findHexProofByAddr = async (addrs, addrToFind) => {
  let indexOfArray = addrs.indexOf(addrToFind)
  let leafNode = addrs.map((addr) => keccak256(addr))
  const merkleTree = new MerkleTree(leafNode, keccak256, { sortPairs: true })
  const clamingAddress = leafNode[indexOfArray]
  const hexProof = merkleTree.getHexProof(clamingAddress)
  return hexProof
}

//findMerkleRoot()
findHexProof()

module.exports = { findMerkleRoot, findHexProof, findHexProofByAddr, findMerkleRootByAddr }
