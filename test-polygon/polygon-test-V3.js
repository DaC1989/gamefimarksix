const Web3 = require("web3");
const { createAlchemyWeb3 } = require("@alch/alchemy-web3");

const url = "https://polygon-mumbai.g.alchemy.com/v2/mmgALrtka8e2gZjKP0x2Pp-BsuiCtQXi";
const wss = "wss://polygon-mumbai.g.alchemy.com/v2/mmgALrtka8e2gZjKP0x2Pp-BsuiCtQXi";
// Using web3js
const web3 = new Web3(url);
// const web3 = createAlchemyWeb3(url);

// erc20 deployed to: 0x472E4F7984D8816D2F8b07dAbE41971aaEBC9447
// lotteryManagerV3 deployed to: 0x5fB6367926D630AF3F49c01650AfcD1ABc175cd1

const abiJson = require("../artifacts/contracts/LotteryManagerV3.sol/LotteryManagerV3.json");
const contractAddress = "0x5fB6367926D630AF3F49c01650AfcD1ABc175cd1";
const accA = "76fc79ab66aa7823543d7754d9ba57aad3d80d957ca8719489baedeb0d362b8d";
const erc20Address = "0x472E4F7984D8816D2F8b07dAbE41971aaEBC9447";
let erc20ABIJson = require("../artifacts/contracts/TestERC20.sol/TestERC20.json");
let erc20 = new web3.eth.Contract(erc20ABIJson.abi, "0x472E4F7984D8816D2F8b07dAbE41971aaEBC9447");

async function createTableIfNecessary() {
    let contract = new web3.eth.Contract(abiJson.abi, contractAddress);
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    console.log("wallet.address", wallet.address);

    let amount = Web3.utils.toWei('4', 'ether');
    let gasPrice = await web3.eth.getGasPrice();
    let gasNeeded = await contract.methods.createTableIfNecessary("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", amount, 1, 5, 5, 10, 1, 1, "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", 1).estimateGas({from: wallet.address});
    let result = await contract.methods
        .createTableIfNecessary(wallet.address, Web3.utils.toWei('3', 'ether'), 3, //creator、betting amount、minPPL
            5, 5, 10,//maxPPL、coolDownTime、gameTime
            1, 1, "0x18c5C2cAB8020E2bF9232BEb4bB4936E5Cb7Cecd", 1)//bankerCommission、referralCommission、bankerWallet、delayBlocks
        .send({
            gasPrice: gasPrice,
            gas: gasNeeded,
            from: wallet.address
        }).on('receipt', function(receipt){
                // receipt
                console.log("receipt.events", receipt.events);
                for (const event of receipt.events) {
                    if (event.event == 'CreateTableIfNecessary') {
                        console.log(`CreateTableIfNecessary ${event.event} with args ${event.args}`);
                    }
                }
            }
        );

    console.log("result: ", result);
}

async function notifyCoolDownTime(hashString) {
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    console.log("wallet address", wallet.address);

    let lotteryManager = new web3.eth.Contract(abiJson.abi, contractAddress);
    let gasPrice2 = await web3.eth.getGasPrice();
    let gasNeeded2 = await lotteryManager.methods.notifyCoolDownTime(hashString).estimateGas({from:wallet.address});
    let result = await lotteryManager.methods.notifyCoolDownTime(hashString).send({
        gasPrice: gasPrice2,
        gas: gasNeeded2,
        from: wallet.address
    }).on('receipt', function (receipt) {
        console.log('receipt', receipt.events.NotifyCoolDownTime.returnValues);
    }).on("error", function (err) {
        console.log("notifyCoolDownTime err", err);
    });
    console.log("result", result);
}

async function referral(a, b) {
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    console.log("wallet address", wallet.address);

    let lotteryManager = new web3.eth.Contract(abiJson.abi, contractAddress);
    let gasPrice2 = await web3.eth.getGasPrice();
    let gasNeeded2 = await lotteryManager.methods.referral(a, b).estimateGas({from:wallet.address});
    let result = await lotteryManager.methods.referral(a, b).send({
        gasPrice: gasPrice2,
        gas: gasNeeded2,
        from: wallet.address
    }).on('receipt', function (receipt) {
        console.log('receipt', receipt);
    }).on("error", function (err) {
        console.log("notifyCoolDownTime err", err);
    });
    console.log("result", result);
}

async function startRound(hashString) {
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    console.log("wallet address", wallet.address);
    let allowance = await erc20.methods.allowance(wallet.address, contractAddress).call();
    console.log("allowance", allowance);

    let lotteryManager = new web3.eth.Contract(abiJson.abi, contractAddress);
    let gasPrice2 = await web3.eth.getGasPrice();
    let gasNeeded2 = await lotteryManager.methods.startRoundV2(hashString).estimateGas({from:wallet.address});
    let result = await lotteryManager.methods.startRoundV2(hashString).send({
        gasPrice: gasPrice2,
        gas: gasNeeded2 * 2,
        from: wallet.address
    }).on('receipt', function (receipt) {
        console.log('receipt', receipt.events.StartRound.returnValues);
    }).on("error", function (err) {
        console.log("startRound err", err);
    });
    console.log("result", result);
}

