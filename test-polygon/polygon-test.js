const Web3 = require("web3");

const url = "https://polygon-mumbai.g.alchemy.com/v2/fDqBg0l2Ws7oC9ImoKnI0gbwdpfyqGHD";
// Using web3js
const web3 = new Web3(url);

async function getBalance(address) {
    let balance = await web3.eth.getBalance(address);
    console.log("getBalance of address", balance);
}

getBalance('0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827');
//计算gas
async function calculateGas(from, to, data) {
    let gasPrice = await web3.eth.getGasPrice()
    let nonce = await web3.eth.getTransactionCount(from, "latest")
    let estimateGas = await web3.eth.estimateGas({
        nonce: nonce,
        from: from,
        to: to,
        data: data
    })
    console.log("gasPrice", gasPrice)
    console.log("estimateGas", estimateGas)
    return {gasPrice, estimateGas}
}
const abiJson = require("../artifacts/contracts/LotteryManager.sol/LotteryManager.json");
const contractAddress = "0x20eEa5DBAdDe9515C19d65f87F5Ad37c14b66211";
const accA = "76fc79ab66aa7823543d7754d9ba57aad3d80d957ca8719489baedeb0d362b8d";
async function createTableIfNecessary() {
    let contract = new web3.eth.Contract(abiJson.abi, contractAddress);
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    let data = contract.methods.createTableIfNecessary("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", Web3.utils.toWei('1', 'ether'), 1, 5, 5, 10, 1, 1, "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827").encodeABI();
    let {gasPrice, estimateGas} = await calculateGas("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", contractAddress, data);

    console.log("wallet.address", wallet.address)

    let result = await contract
        .methods
        .createTableIfNecessary("0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827", Web3.utils.toWei('1', 'ether'), 3, //creator、betting amount、minPPL
            5, 5, 10,//maxPPL、coolDownTime、gameTime
            1, 1, "0x18c5C2cAB8020E2bF9232BEb4bB4936E5Cb7Cecd")//bankerCommission、referralCommission、bankerWallet
        .send({
            gasPrice: gasPrice,
            gas: estimateGas,
            from: "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827"
        }).on('receipt', function(receipt){
            // receipt
            console.log(receipt);}
        );
    console.log("test2 result: ", result);
}

createTableIfNecessary()


