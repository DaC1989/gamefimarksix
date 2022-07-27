const Web3 = require("web3");

const url = "https://polygon-mumbai.g.alchemy.com/v2/mmgALrtka8e2gZjKP0x2Pp-BsuiCtQXi";
// Using web3js
const web3 = new Web3(url);

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
// lotteryFactory deployed to: 0x360C1Fb4D152e62410C9a7d680c8588362f26003
// lotteryManager deployed to: 0xBF593d2099830758393fD3F2B6B77e2C8Ee628a9

const abiJson = require("../artifacts/contracts/LotteryManager.sol/LotteryManager.json");
const contractAddress = "0xBF593d2099830758393fD3F2B6B77e2C8Ee628a9";
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
        .createTableIfNecessary(wallet.address, Web3.utils.toWei('2', 'ether'), 3, //creator、betting amount、minPPL
            5, 5, 10,//maxPPL、coolDownTime、gameTime
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
    let managerKey = "4598f0b7b1d52313eff063f4b2b2d75564a698cef5747d3189f96f0abb167235";
    web3.eth.accounts.wallet.add(managerKey);
    let wallet = web3.eth.accounts.privateKeyToAccount(managerKey);
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
    let result = await contract.methods.startRoundV2(hash).send({
        gasPrice: gasPrice,
        gas: gasNeeded,
        from: wallet.address
    });
    console.log(result);
}


// createTableIfNecessary();
// joinTable(1, 2, "59638374068026126455012704085720935665581539865328318513549580719217222975603");
// manangerApproveContract();
startRound("59638374068026126455012704085720935665581539865328318513549580719217222975603");
startRound("59638374068026126455012704085720935665581539865328318513549580719217222975603");





