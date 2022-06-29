//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILotteryTable {

    struct TableInfo {
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

    struct JoinInfo {
        uint256 count;
        uint256 number;
        address referraler;
    }

    function joinTable(JoinInfo memory joinInfo) external payable;

}
