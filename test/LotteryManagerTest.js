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

        const ArrayUtils = await ethers.getContractFactory("ArrayUtils");
        const arrayUtils = await ArrayUtils.deploy();
        await arrayUtils.deployed();

        const LotteryFactory = await hre.ethers.getContractFactory("LotteryFactoryV3", {
            libraries: {
                ArrayUtils: arrayUtils.address,
            },
        });
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

        await erc20.connect(signers[0]).transfer(player, Web3.utils.toWei('50000', 'ether'));
        console.log("balanceOf player", await erc20.balanceOf(player));

        const LotteryManager = await hre.ethers.getContractFactory("LotteryManagerV3", {
            // libraries: {
            //     ArrayUtils: arrayUtils.address,
            // },
        });
        const lotteryManager = await LotteryManager.deploy(lotteryFactory.address, erc20.address);
        await lotteryManager.deployed();
        console.log("LotteryManager deployed to:", lotteryManager.address);

        const createTableIfNecessary = await lotteryManager.createTableIfNecessary("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827",
            Web3.utils.toWei('2', 'ether'), 1, 1, 5, 10, 1, 1, "0x18c5C2cAB8020E2bF9232BEb4bB4936E5Cb7Cecd", 0, 10);
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
            "bankerWallet":"0x18c5C2cAB8020E2bF9232BEb4bB4936E5Cb7Cecd", "delayBlocks":20, "jackpotCommission":20};

        //player approve
        await erc20.connect(signers[1]).approve(lotteryManager.address, Web3.utils.toWei('2000', 'ether'));

        //joinTable
        const joinTableV2Tx = await lotteryManager.connect(signers[1]).joinTableV2(1, 2, hashString, 1);
        const joinTableV2TxReceipt = await joinTableV2Tx.wait();
        for (const event of joinTableV2TxReceipt.events) {
            console.log(`joinTableV2TxReceipt ${event.event} with args ${event.args}`);
        }

        //edit table
        // const editTableTx = await lotteryManager.editTable(hashString, tableInfo);
        // const editTableTxReceipt = await editTableTx.wait();
        // for (const event of editTableTxReceipt.events) {
        //     console.log(`editTableTxReceipt ${event.event} with args ${event.args}`);
        // }

        //holdingTicket
        const holdingTicketTx = await lotteryManager.holdingTicket(hashString);
        console.log("holdingTicketTx", holdingTicketTx);

        await erc20.approve(lotteryManager.address, erc20.balanceOf(signers[0].address));
        //notifyCoolDownTime
        const notifyCoolDownTimeTx = await lotteryManager.notifyCoolDownTime(hashString);
        const notifyCoolDownTimeTxReceipt = await notifyCoolDownTimeTx.wait();
        for (const event of notifyCoolDownTimeTxReceipt.events) {
            console.log(`notifyCoolDownTimeTxReceipt ${event.event} with args ${event.args}`);
        }
        //getTableInfo
        // const getTableInfoTx = await lotteryManager.getTableInfo(hashString);
        // console.log("getTableInfoTxReceipt", getTableInfoTx)

        //start round
        const startRoundTx = await lotteryManager.startRoundV2(hashString);
        const startRoundTxReceipt = await startRoundTx.wait();
        for (const event of startRoundTxReceipt.events) {
            if (event.event == 'StartRound') {
                console.log("StartRound.startRoundResult1",event.args)
            }
            if (event.event == 'JackpotWinner') {
                console.log("JackpotWinner",event)
            }
        }
        //joinTable
        const joinTableV2Tx2 = await lotteryManager.connect(signers[1]).joinTableV2(1, 2, hashString, 2);
        const joinTableV2TxReceipt2 = await joinTableV2Tx2.wait();
        for (const event of joinTableV2TxReceipt2.events) {
            console.log(`joinTableV2TxReceipt2 ${event.event} with args ${event.args}`);
        }
        //notifyCoolDownTime
        const notifyCoolDownTimeTx2 = await lotteryManager.notifyCoolDownTime(hashString);
        const notifyCoolDownTimeTxReceipt2 = await notifyCoolDownTimeTx2.wait();
        for (const event of notifyCoolDownTimeTxReceipt2.events) {
            console.log(`notifyCoolDownTimeTxReceipt2 ${event.event} with args ${event.args}`);
        }
        //start round
        const startRoundTx2 = await lotteryManager.startRoundV2(hashString);
        const startRoundTxReceipt2 = await startRoundTx2.wait();
        for (const event of startRoundTxReceipt2.events) {
            if (event.event == 'StartRound') {
                console.log("StartRound.startRoundResult2",event.args)
            }
            if (event.event == 'JackpotWinner') {
                console.log("JackpotWinner",event)
            }
        }
        //joinTable
        const joinTableV2Tx3 = await lotteryManager.connect(signers[1]).joinTableV2(1, 2, hashString, 3);
        const joinTableV2TxReceipt3 = await joinTableV2Tx3.wait();
        for (const event of joinTableV2TxReceipt3.events) {
            console.log(`joinTableV2TxReceipt3 ${event.event} with args ${event.args}`);
        }
        //notifyCoolDownTime
        const notifyCoolDownTimeTx3 = await lotteryManager.notifyCoolDownTime(hashString);
        const notifyCoolDownTimeTxReceipt3 = await notifyCoolDownTimeTx3.wait();
        for (const event of notifyCoolDownTimeTxReceipt3.events) {
            console.log(`notifyCoolDownTimeTxReceipt3 ${event.event} with args ${event.args}`);
        }
        //start round
        const startRoundTx3 = await lotteryManager.startRoundV2(hashString);
        const startRoundTxReceipt3 = await startRoundTx3.wait();
        for (const event of startRoundTxReceipt3.events) {
            if (event.event == 'StartRound') {
                console.log("StartRound.startRoundResult3",event.args)
            }
            if (event.event == 'JackpotWinner') {
                console.log("JackpotWinner",event)
            }
        }

        //joinTable
        const joinTableV2Tx4 = await lotteryManager.connect(signers[1]).joinTableV2(1, 2, hashString, 4);
        const joinTableV2TxReceipt4 = await joinTableV2Tx4.wait();
        for (const event of joinTableV2TxReceipt4.events) {
            console.log(`joinTableV2TxReceipt4 ${event.event} with args ${event.args}`);
        }
        //notifyCoolDownTime
        const notifyCoolDownTimeTx4 = await lotteryManager.notifyCoolDownTime(hashString);
        const notifyCoolDownTimeTxReceipt4 = await notifyCoolDownTimeTx4.wait();
        for (const event of notifyCoolDownTimeTxReceipt3.events) {
            console.log(`notifyCoolDownTimeTxReceipt4 ${event.event} with args ${event.args}`);
        }
        //start round
        const startRoundTx4 = await lotteryManager.startRoundV2(hashString);
        const startRoundTxReceipt4 = await startRoundTx4.wait();
        for (const event of startRoundTxReceipt4.events) {
            if (event.event == 'StartRound') {
                console.log("StartRound.startRoundResult4",event.args)
            }
            if (event.event == 'JackpotWinner') {
                console.log("JackpotWinner",event)
            }
        }



    }).timeout(30000);
});
