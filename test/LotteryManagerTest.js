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
        await hre.run('compile');
        const signers = await ethers.getSigners();
        const player = "0xa06e7791114B68CdE383798AB24C06A6615a52dd";
        console.log("player address: ", signers[1].address);

        const Lib = await ethers.getContractFactory("TableAddress");
        const lib = await Lib.deploy();
        await lib.deployed();

        const LotteryFactory = await hre.ethers.getContractFactory("LotteryFactory");
        const lotteryFactory = await LotteryFactory.deploy();
        await lotteryFactory.deployed();
        console.log("LotteryFactory deployed to:", lotteryFactory.address);

        const ERC20 = await hre.ethers.getContractFactory("TestERC20");
        const erc20 = await ERC20.deploy("test-usdt", "test-usdt" );
        await erc20.deployed();
        console.log("erc20 deployed to:", erc20.address);
        const totalSupply = await erc20.totalSupply();
        console.log("totalSupply", totalSupply);
        console.log("balanceOf 0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", await erc20.balanceOf("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827"));

        await erc20.connect(signers[0]).transfer(player, Web3.utils.toWei('50', 'ether'));
        console.log("balanceOf player", await erc20.balanceOf(player));

        const LotteryManager = await hre.ethers.getContractFactory("LotteryManager", {
            // libraries: {
            //     TableAddress: lib.address,
            // },
        });
        const lotteryManager = await LotteryManager.deploy(lotteryFactory.address, erc20.address);
        await lotteryManager.deployed();
        console.log("LotteryManager deployed to:", lotteryManager.address);

        const createTableIfNecessary = await lotteryManager.createTableIfNecessary("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827",
            Web3.utils.toWei('2', 'ether'), 20, 5, 5, 10, 1, 1, "0x18c5C2cAB8020E2bF9232BEb4bB4936E5Cb7Cecd");
        const receipt = await createTableIfNecessary.wait()
        let hashString = "";
        for (const event of receipt.events) {
            console.log(`createTableIfNecessary ${event.event} with args ${event.args}`);
            if (event.event == 'CreateTableIfNecessary') {
                hashString = event.args[0];
            }
        }

        const tableInfo = {"creator": "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827",
            "amount": Web3.utils.toWei('2', 'ether'),
            "minPPL":3,
            "maxPPL":5,
            "coolDownTime": 5,
            "gameTime": 10,
            "bankerCommission":1,
            "referralCommission":1,
            "bankerWallet":"0x18c5C2cAB8020E2bF9232BEb4bB4936E5Cb7Cecd"};

        //player approve
        await erc20.connect(signers[1]).approve(lotteryManager.address, Web3.utils.toWei('1.111111111111111111', 'ether'));

        //joinTable
        // const joinTableV2Tx = await lotteryManager.connect(signers[1]).joinTableV2(1, 2, hashString);
        // const joinTableV2TxReceipt = await joinTableV2Tx.wait();
        // for (const event of joinTableV2TxReceipt.events) {
        //     console.log(`joinTableV2TxReceipt ${event.event} with args ${event.args}`);
        // }

        //edit table
        const editTableTx = await lotteryManager.editTable(hashString, tableInfo);
        const editTableTxReceipt = await editTableTx.wait();
        for (const event of editTableTxReceipt.events) {
            console.log(`editTableTxReceipt ${event.event} with args ${event.args}`);
        }

        //holdingTicket
        const holdingTicketTx = await lotteryManager.holdingTicket(hashString);
        console.log("holdingTicketTx", holdingTicketTx);

        //start round
        await erc20.approve(lotteryManager.address, erc20.balanceOf(signers[0].address));
        const startRoundTx = await lotteryManager.startRoundV2(hashString);
        const startRoundTxReceipt = await startRoundTx.wait();
        for (const event of startRoundTxReceipt.events) {
            if (event.event == 'StartRound') {
                console.log("StartRound",event)
            }
        }

    }).timeout(30000);

    it("startRoundV3", async function () {
        await hre.run('compile');
        const signers = await ethers.getSigners();
        const player = "0xa06e7791114B68CdE383798AB24C06A6615a52dd";
        console.log("player address: ", signers[1].address);

        const Lib = await ethers.getContractFactory("TableAddress");
        const lib = await Lib.deploy();
        await lib.deployed();

        const LotteryFactory = await hre.ethers.getContractFactory("LotteryFactoryV3");
        const lotteryFactory = await LotteryFactory.deploy();
        await lotteryFactory.deployed();
        console.log("LotteryFactory deployed to:", lotteryFactory.address);

        const ERC20 = await hre.ethers.getContractFactory("TestERC20");
        const erc20 = await ERC20.deploy("test-usdt", "test-usdt" );
        await erc20.deployed();
        console.log("erc20 deployed to:", erc20.address);
        const totalSupply = await erc20.totalSupply();
        console.log("totalSupply", totalSupply);
        console.log("balanceOf 0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", await erc20.balanceOf("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827"));

        await erc20.connect(signers[0]).transfer(player, Web3.utils.toWei('50', 'ether'));
        console.log("balanceOf player", await erc20.balanceOf(player));

        const LotteryManager = await hre.ethers.getContractFactory("LotteryManagerV3", {
            // libraries: {
            //     TableAddress: lib.address,
            // },
        });
        const lotteryManager = await LotteryManager.deploy(lotteryFactory.address, erc20.address);
        await lotteryManager.deployed();
        console.log("LotteryManager deployed to:", lotteryManager.address);

        const createTableIfNecessary = await lotteryManager.createTableIfNecessary("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827",
            Web3.utils.toWei('2', 'ether'), 20, 5, 5, 10, 1, 1, "0x18c5C2cAB8020E2bF9232BEb4bB4936E5Cb7Cecd", 0);
        const receipt = await createTableIfNecessary.wait()
        let hashString = "";
        for (const event of receipt.events) {
            console.log(`createTableIfNecessary ${event.event} with args ${event.args}`);
            if (event.event == 'CreateTableIfNecessary') {
                hashString = event.args[0];
            }
        }

        const tableInfo = {"creator": "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827",
            "amount": Web3.utils.toWei('2', 'ether'),
            "minPPL":3,
            "maxPPL":5,
            "coolDownTime": 5,
            "gameTime": 10,
            "bankerCommission":1,
            "referralCommission":1,
            "bankerWallet":"0x18c5C2cAB8020E2bF9232BEb4bB4936E5Cb7Cecd", "delayBlocks":0};

        //player approve
        await erc20.connect(signers[1]).approve(lotteryManager.address, Web3.utils.toWei('1.111111111111111111', 'ether'));

        //joinTable
        // const joinTableV2Tx = await lotteryManager.connect(signers[1]).joinTableV2(1, 2, hashString);
        // const joinTableV2TxReceipt = await joinTableV2Tx.wait();
        // for (const event of joinTableV2TxReceipt.events) {
        //     console.log(`joinTableV2TxReceipt ${event.event} with args ${event.args}`);
        // }

        //edit table
        const editTableTx = await lotteryManager.editTable(hashString, tableInfo);
        const editTableTxReceipt = await editTableTx.wait();
        for (const event of editTableTxReceipt.events) {
            console.log(`editTableTxReceipt ${event.event} with args ${event.args}`);
        }

        //holdingTicket
        const holdingTicketTx = await lotteryManager.holdingTicket(hashString);
        console.log("holdingTicketTx", holdingTicketTx);

        //notifyCoolDownTime
        const notifyCoolDownTimeTx = await lotteryManager.notifyCoolDownTime(hashString);
        const notifyCoolDownTimeTxReceipt = await notifyCoolDownTimeTx.wait();
        for (const event of notifyCoolDownTimeTxReceipt.events) {
            console.log(`notifyCoolDownTimeTxReceipt ${event.event} with args ${event.args}`);
        }
        //

        //start round
        await erc20.approve(lotteryManager.address, erc20.balanceOf(signers[0].address));
        const startRoundTx = await lotteryManager.startRoundV2(hashString);
        const startRoundTxReceipt = await startRoundTx.wait();
        for (const event of startRoundTxReceipt.events) {
            if (event.event == 'StartRound') {
                console.log("StartRound",event)
            }
        }

    }).timeout(30000);
});
