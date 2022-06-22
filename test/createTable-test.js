const hre = require("hardhat");
const Web3 = require("web3");

async function main() {
    const LotteryFactory = await hre.ethers.getContractFactory("LotteryFactory");
    const lotteryFactory = await LotteryFactory.deploy();
    await lotteryFactory.deployed();
    console.log("LotteryFactory deployed to:", lotteryFactory.address);

    const LotteryManager = await hre.ethers.getContractFactory("LotteryManager");
    const lotteryManager = await LotteryManager.deploy(lotteryFactory.address);
    await lotteryManager.deployed();
    console.log("LotteryManager deployed to:", lotteryManager.address);

    const tableAddressTx = await lotteryManager.createTableIfNecessary(lotteryManager.address, Web3.utils.toWei('1', 'ether'), 1, 5, 5, 10, 1, 1, lotteryManager.address);
    const tableAddressTx2 = await lotteryManager.createTableIfNecessary(lotteryManager.address, Web3.utils.toWei('1', 'ether'), 1, 5, 5, 10, 1, 1, lotteryManager.address);
    // wait until the transaction is mined
    await tableAddressTx.wait();

    await tableAddressTx2.wait();
    console.log("tableAddressTx deployed to:", tableAddressTx);
    console.log("tableAddressTx2 deployed to:", tableAddressTx2);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
