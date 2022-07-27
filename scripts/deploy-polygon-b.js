// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const {ethers} = require("hardhat");
const Web3 = require("web3");

//自测
async function main() {
    await hre.run('compile');
    const signers = await ethers.getSigners();
    //提供ERC20测试代币
    const ERC20 = await hre.ethers.getContractFactory("TestERC20");
    const erc20 = await ERC20.deploy("test-usdt02", "test-usdt02" );
    await erc20.deployed();
    console.log("erc20 deployed to:", erc20.address);
    await erc20.connect(signers[0]).transfer(signers[2].address, Web3.utils.toWei('10000', 'ether'));

    const LotteryFactory = await hre.ethers.getContractFactory("LotteryFactory");
    const lotteryFactory = await LotteryFactory.deploy();
    await lotteryFactory.deployed();
    console.log("lotteryFactory deployed to:", lotteryFactory.address);

    const LotteryManager = await hre.ethers.getContractFactory("LotteryManager");
    const lotteryManager = await LotteryManager.deploy(lotteryFactory.address, erc20.address);
    await lotteryManager.deployed();
    console.log("lotteryManager deployed to:", lotteryManager.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
