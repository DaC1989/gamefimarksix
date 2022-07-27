const Web3 = require("web3");

const url = "https://polygon-mumbai.g.alchemy.com/v2/mmgALrtka8e2gZjKP0x2Pp-BsuiCtQXi";
// Using web3js
const web3 = new Web3(url);

// erc20 deployed to: 0x472E4F7984D8816D2F8b07dAbE41971aaEBC9447
// lotteryFactory deployed to: 0x4EC23E95b6190564f14b685f235fd93f37E1F862
// lotteryManager deployed to: 0x149bd24c00A24b3E2FdB46D17740f0aA1E99d2cD


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

const abiJson = require("../artifacts/contracts/LotteryManager.sol/LotteryManager.json");
const contractAddress = "0x81F39241D2Cbb9a8985Af862a7157c33B41Ab933";
const accA = "76fc79ab66aa7823543d7754d9ba57aad3d80d957ca8719489baedeb0d362b8d";
const erc20Address = "0x472E4F7984D8816D2F8b07dAbE41971aaEBC9447";

async function createTableIfNecessary() {
    let contract = new web3.eth.Contract(abiJson.abi, contractAddress);
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    let data = contract.methods.createTableIfNecessary("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", Web3.utils.toWei('1', 'ether'), 1, 5, 5, 10, 1, 1, "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827").encodeABI();
    let {gasPrice, estimateGas} = await calculateGas("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", contractAddress, data);

    console.log("wallet.address", wallet.address)

    let result = await contract
        .methods
        .createTableIfNecessary("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", Web3.utils.toWei('2', 'ether'), 3, //creator、betting amount、minPPL
            5, 5, 10,//maxPPL、coolDownTime、gameTime
            1, 1, "0x18c5C2cAB8020E2bF9232BEb4bB4936E5Cb7Cecd")//bankerCommission、referralCommission、bankerWallet
        .send({
            gasPrice: gasPrice,
            gas: estimateGas,
            from: "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827"
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
    console.log("test2 result: ", result);
}

let erc20ABIJson = require("../artifacts/contracts/TestERC20.sol/TestERC20.json");
let erc20 = new web3.eth.Contract(erc20ABIJson.abi, "0x472E4F7984D8816D2F8b07dAbE41971aaEBC9447");
async function startRound() {
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    let balance = await erc20.methods.balanceOf(wallet.address).call();
    console.log("wallet, balance", wallet, balance);
    let allowance = await erc20.methods.allowance(wallet.address, contractAddress).call();
    console.log("allowance", allowance);
    let gasNeeded =await erc20.methods.approve(contractAddress, balance).estimateGas({from:wallet.address});
    let gasPrice = await web3.eth.getGasPrice()
    await erc20.methods.approve(contractAddress, balance).send({
        gasPrice: gasPrice,
        gas: gasNeeded,
        from: "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827"
    });
    let allowance2 = await erc20.methods.allowance(wallet.address, contractAddress).call();
    console.log("allowance2", allowance2);
    let hashString = "49584930728079883437580855597249589608309770452182078693195765254017489182861";
    let lotteryManager = new web3.eth.Contract(abiJson.abi, contractAddress);
    let gasPrice2 = await web3.eth.getGasPrice()
    let gasNeeded2 = await lotteryManager.methods.startRoundV2(hashString).estimateGas({from:wallet.address});
    let result = await lotteryManager.methods.startRoundV2(hashString).send({
        gasPrice: gasPrice2,
        gas: gasNeeded2,
        from: "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827"
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
        gas: gasNeeded2,
        from: wallet.address
    });

    console.log("result", result);
}

async function getBalance(address) {
    let balance = await erc20.methods.balanceOf(address).call();
    console.log("getBalance of address", Web3.utils.fromWei(balance));
}

// getBalance('0x29Bf30f822E93582b8ABcA1788eB142021f44EDb');
// createTableIfNecessary();
// startRound();
// testEstimateGas();
// testHoldingTicket();
transferUSDT("0x366fB72a638657AD21512c46cFe474AE1E88155a");


