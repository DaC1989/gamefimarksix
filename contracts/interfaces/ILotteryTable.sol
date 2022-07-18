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
        address player;
        uint256 count;
        uint256 number;
        address referraler;
    }

    struct RoundResult {
        uint256 round;
        uint256 roundNumber;
        address[] players;
        uint256 winnerAllCount;
        address[] winners;
        uint256[] winnerCount;
    }


    function joinTable(JoinInfo memory joinInfo) external;

}
