const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const Web3 = require("web3");
const {address} = require("hardhat/internal/core/config/config-validation");

describe("TableAddressTest", function () {

    let lib;
    let lotteryFactory;
    let erc20;
    let lotteryManager;

    async function before() {
        const Lib = await ethers.getContractFactory("TableAddress");
        lib = await Lib.deploy();
        await lib.deployed();

        const LotteryFactory = await hre.ethers.getContractFactory("LotteryFactory");
        lotteryFactory = await LotteryFactory.deploy();
        await lotteryFactory.deployed();
        console.log("LotteryFactory deployed to:", lotteryFactory.address);

        const ERC20 = await hre.ethers.getContractFactory("TestERC20");
        erc20 = await ERC20.deploy("test-usdt", "test-usdt" );
        await erc20.deployed();
        console.log("erc20 deployed to:", erc20.address);

        const LotteryManager = await hre.ethers.getContractFactory("LotteryManager", {
            libraries: {
                TableAddress: lib.address,
            },
        });
        lotteryManager = await LotteryManager.deploy(lotteryFactory.address, erc20.address);
        await lotteryManager.deployed();
        console.log("LotteryManager deployed to:", lotteryManager.address);
    }

    it("computeAddressV1", async function () {
        await before();
        const createTableIfNecessary = await lotteryManager.createTableIfNecessary("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827",
            Web3.utils.toWei('1', 'ether'), 10, 10, 5, 10, 1, 1, "0x18c5C2cAB8020E2bF9232BEb4bB4936E5Cb7Cecd");
        const receipt = await createTableIfNecessary.wait()
        let hashString = "";
        for (const event of receipt.events) {
            console.log(`createTableIfNecessary ${event.event} with args ${event.args}`);
            if (event.event == 'CreateTableIfNecessary') {
                hashString = event.args[0];
            }
        }
        const tableInfo = {"creator": "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827",
            "amount": Web3.utils.toWei('1', 'ether'),
            "minPPL":10,
            "maxPPL":10,
            "coolDownTime": 5,
            "gameTime": 10,
            "bankerCommission":1,
            "referralCommission":1,
            "bankerWallet":"0x18c5C2cAB8020E2bF9232BEb4bB4936E5Cb7Cecd"};
        const joinTableV1 = await lotteryManager.joinTableV1(tableInfo);
        await joinTableV1.wait()


    }).timeout(20000);

});