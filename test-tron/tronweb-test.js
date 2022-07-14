const TronWeb = require("tronweb");
const Web3 = require("web3");

const tronWeb = new TronWeb({
    fullHost: 'https://api.shasta.trongrid.io',
    headers: {"TRON-PRO-API-KEY": '9490427e-8b9b-4eac-9541-5882f181fdd2'},
    privateKey: '437afe64d2519921904bc2517638f1b83ad7dbe1f437919bcbe0081941504e8f'
});

async function getBalance(address) {
    let balance = await tronWeb.trx.getBalance(address);
    console.log("getBalance of address", balance);
}

//getBalance('TXf5yeQTcn1bzqo6NzJhn4dxVPXwsEUBKW');

const abiJson = require("../build/contracts/LotteryManager.json");

async function createTableIfNecessary() {
    // let instance = await tronWeb.contract().at("TMMN1zJk2WGZVps7FEMSEsU6A7dQy4XL6y");
    let instance = await tronWeb.contract(abiJson.abi, "TMMN1zJk2WGZVps7FEMSEsU6A7dQy4XL6y");
    let res = await instance.createTableIfNecessary("TXf5yeQTcn1bzqo6NzJhn4dxVPXwsEUBKW",
        Web3.utils.toWei('1', 'ether'), 10, 10, 5, 10, 1, 1, "TD2W4i3Lb5tzqstqDxKgDbHhtzeTgzTPp4").send({
        feeLimit: 1_000_000_000,
        callValue: 0,
        shouldPollResponse: true
    });
    console.log("res", res);
}

async function event() {
    let instance = await tronWeb.contract(abiJson.abi, "TMMN1zJk2WGZVps7FEMSEsU6A7dQy4XL6y");
    let hash = await instance.createTableIfNecessary("TXf5yeQTcn1bzqo6NzJhn4dxVPXwsEUBKW",
        Web3.utils.toWei('1', 'ether'), 10, 10, 5, 10, 1, 1, "TD2W4i3Lb5tzqstqDxKgDbHhtzeTgzTPp4").send({
        feeLimit: 1_000_000_000,
        callValue: 0,
        //shouldPollResponse: true
    });
    console.log("hash", hash);
    //过滤事件以确定上链成功
    let i = 0
    let checkConfirm = async () => {
        i++
        if (i > 9) {
            //循环10次
            clearInterval(timer)
        }
        //过滤事件，每3秒10条，10次
        let res = await tronWeb.getEventResult('TMMN1zJk2WGZVps7FEMSEsU6A7dQy4XL6y', {eventName: 'CreateTableIfNecessary', size: 10})
        let checkEvent = async () => {
            return new Promise(resolve => {
                for (let t = 0; t < res.length; t++) {
                    console.log("res[t].transaction", res[t].transaction);
                    if (hash === res[t].transaction) {
                        console.log("res[t].transaction", hash, res[t]);
                        clearInterval(timer)
                        resolve('ok')
                    }
                }
                if (i === 10) {
                    resolve('false')
                }
            })
        }
        let event = await checkEvent()
        if (event === 'ok') {
            console.log("OK");
        } else {
            console.log("出错啦！请刷新后重试！")
        }
    }

    //设置定时器以更新
    let timer = setInterval(checkConfirm, 3000)

}

// createTableIfNecessary();
event();