async function testEstimateGas() {
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    let balance = await erc20.methods.balanceOf(wallet.address).call();
    console.log("wallet, balance", wallet, balance);
    let allowance = await erc20.methods.allowance(wallet.address, contractAddress).call();
    console.log("allowance", allowance);
    let data = await erc20.methods.approve(contractAddress, balance).estimateGas({from:wallet.address});
    console.log("data", data);
}

async function testHoldingTicket() {
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    let lotteryManager = new web3.eth.Contract(abiJson.abi, contractAddress);
    let hashString = "49584930728079883437580855597249589608309770452182078693195765254017489182861";
    let result = await lotteryManager.methods.holdingTicket(hashString).call({from:wallet.address});
    console.log("result", result);
}

async function transferUSDT(address) {
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);

    let gasPrice2 = await web3.eth.getGasPrice();
    let gasNeeded2 = await erc20.methods.transfer(address, Web3.utils.toWei('10000', 'ether')).estimateGas({from: wallet.address});
    let result = await erc20.methods.transfer(address, Web3.utils.toWei('10000', 'ether')).send({
        gasPrice: gasPrice2,
        gas: gasNeeded2 * 2,
        from: wallet.address
    });

    console.log("result", result);
}

//manager 给 contract approve
async function manangerApproveContract() {
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    console.log("wallet.address", wallet.address);
    let amount = Web3.utils.toWei('10000000', 'ether');
    let gasNeeded =await erc20.methods.approve(contractAddress, amount).estimateGas({from:wallet.address});
    let gasPrice = await web3.eth.getGasPrice()
    await erc20.methods.approve(contractAddress, amount).send({
        gasPrice: gasPrice,
        gas: gasNeeded,
        from: wallet.address
    });
    let allowance = await erc20.methods.allowance(wallet.address, contractAddress).call();
    console.log("allowance", allowance);
}

async function joinTable(count, number, hash) {
    let playerKey = "4710b1bb264d816af07198cab65a9389fbdf4d4119169ac22b10f9bf362ab9e2";
    web3.eth.accounts.wallet.add(playerKey);
    let wallet = web3.eth.accounts.privateKeyToAccount(playerKey);
    console.log("wallet.address", wallet.address);

    //假设是5u的table
    let amount = Web3.utils.toWei('' + count * 5, 'ether');
    let gasNeeded =await erc20.methods.approve(contractAddress, amount).estimateGas({from:wallet.address});
    let gasPrice = await web3.eth.getGasPrice()
    await erc20.methods.approve(contractAddress, amount).send({
        gasPrice: gasPrice,
        gas: gasNeeded,
        from: wallet.address
    });
    let allowance = await erc20.methods.allowance(wallet.address, contractAddress).call();
    console.log("allowance", allowance);
    let gasPrice2 = await web3.eth.getGasPrice();
    let lotteryManager = new web3.eth.Contract(abiJson.abi, contractAddress);
    let gasNeeded2 = await lotteryManager.methods.joinTableV2(count, number, hash).estimateGas({from: wallet.address});
    let result = await lotteryManager.methods.joinTableV2(count, number, hash).send({
        gasPrice: gasPrice2,
        gas: gasNeeded2,
        from: wallet.address
    }).on('receipt', function (receipt) {
        console.log('receipt', receipt.events.ReferCommission.returnValues);
    }).on("error", function (err) {
        console.log("joinTable err", err);
    });
    console.log("joinTable", result);
}

async function getUSDTBalance(address) {
    let balance = await erc20.methods.balanceOf(address).call();
    console.log("getBalance of address", Web3.utils.fromWei(balance));
}

async function getMaticBalance(address) {
    let balance = await web3.eth.getBalance(address);
    console.log("getBalance of address", Web3.utils.fromWei(balance));
}

let hash = "96960858409662686889941291405022178343652862133237785188686581123087088197678";
// getUSDTBalance('0x29Bf30f822E93582b8ABcA1788eB142021f44EDb');
// getMaticBalance('0x149bd24c00A24b3E2FdB46D17740f0aA1E99d2cD');
// createTableIfNecessary();
// notifyCoolDownTime(hash);
// manangerApproveContract();
// startRound(hash);
// testEstimateGas();
// testHoldingTicket();
// transferUSDT("0x4cc0C11426E8cd3E505fF9A65050FF89a21f10D4");
// referral("0xC0b87B15Af3078802ABd6754520439eA1DA0fe6D", "0x33E3eCe14f35DD7f031Eb277405044f7e5fBd8E2");
joinTable(1, 2, hash);

