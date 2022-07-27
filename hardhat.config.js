require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const API_KEY = process.env.API_KEY;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      from: "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827",
      accounts: [{privateKey:"76fc79ab66aa7823543d7754d9ba57aad3d80d957ca8719489baedeb0d362b8d", balance:"104949625000000000000000"},
                 {privateKey:"cd994739b6121633fc69c0c99351e56c0d2661327e3e7a5fd7805eb9f61a4c83", balance:"104949625000000000000000"}]
    },
    matic: {
      url: "https://polygon-rpc.com/",
      accounts: [PRIVATE_KEY]
    },
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/fDqBg0l2Ws7oC9ImoKnI0gbwdpfyqGHD",
      accounts: ["4598f0b7b1d52313eff063f4b2b2d75564a698cef5747d3189f96f0abb167235","76fc79ab66aa7823543d7754d9ba57aad3d80d957ca8719489baedeb0d362b8d","cd994739b6121633fc69c0c99351e56c0d2661327e3e7a5fd7805eb9f61a4c83"]
    },
    bscTestnet: {
      chainId: 97,
      url: "https://bsc-testnet.web3api.com/v1/YA4TB2Y3RCXAYVX49QFQS1M1SXVE3J6XJ9",
      accounts: [PRIVATE_KEY]
    }
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 200000
  },
  etherscan: {
    apiKey: {
      bscTestnet: "TXDXR5XXVHIUSTRN49B9GR9YWSAC9CE5SN"
    }
  }
}
