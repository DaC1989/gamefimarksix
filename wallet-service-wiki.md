This wallet service help to create a crypto wallet, sending transactions, and checking wallet balances.

Dev Url: http://wallet.pqbd.fun

Staging Url: http://wallet.dbqp.fun

Services Token: `vlWi157wc2p6VUisxXOl`

![Screenshot_2022-11-21_at_5.52.54_PM](uploads/91f211f81852a9c5451b6673ba88d3a5/Screenshot_2022-11-21_at_5.52.54_PM.png)

#### We supported 4 chains so far

* eth-mainnet: chainId is 1
* eth-goerli: chainId is 5
* polygon-mainnet: chainId is 137
* polygon-mumbai: chainId is 80001

#### POST /wallet/wallet_service/createWallet (Create wallet)

Payload

```
{
   "token":"token",
   "data":{
      "type":"service",
      "label":"James Service Wallet"
   }
}
```

Response

```
{
    "success": true,
    "data": {
        "address": "0xc91f848b9bfa693ece2ef7aaa082c87aa25117c4",
        "label": "James Service Wallet22",
        "type": "service",
        "createdAt": "2022-12-21T06:13:10.861Z"
    }
}
```

#### POST /wallet/wallet_service/transfer (Transfer money)

Payload

```
{
   "token":"token",
   "data":{
        "fromAddress": "0x56bb7123add01133a16e0e2f57b8ddef376d8cba",
        "toAddress": "0xba9EA47D307bcfCcc98ecBc23AA647f8f289bDd9",
        "chainId": 80001,
        "asset": "USDT",
        "amount": 0.01
   }
}
```

Response

```
{
    "success": true,
    "data": {
        "blockHash": "0xb685bb1b213ca0ff081d2b893b2ab4c620477dc6d198e1c1f625ccbc12d2a8f9",
        "blockNumber": 29920535,
        "contractAddress": null,
        "cumulativeGasUsed": 564233,
        "effectiveGasPrice": 1972972131,
        "from": "0x56bb7123add01133a16e0e2f57b8ddef376d8cba",
        "gasUsed": 34823,
        "status": true,
        "to": "0xfe4f5145f6e09952a5ba9e956ed0c25e3fa4c7f1",
        "transactionHash": "0x783c122b508587ab814588345d40e0d01a2878a6c9887c72928712f56a961790",
        "transactionIndex": 2,
        "type": "0x0",
        "asset": "USDT",
        "amount": 0.01,
        "chainId": 80001,
        "createdAt": "2022-12-20T09:21:58.301Z"
    }
}
```

#### POST /wallet/wallet_service/getAllWallets (Get all wallet address) Listing Addresses

Payload

```
{
   "token":"",
   "data":{
   }
}
```

Response

```
{
    "success": true,
    "data": [
        {
            "address": "0x56bb7123add01133a16e0e2f57b8ddef376d8cba",
            "label": "James Service Wallet02",
            "type": "service"
        },
        {
            "address": "0x134db67d59e6270ab789bc58a53b7173846f07ee",
            "label": "Subscription Wallet",
            "type": "subscription"
        },
        {
            "address": "0xc91f848b9bfa693ece2ef7aaa082c87aa25117c4",
            "label": "James Service Wallet22",
            "type": "service"
        }
    ]
}
```

#### POST /wallet/wallet_service/getWallet (Get wallet info)

Payload

```
{
   "token":"",
   "data":{
      "address":"0x56bb7123add01133a16e0e2f57b8ddef376d8cba"
   }
}
```

Response

```
{
    "success": true,
    "data": {
        "address": "0x56bb7123add01133a16e0e2f57b8ddef376d8cba",
        "label": "James Service Wallet",
        "type": "service"
    }
}
```

#### POST /wallet/wallet_service/getBalance (Get wallet balance)

Payload

```
{
    "token": "vlWi157wc2p6VUisxXOl",
    "data": {
        "address": "0x134db67d59e6270ab789bc58a53b7173846f07ee",
        "chainId":80001,
        "asset":"USDT" 
    }
}
```

Response

```
{
    "success": true,
    "data": "0"
}
```

#### POST /wallet/wallet_service/updateWallet (Update the wallet info)

Payload

```
{
   "token":"token",
   "data": {
        "address": "0x56bb7123add01133a16e0e2f57b8ddef376d8cba",
        "label": "James Service Wallet02",
        "type": "service"
    }
}
```

Response

```
{
   "success":true,
   "data":true
}
```

#### POST /wallet/wallet_service/getWalletMnemonic (Get wallet passphrase, only subscription wallet can get passphrase)

Payload

```
{
   "token":"token",
   "data":{
      "address":"0x56bb7123add01133a16e0e2f57b8ddef376d8cba"
   }
}
```

Response

```
{
   "success":true,
   "data": {
        "address": "0x56bb7123add01133a16e0e2f57b8ddef376d8cba",
        "mnemonic": "round trash expand kitchen cube profit hamster sport destroy acquire weekend debate"
    }
}
```

#### POST /wallet/wallet_service/getWallletPrivateKey (Get wallet private key, only subscription wallet can get private key)

Payload

```
{
   "token":"token",
   "data":{
      "address":"0x56bb7123add01133a16e0e2f57b8ddef376d8cba"
   }
}
```

Response

```
{
   "success": true,
    "data": {
        "address": "0x56bb7123add01133a16e0e2f57b8ddef376d8cba",
        "privateKey": "0x50032c7316fa2bcc8b0d20d4eecda104821e0112a595e89db8c71d6d2346808f"
    }
}
```

#### POST /wallet/wallet_service/releaseWallet(Be careful! It will remove wallet record. Release service wallet, only service wallet can be released)

Payload

```
{
   "token":"token",
   "data":{
      "address":"1Q1AtvCyKhtveGm3187mgNRh5YcukUWjQC"
   }
}
```

Response

```
{
   "success":true,
   "data":{
      "address":"1Q1AtvCyKhtveGm3187mgNRh5YcukUWjQC",
   }
}
```

#### POST /wallet/wallet_service/getTransactions(Get transfer logs )

Payload

```
{
   "token":"token",
   "data":{
      "from":"1Q1AtvCyKhtveGm3187mgNRh5YcukUWjQC"
   }
}
```

Response

```
{
    "success": true,
    "data": [
        {
            "chainId": 80001,
            "transactionHash": "0x783c122b508587ab814588345d40e0d01a2878a6c9887c72928712f56a961790",
            "from": "0x56bb7123add01133a16e0e2f57b8ddef376d8cba",
            "to": "0xfe4f5145f6e09952a5ba9e956ed0c25e3fa4c7f1",
            "asset": "USDT",
            "amount": 0.01,
            "status": true
        }
    ]
}
```
