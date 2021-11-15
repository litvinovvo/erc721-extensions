import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import type { NFTCollection } from "../typechain-types/NFTCollection";

const isSorted = (arr: number[]) => arr.every((v, i, a) => !i || a[i - 1] <= v);
const { parseEther } = ethers.utils;
const { BigNumber: BN } = ethers;

describe("NFTCollection contract", function () {
  let factory;
  let contract: NFTCollection;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr3: SignerWithAddress;
  let addrs: SignerWithAddress[];

  beforeEach(async function () {
    factory = await ethers.getContractFactory("NFTCollection");
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

    contract = await factory.deploy("Test collection", "TEST", "test-url") as NFTCollection;
    await contract.start();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await contract.owner()).to.equal(owner.address);
    });
  });

  describe("Royalty", function () {
    it("Should distribute royalties between owners", async function () {
      const price = await contract.cost();
      await contract.connect(addr1).mint(1, { value: price });
      await contract.connect(addr2).mint(3, { value: price.mul(BN.from(3)) });

      await expect(
        await addr3.sendTransaction({
          to: contract.address,
          value: parseEther("8"),
        })
      ).to.changeEtherBalances(
        [addr1, addr2],
        [parseEther("2"), parseEther("6")]
      );
    });
  });

  describe("Minting", function () {
    it("Should mint free item for owner", async function () {
      await contract.mint(1);
      const ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(1);
    });

    it("Should mint item for price for not owner", async function () {
      const price = await contract.cost();
      await contract.connect(addr1).mint(1, { value: price });
      const addr1Balance = await contract.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(1);
    });

    it("Should fail if mint too many items per tx", async function () {
      await expect(
        contract.mint((await contract.maxMintAmount()).toNumber() + 1)
      ).to.be.revertedWith("Max items per mint exceeded");
    });

    it("Should mint random item", async function () {
      const maxSupply = await (await contract.maxSupply()).toNumber();
      const tokenIds = [];

      await contract.setMaxMintAmount(maxSupply);
      await contract.mint(maxSupply);

      for (let i = 0; i < maxSupply; i++) {
        tokenIds.push(await (await contract.tokenByIndex(i)).toNumber());
      }

      expect(isSorted(tokenIds)).to.false;
    });
  });
});
