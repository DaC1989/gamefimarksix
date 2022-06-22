const Web3 = require("web3");

const web3 = new Web3("https://bsc-testnet.web3api.com/v1/FE3K26WKD1VF2FQZ922MU9D53CVMT4FI22");

//钱包地址
const address = "0x979b7b65D5c5D6FaCbdBa8f803eEC8408E95e827";
//钱包私钥
const accA = "76fc79ab66aa7823543d7754d9ba57aad3d80d957ca8719489baedeb0d362b8d";

//合约abi
const abiJson = require("../artifacts/contracts/LotteryManager.sol/LotteryManager.json");

const contractAddress = "0xA3CC0f2E5Af2676b8182980A67034C782902758F";

//计算gas
async function calculateGas(addr, data) {
    let gasPrice = await web3.eth.getGasPrice()
    let nonce = await web3.eth.getTransactionCount(address, "latest")
    let estimateGas = await web3.eth.estimateGas({
        nonce: nonce,
        from: addr,
        data: data
    })
    console.log("gasPrice", gasPrice)
    console.log("estimateGas", estimateGas)
    return {gasPrice, estimateGas}
}

async function createTableIfNecessary() {
    let contract = new web3.eth.Contract(abiJson.abi, contractAddress);
    web3.eth.accounts.wallet.add(accA);
    let wallet = web3.eth.accounts.privateKeyToAccount(accA);
    let data = contract.methods.createTableIfNecessary(address, Web3.utils.toWei('1', 'ether'), 1,
        3, 300, 600,
        1, 1, address).encodeABI();

    let {gasPrice, estimateGas} = await calculateGas(address, data);

    console.log("wallet.address", wallet.address)
    let result = await contract.methods.createTableIfNecessary(wallet.address, Web3.utils.toWei('2', 'ether'), 1,
                                                                3, 300, 600,
                                                                1, 1, wallet.address).send({
        gasPrice: gasPrice,
        gas: estimateGas*100,
        from: address
    });
    console.log("test2 result: ", result);
    return result;
}

createTableIfNecessary().then(result =>{

})

