//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryTableDeployer.sol";

contract LotteryTable {

    struct TableInfo {
        address factory;
        address creator;
        uint256 amount;
        uint256 minPPL;
        uint256 maxPPL;
        uint256 coolDownTime;
        uint256 gameTime;
        uint256 bankerCommission;
        uint256 referralCommission;
        address bankerWallet;
    }
    TableInfo public tableInfo;

//    modifier onlyFactoryOwner() {
//        require(msg.sender == ILotteryFactory(factory).owner());
//        _;
//    }

    constructor() {
        ILotteryTableDeployer.Parameters memory params = ILotteryTableDeployer(msg.sender).getParameters();
        tableInfo =  TableInfo({factory:params.factory,
                                creator: params.creator,
                                amount:params.amount,
                                minPPL:params.minPPL,
                                maxPPL:params.maxPPL,
                                coolDownTime:params.amount,
                                gameTime:params.gameTime,
                                bankerCommission:params.bankerCommission,
                                referralCommission:params.referralCommission,
                                bankerWallet:params.bankerWallet});
    }





}
