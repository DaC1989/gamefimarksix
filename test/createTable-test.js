const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");

describe("create table", function () {
    it("create table", async function () {
        const LotteryFactory = await hre.ethers.getContractFactory("LotteryFactory");
        const lotteryFactory = await LotteryFactory.deploy();
        await lotteryFactory.deployed();
        console.log("LotteryFactory deployed to:", lotteryFactory.address);

        const LotteryManager = await hre.ethers.getContractFactory("LotteryManager");
        const lotteryManager = await LotteryManager.deploy(lotteryFactory.address);
        await lotteryManager.deployed();
        console.log("lotteryManager deployed to:", lotteryManager.address);

        const tableAddressTx = await lotteryManager.createTableIfNecessary(lotteryFactory.address, 1, 1, 5, 5, 10, 1, 1, lotteryFactory.address);

        // wait until the transaction is mined
        await tableAddressTx.wait();
        console.log("tableAddressTx deployed to:", tableAddressTx);

        //expect(await greeter.greet()).to.equal("Hola, mundo!");
    });
});
