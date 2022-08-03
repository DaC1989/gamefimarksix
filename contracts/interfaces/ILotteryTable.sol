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

    struct RoundInfo {
        address[] players;//玩家
        uint256[] numbers;//号码
        uint256[] counts;//下注数
    }

    struct RoundResult {
        uint256 round;
        uint256 roundNumber;
        address[] players;
        uint256[] numbers;//玩家号码
        uint256[] counts;//玩家下注数
        uint256 winnerAllCount;//本局总的中奖下注数量
        address[] winners;//赢家
        uint256[] winnerCount;//赢家下注数量
    }

    function joinTable(JoinInfo memory joinInfo) external;

}
