const Web3 = require("web3");
const { createAlchemyWeb3 } = require("@alch/alchemy-web3");

const url = "https://polygon-mumbai.g.alchemy.com/v2/mmgALrtka8e2gZjKP0x2Pp-BsuiCtQXi";
const wss = "wss://polygon-mumbai.g.alchemy.com/v2/mmgALrtka8e2gZjKP0x2Pp-BsuiCtQXi";
// Using web3js
// const web3 = new Web3(wss);
const web3 = createAlchemyWeb3(wss);

//计算gas
async function calculateGas(from, to, data) {
    let gasPrice = await web3.eth.getGasPrice()
    console.log("gasPrice", gasPrice)
    let nonce = await web3.eth.getTransactionCount(from, "latest")
    let estimateGas = await web3.eth.estimateGas({
        nonce: nonce,
        from: from,
        to: to,
        data: data
    })
    console.log("estimateGas", estimateGas)
    return {gasPrice, estimateGas}
}

// erc20 deployed to: 0x73D66092F96F808cEDF399c22BE732318D347FCe
// lotteryFactory deployed to: 0x8668eF8D1de4BEFea5cD9403C320d3324B4CA98d
// lotteryManager deployed to: 0xC1c452a56d4277EFd8892ab03B7180eeb88d8E5B


const abiJson = require("../artifacts/contracts/LotteryManager.sol/LotteryManager.json");
const contractAddress = "0xC1c452a56d4277EFd8892ab03B7180eeb88d8E5B";
const accA = "4598f0b7b1d52313eff063f4b2b2d75564a698cef5747d3189f96f0abb167235";
let erc20ABIJson = require("../artifacts/contracts/TestERC20.sol/TestERC20.json");
const erc20Address = "0x73D66092F96F808cEDF399c22BE732318D347FCe";

let contract = new web3.eth.Contract(abiJson.abi, contractAddress);
let erc20 = new web3.eth.Contract(erc20ABIJson.abi, erc20Address);

async function createTableIfNecessary() {
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    let data = contract.methods.createTableIfNecessary(wallet.address, Web3.utils.toWei('2', 'ether'), 1, 5, 5, 10, 1, 1, "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827").encodeABI();
    let {gasPrice, estimateGas} = await calculateGas(wallet.address, contractAddress, data);

    let result = await contract
        .methods
        .createTableIfNecessary(wallet.address, Web3.utils.toWei('2', 'ether'), 20, //creator、betting amount、minPPL
            25, 5, 10,//maxPPL、coolDownTime、gameTime
            1, 1, "0x18c5C2cAB8020E2bF9232BEb4bB4936E5Cb7Cecd")//bankerCommission、referralCommission、bankerWallet
        .send({
            gasPrice: gasPrice,
            gas: estimateGas,
            from: wallet.address
        }).on('receipt', function(receipt){
                // receipt
                console.log("receipt.events", receipt.events.CreateTableIfNecessary.returnValues);
            }
        );
}
//table hash 59638374068026126455012704085720935665581539865328318513549580719217222975603
async function joinTable(count, number, hash) {
    //player cd994739b6121633fc69c0c99351e56c0d2661327e3e7a5fd7805eb9f61a4c83
    let playerKey = "cd994739b6121633fc69c0c99351e56c0d2661327e3e7a5fd7805eb9f61a4c83";
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
    let gasNeeded2 = await contract.methods.joinTableV2(count, number, hash).estimateGas({from: wallet.address});
    let result = await contract.methods.joinTableV2(count, number, hash).send({
        gasPrice: gasPrice2,
        gas: gasNeeded2,
        from: wallet.address
    });
    console.log(result);
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


async function startRound(hash) {
    let managerKey = "4598f0b7b1d52313eff063f4b2b2d75564a698cef5747d3189f96f0abb167235";
    web3.eth.accounts.wallet.add(managerKey);
    let wallet = web3.eth.accounts.privateKeyToAccount(managerKey);
    console.log("wallet.address", wallet.address);

    let gasPrice = await web3.eth.getGasPrice();
    let gasNeeded = await contract.methods.startRoundV2(hash).estimateGas({from: wallet.address});
    let transHash;
    try {
        let result = await contract.methods.startRoundV2(hash).send({
            gasPrice: gasPrice,
            gas: gasNeeded * 2,
            from: wallet.address
        }).once('sent', function (payload) {
            console.log('sent', payload)
        }).once('transactionHash', function (hash) {
            transHash = hash;
            console.log('transactionHash', hash);
        }).on('receipt', function (receipt) {
            console.log('on receipt', receipt.events.StartRound);
        }).on('error', function(err, receipt) {
            console.log('err', err);
            console.log('receipt', receipt);
        });
    } catch (e) {
        console.log("e", e);
    }
    console.log("transHash", transHash);
    // let result2 = await web3.eth.getTransactionReceipt('0xaf798ea123b793d99af1c36ba03c927e9e5aa1ec5ddd5d26999d3c5dea78b629');
    // console.log("result2.logs", result2.logs);
    // let decodedLogs = logsDecoder.decodeLogs(result2.logs);
    // console.log("decodedLogs", decodedLogs);


}

async function testHoldingTicket(hashString) {
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    let lotteryManager = new web3.eth.Contract(abiJson.abi, contractAddress);
    let result = await lotteryManager.methods.holdingTicket(hashString).call({from:wallet.address});
    console.log("result", result);
}


// createTableIfNecessary();
// joinTable(1, 2, "59638374068026126455012704085720935665581539865328318513549580719217222975603");
// manangerApproveContract();
//testHoldingTicket("59638374068026126455012704085720935665581539865328318513549580719217222975603");
// 46495648773727286948702670389830856155501528355533819124473569087233644039955 10
// 72504804741705690193767731652589755094368416868913544711784094133993040218870 20
startRound("72504804741705690193767731652589755094368416868913544711784094133993040218870");







