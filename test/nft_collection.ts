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
  let addr4: SignerWithAddress;
  let addrs: SignerWithAddress[];

  beforeEach(async function () {
    factory = await ethers.getContractFactory("NFTCollection");
    [owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners();

    contract = (await factory.deploy(
      "Test collection",
      "TEST",
      "test-url",
      100
    )) as NFTCollection;
    await contract.start();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await contract.owner()).to.equal(owner.address);
    });
  });

  describe("Whitelist", function () {
    it("Should prevent free mint for non whitelisted", async function () {
      await expect(contract.freeMint(1)).to.be.revertedWith(
        "You are not in the whitelist"
      );
    });

    it("Should prevent free mint if exceed available", async function () {
      await contract.setWhitelist([owner.address], [2]);
      await expect(contract.freeMint(3)).to.be.revertedWith(
        "Exceed free mints"
      );
    });

    it("Should protect set method from not owner", async function () {
      await expect(contract.connect(addr1).setWhitelist([owner.address], [2]))
        .to.be.reverted;
    });

    it("Should decrease available amount on mint", async function () {
      await contract.setWhitelist([owner.address], [2]);
      await contract.freeMint(1);

      expect(await contract.balanceOf(owner.address)).to.equal(1);
      expect(await contract.whitelist(owner.address)).to.be.equal(1);

      await expect(contract.freeMint(2)).to.be.revertedWith(
        "Exceed free mints"
      );
    });

    it("Should maintain reset", async function () {
      await contract.setWhitelist([owner.address], [1]);
      await contract.freeMint(1);
      expect(await contract.whitelist(owner.address)).to.be.equal(0);

      await contract.setWhitelist([owner.address], [1]);
      await contract.freeMint(1);
      expect(await contract.whitelist(owner.address)).to.be.equal(0);

      expect(await contract.balanceOf(owner.address)).to.equal(2);
    });
  });

  describe("Owners", function () {
    it("Should maintain owners list on mint", async function () {
      const price = await contract.cost();
      await contract.mint(1);
      expect(await contract.totalOwners()).to.equal(1);
      await contract.mint(1);
      expect(await contract.totalOwners()).to.equal(1);
      await contract.connect(addr1).mint(1, { value: price });
      expect(await contract.totalOwners()).to.equal(2);
      await contract.connect(addr1).mint(1, { value: price });
      expect(await contract.totalOwners()).to.equal(2);
      await contract.connect(addr2).mint(2, { value: price.mul(BN.from(2)) });
      expect(await contract.totalOwners()).to.equal(3);
      expect(await contract.ownerByIndex(0)).to.equal(owner.address);
      expect(await contract.ownerByIndex(1)).to.equal(addr1.address);
      expect(await contract.ownerByIndex(2)).to.equal(addr2.address);
    });

    it("Should maintain owners list on burn", async function () {
      const price = await contract.cost();
      await contract.mint(2);
      await contract.connect(addr1).mint(1, { value: price });

      const ownerTokenId = await contract.tokenOfOwnerByIndex(owner.address, 0);
      await contract.burn(ownerTokenId);

      expect(await contract.totalOwners()).to.equal(2);
      expect(await contract.ownerByIndex(0)).to.equal(owner.address);
      expect(await contract.ownerByIndex(1)).to.equal(addr1.address);

      const ownerLastTokenId = await contract.tokenOfOwnerByIndex(
        owner.address,
        0
      );
      await contract.burn(ownerLastTokenId);

      expect(await contract.totalOwners()).to.equal(1);
      expect(await contract.ownerByIndex(0)).to.equal(addr1.address);
    });

    it("Should maintain owners list on transfer", async function () {
      const price = await contract.cost();
      await contract.mint(2);
      await contract.connect(addr1).mint(1, { value: price });
      await contract.connect(addr2).mint(2, { value: price.mul(BN.from(2)) });

      const addr1TokenId = await contract.tokenOfOwnerByIndex(addr1.address, 0);

      await contract
        .connect(addr1)
        .transferFrom(addr1.address, addr2.address, addr1TokenId);

      expect(await contract.totalOwners()).to.equal(2);
      expect(await contract.ownerByIndex(0)).to.equal(owner.address);
      expect(await contract.ownerByIndex(1)).to.equal(addr2.address);

      const addr2TokenId = await contract.tokenOfOwnerByIndex(addr2.address, 0);
      await contract
        .connect(addr2)
        .transferFrom(addr2.address, addr3.address, addr2TokenId);

      expect(await contract.totalOwners()).to.equal(3);
      expect(await contract.ownerByIndex(0)).to.equal(owner.address);
      expect(await contract.ownerByIndex(1)).to.equal(addr2.address);
      expect(await contract.ownerByIndex(2)).to.equal(addr3.address);

      const ownerTokenId = await contract.tokenOfOwnerByIndex(owner.address, 0);
      await contract.transferFrom(owner.address, addr3.address, ownerTokenId);

      expect(await contract.totalOwners()).to.equal(3);
      expect(await contract.ownerByIndex(0)).to.equal(owner.address);
      expect(await contract.ownerByIndex(1)).to.equal(addr2.address);
      expect(await contract.ownerByIndex(2)).to.equal(addr3.address);
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

    it("Should ignore no royalties addresses", async function () {
      const price = await contract.cost();

      await contract.mint(1);
      await contract.connect(addr1).mint(1, { value: price });
      await contract.connect(addr2).mint(3, { value: price.mul(BN.from(3)) });
      await contract.connect(addr4).mint(2, { value: price.mul(BN.from(2)) });
      await contract.setNoRoyalties([owner.address, addr4.address]);

      await expect(
        await addr3.sendTransaction({
          to: contract.address,
          value: parseEther("8"),
        })
      ).to.changeEtherBalances(
        [addr1, addr2],
        [parseEther("2"), parseEther("6")]
      );

      await contract.setNoRoyalties([owner.address]);
      await expect(
        await addr3.sendTransaction({
          to: contract.address,
          value: parseEther("6"),
        })
      ).to.changeEtherBalances(
        [addr1, addr2, addr4],
        [parseEther("1"), parseEther("3"), parseEther("2")]
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
