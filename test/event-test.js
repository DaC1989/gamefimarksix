const Web3 = require("web3");

const web3 = new Web3("https://bsc-testnet.web3api.com/v1/FE3K26WKD1VF2FQZ922MU9D53CVMT4FI22");

//factory合约abi
const abiJson = require("../artifacts/contracts/LotteryFactory.sol/LotteryFactory.json");

//factory合约address
const contractAddress = "0xB175E50C83547F59194fE35F3709F1DA280Ac896";

//监听实时事件
async function subscribeCreateTable() {
    let contract = new web3.eth.Contract(abiJson.abi, contractAddress);
    contract.events.tableCreated(function(err, result) {
        if (!err) {
            console.log(result);
        }
    });
}
//查询历史某个区块的事件
async function pastCreateTable() {
    let contract = new web3.eth.Contract(abiJson.abi, contractAddress);
    await contract.getPastEvents('tableCreated',
        {fromBlock: 20414175, toBlock: 20414176},
        function (err, result) {
                if (!err) {
                    console.log(result);
                }
            });

    await sleep(4000);

}

pastCreateTable();

function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(resolve, ms);
    });
}


