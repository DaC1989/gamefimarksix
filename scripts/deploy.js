// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    await hre.run('compile');
    // We get the contract to deploy
    const LotteryFactory = await hre.ethers.getContractFactory("LotteryFactory");
    const lotteryFactory = await LotteryFactory.deploy();
    await lotteryFactory.deployed();
    console.log("LotteryFactory deployed to:", lotteryFactory.address);

    //hardhat usdt:0x73F7fF55196c525A8273c766BeeA3F61D1b829b2
    //BSC testnet USDT:0x337610d27c682E347C9cD60BD4b3b107C9d34dDd
    //BSC mainnet USDT:0x55d398326f99059ff775485246999027b3197955
    const LotteryManager = await hre.ethers.getContractFactory("LotteryManager");
    const lotteryManager = await LotteryManager.deploy(lotteryFactory.address, "0x337610d27c682E347C9cD60BD4b3b107C9d34dDd");
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
