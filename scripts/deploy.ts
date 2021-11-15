const { NFT_NAME, NFT_SYMBOL, NFT_BASE_URI, NFT_MAX_SUPPLY } = process.env;
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log(
    "Account balance:",
    ethers.utils.formatEther(await deployer.getBalance())
  );

  const Contract = await ethers.getContractFactory("NFTCollection");
  const contract = await Contract.deploy(
    NFT_NAME,
    NFT_SYMBOL,
    NFT_BASE_URI,
    NFT_MAX_SUPPLY
  );

  console.log("Contract address:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
