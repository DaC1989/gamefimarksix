const Web3 = require("web3");
const express = require('express');

const web3 = new Web3("https://bsc-testnet.web3api.com/v1/FE3K26WKD1VF2FQZ922MU9D53CVMT4FI22");

//启动
async function main() {

}

//创建钱包
async function createWallet(count) {
    let accounts = web3.eth.accounts.wallet.create(count,web3.utils.randomHex(32));
    let results = [];
    for (let i = 0; i < accounts.length; i++) {
        let obj = {}
        obj.address = accounts[0].address;
        obj.privateKey = accounts[0].privateKey;
        results.push(obj);
    }
    return results;
}

//计算gas
async function calculateGas(address, data) {
    let gasPrice = await web3.eth.getGasPrice()
    let nonce = await web3.eth.getTransactionCount(address, "latest")
    let estimateGas = await web3.eth.estimateGas({
        nonce: nonce,
        to: address,
        data: web3.utils.utf8ToHex(data)
    })
    return {gasPrice, estimateGas}
}

//转钱
async function transMoney(fromKey, toKey, amount) {
    let from_account = web3.eth.accounts.privateKeyToAccount(fromKey);
    let to_account = web3.eth.accounts.privateKeyToAccount(toKey);
    web3.eth.accounts.wallet.add(from_account);
    web3.eth.accounts.wallet.add(to_account);
    let {gasPrice, estimateGas} = await calculateGas(to_account.address, amount);
    return web3.eth.sendTransaction({
        gasPrice: gasPrice,
        gas: estimateGas*50,
        value: amount,
        from: from_account.address,
        to: to_account.address
    }).catch(e => {
        throw e;
    });
}

//私钥
const accA = "76fc79ab66aa7823543d7754d9ba57aad3d80d957ca8719489baedeb0d362b8d";
const accB = "e53a50d1182275069e6d3afa9b57c4757aec1a6ca23a39dbc75f77e9f108ced7";
main().then(r => {
    transMoney(accA, accB, Web3.utils.toWei('0.02', 'ether')).then(r => {
        console.log({result: JSON.stringify(r) });
    });
});