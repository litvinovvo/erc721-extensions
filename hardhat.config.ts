import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import dotenv from "dotenv";

dotenv.config();
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
  solidity: "0.8.9",
  networks: {
    testnet: {
      url: process.env.TESTNET,
      accounts: [process.env.TESTNET_PRIVATE_KEY],
    },
    mainnet: {
      url: process.env.MAINNET,
      accounts: [process.env.MAINNET_PRIVATE_KEY],
    },
  },
};
