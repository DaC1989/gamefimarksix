const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const Web3 = require("web3");

describe("LotteryManager", function () {
    it("createTableIfNecessary", async function () {

        const Lib = await ethers.getContractFactory("TableAddress");
        const lib = await Lib.deploy();
        await lib.deployed();

        const LotteryFactory = await hre.ethers.getContractFactory("LotteryFactory");
        const lotteryFactory = await LotteryFactory.deploy();
        await lotteryFactory.deployed();
        console.log("LotteryFactory deployed to:", lotteryFactory.address);

        const LotteryManager = await hre.ethers.getContractFactory("LotteryManager", {
            libraries: {
                TableAddress: lib.address,
            },
        });
        const lotteryManager = await LotteryManager.deploy(lotteryFactory.address);
        await lotteryManager.deployed();
        console.log("LotteryManager deployed to:", lotteryManager.address);

        const tableAddressTx = await lotteryManager.createTableIfNecessary(lotteryManager.address, Web3.utils.toWei('1', 'ether'), 1, 5, 5, 10, 1, 1, lotteryManager.address);
        const tableAddressTx2 = await lotteryManager.createTableIfNecessary(lotteryManager.address, Web3.utils.toWei('1', 'ether'), 1, 5, 5, 10, 1, 1, lotteryManager.address);
    }).timeout(10000);

    it("joinTableV1", async function () {

        const Lib = await ethers.getContractFactory("TableAddress");
        const lib = await Lib.deploy();
        await lib.deployed();

        const LotteryFactory = await hre.ethers.getContractFactory("LotteryFactory");
        const lotteryFactory = await LotteryFactory.deploy();
        await lotteryFactory.deployed();
        console.log("LotteryFactory deployed to:", lotteryFactory.address);

        const LotteryManager = await hre.ethers.getContractFactory("LotteryManager", {
            // libraries: {
            //     TableAddress: lib.address,
            // },
        });
        const lotteryManager = await LotteryManager.deploy(lotteryFactory.address);
        await lotteryManager.deployed();
        console.log("LotteryManager deployed to:", lotteryManager.address);

        const ERC20 = await hre.ethers.getContractFactory("TestERC20");
        const erc20 = await ERC20.deploy("test-usdt", "test-usdt" );
        await erc20.deployed();
        console.log("erc20 deployed to:", erc20.address);
        const totalSupply = await erc20.totalSupply();
        console.log("totalSupply", totalSupply);
        console.log("balanceOf", await erc20.balanceOf("0x73F7fF55196c525A8273c766BeeA3F61D1b829b2"));
        const transferTx = await erc20.transfer("", "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", Web3.utils.toWei('2', 'ether'));
        await transferTx.wait();

        const tableAddressTx = await lotteryManager.createTableIfNecessary("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", Web3.utils.toWei('1', 'ether'), 1, 5, 5, 10, 1, 1, "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827");
        await tableAddressTx.wait();

        const arg = {"creator": "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827",
            "amount": Web3.utils.toWei('1', 'ether'),
            "minPPL":1,
            "maxPPL":5,
            "coolDownTime": 5,
            "gameTime": 10,
            "bankerCommission":1,
            "referralCommission":1,
            "bankerWallet":"0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827"};
        const signers = await ethers.getSigners();
        const joinTableV1Tx = await lotteryManager.joinTableV1(1, 2, arg, {
            value: Web3.utils.toWei('1', 'ether'),
        });
        await joinTableV1Tx.wait();
    }).timeout(10000);

    it("startRound", async function () {

        const Lib = await ethers.getContractFactory("TableAddress");
        const lib = await Lib.deploy();
        await lib.deployed();

        const LotteryFactory = await hre.ethers.getContractFactory("LotteryFactory");
        const lotteryFactory = await LotteryFactory.deploy();
        await lotteryFactory.deployed();
        console.log("LotteryFactory deployed to:", lotteryFactory.address);

        const LotteryManager = await hre.ethers.getContractFactory("LotteryManager", {
            // libraries: {
            //     TableAddress: lib.address,
            // },
        });
        const lotteryManager = await LotteryManager.deploy(lotteryFactory.address);
        await lotteryManager.deployed();
        console.log("LotteryManager deployed to:", lotteryManager.address);

        const ERC20 = await hre.ethers.getContractFactory("TestERC20");
        const erc20 = await ERC20.deploy("test-usdt", "test-usdt" );
        await erc20.deployed();
        console.log("erc20 deployed to:", erc20.address);
        const totalSupply = await erc20.totalSupply();
        console.log("totalSupply", totalSupply);
        console.log("balanceOf", await erc20.balanceOf("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827"));

        const tableAddressTx = await lotteryManager.createTableIfNecessary("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", Web3.utils.toWei('1', 'ether'), 1, 5, 5, 10, 1, 1, "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827");
        await tableAddressTx.wait();

        const tableInfo = {"creator": "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827",
            "amount": Web3.utils.toWei('1', 'ether'),
            "minPPL":1,
            "maxPPL":5,
            "coolDownTime": 5,
            "gameTime": 10,
            "bankerCommission":1,
            "referralCommission":1,
            "bankerWallet":"0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827"};
        const signers = await ethers.getSigners();
        const joinTableV1Tx = await lotteryManager.joinTableV1(1, 2, tableInfo, {
            value: Web3.utils.toWei('1', 'ether'),
        });
        console.log("table contract wallet balance:", await erc20.balanceOf("0x1008b527f4334d98ef985cd210440b7c7a9f3d5e"));
        await joinTableV1Tx.wait();

        const startRoundTx = await lotteryManager.startRoundV1(tableInfo);
        await startRoundTx.wait();
    }).timeout(10000);
});
