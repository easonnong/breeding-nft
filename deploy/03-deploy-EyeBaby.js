const { network } = require("hardhat")
const { developmentChains, VERIFICATION_BLOCK_CONFIRMATIONS } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const waitBlockConfirmations = developmentChains.includes(network.name)
    ? 1
    : VERIFICATION_BLOCK_CONFIRMATIONS

  const eyeGenesis = await deployments.get("EyeGenesis")
  eyeGenesisAddress = eyeGenesis.address

  const eyeColor = await deployments.get("EyeColor")
  eyeColorAddress = eyeColor.address

  const arguments = [eyeGenesisAddress, eyeColorAddress]
  const eyeBaby = await deploy("EyeBaby", {
    from: deployer,
    args: arguments,
    log: true,
    waitBlockConfirmations: waitBlockConfirmations,
  })

  // Verify the deployment
  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    log("Verifying...")
    await verify(eyeBaby.address, arguments)
  }
}

module.exports.tags = ["all", "EyeBaby"]
