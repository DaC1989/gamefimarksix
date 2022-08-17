//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILotteryTableV3 {

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
        uint256 delayBlocks;
        uint256 jackpotCommission;
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
        uint256 round;//第几局
        uint256 roundNumber;//开奖号码
        uint256[] prizeNumbers;//中奖号码
        address[] players;//所有玩家
        uint256[] numbers;//玩家号码
        uint256[] counts;//玩家下注数
        uint256 winnerAllCount;//本局总的中奖下注数量
        address[] winners;//赢家
        uint256[] winnerCount;//赢家下注数量
        address[] jackpotWinners;//jackpot赢家
    }

    function joinTable(JoinInfo memory joinInfo) external;

}
