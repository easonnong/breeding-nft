const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers")
const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("EyeGenesis NFT Unit Tests", function () {
      async function deployContractLockFixture() {
        let eyeGenesis, eyeGenesisContract
        const accounts = await ethers.getSigners()
        const deployer = accounts[0]
        const user1 = accounts[1]
        const user2 = accounts[2]
        const user3 = accounts[3]
        await deployments.fixture(["EyeGenesis"])
        eyeGenesisContract = await ethers.getContract("EyeGenesis")
        eyeGenesis = eyeGenesisContract.connect(deployer)
        return { eyeGenesis, deployer, user1, user2, user3 }
      }

      describe("construtor", function () {
        it("initalizes the NFT correctly", async () => {
          let { eyeGenesis } = await loadFixture(deployContractLockFixture)
          expect((await eyeGenesis.name()).toString()).to.equal("Eye Genesis")
          expect((await eyeGenesis.symbol()).toString()).to.equal("EYEGENESIS")
          expect((await eyeGenesis.state()).toString()).to.equal("0")
          expect((await eyeGenesis.maxSupply()).toString()).to.equal("5")
          expect(ethers.utils.formatEther(await eyeGenesis.publicCost())).to.equal("0.01")
          expect((await eyeGenesis.maxMintAmountPerTx()).toString()).to.equal("3")
          expect((await eyeGenesis.maxPerWalletPublic()).toString()).to.equal("3")
          expect((await eyeGenesis.uriPrefix()).toString()).to.equal("")
        })
      })

      describe("genesisMint", function () {
        it("reverts if public mint is disabled", async () => {
          let { eyeGenesis } = await loadFixture(deployContractLockFixture)
          await expect(eyeGenesis.genesisMint(1)).to.be.revertedWith("Public mint is disabled")
        })
        describe("mintCompliance", function () {
          it("reverts if mint more than maxMintAmountPerTx", async () => {
            let { eyeGenesis } = await loadFixture(deployContractLockFixture)
            await eyeGenesis.setState(1)
            await expect(eyeGenesis.genesisMint(4)).to.be.revertedWith("Invalid mint amount")
          })
          it("reverts if mint more than maxSupply", async () => {
            let { eyeGenesis, deployer } = await loadFixture(deployContractLockFixture)
            await eyeGenesis.setState(1)
            await eyeGenesis.mintForAddress(deployer.address, 1)
            const fee = ethers.utils.parseEther((0.01 * 5).toString())
            await expect(eyeGenesis.genesisMint(5, { value: fee.toString() })).to.be.revertedWith(
              "Invalid mint amount"
            )
          })
        })
        it("reverts if public mint minted more than limit", async () => {
          let { eyeGenesis } = await loadFixture(deployContractLockFixture)
          await eyeGenesis.setState(1)
          const fee = ethers.utils.parseEther((0.01 * 3).toString())
          await eyeGenesis.genesisMint(3, { value: fee.toString() })
          await expect(eyeGenesis.genesisMint(1)).to.be.revertedWith("Cannot mint that many")
        })
        it("reverts if public donnot have enough eth", async () => {
          let { eyeGenesis } = await loadFixture(deployContractLockFixture)
          await eyeGenesis.setState(1)
          const fee = ethers.utils.parseEther((0.01).toString())
          await expect(eyeGenesis.genesisMint(1)).to.be.revertedWith("Need more eth")
        })
      })

      describe("mintForAddress", function () {
        it("mint for other addrs successfully", async () => {
          let { eyeGenesis, user1, user2 } = await loadFixture(deployContractLockFixture)
          await eyeGenesis.mintForAddress(user1.address, 1)
          await eyeGenesis.mintForAddress(user2.address, 2)
          expect(await eyeGenesis.balanceOf(user1.address)).to.equal(1)
          expect(await eyeGenesis.balanceOf(user2.address)).to.equal(2)
        })
      })

      describe("refundIfOver", function () {
        it("reverts if REFUND is disabled", async () => {
          let { eyeGenesis } = await loadFixture(deployContractLockFixture)
          await expect(eyeGenesis.refundIfOver()).to.be.revertedWith("Refund is disabled")
        })
        it("refund successfully", async () => {
          let { eyeGenesis, deployer } = await loadFixture(deployContractLockFixture)
          await eyeGenesis.setState(1)
          const balanceBefore = await deployer.getBalance()
          const fee = ethers.utils.parseEther("1")
          let txResponse = await eyeGenesis.genesisMint(1, { value: fee.toString() })
          let transactionReceipt = await txResponse.wait(1)
          let { gasUsed: gasUsedMint, effectiveGasPrice: gasPriceMint } = transactionReceipt
          const gasCostMint = gasUsedMint.mul(gasPriceMint)
          await eyeGenesis.setState(2)
          txResponse = await eyeGenesis.refundIfOver()
          transactionReceipt = await txResponse.wait(1)
          let { gasUsed: gasUsedRefund, effectiveGasPrice: gasPriceRefund } = transactionReceipt
          const gasCostRefund = gasUsedRefund.mul(gasPriceRefund)
          const balanceAfter = await deployer.getBalance()
          console.log(
            `${balanceAfter.toString()}+${gasCostRefund.toString()}+${gasCostMint.toString()}=${balanceBefore.toString()}-${ethers.utils
              .parseEther((0.01).toString())
              .toString()}`
          )
          assert(
            balanceAfter.add(gasCostRefund).add(gasCostMint).toString() ==
              balanceBefore.sub(ethers.utils.parseEther((0.01).toString())).toString()
          )
        })
      })
    })
