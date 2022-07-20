//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryTableDeployer.sol";
import "./interfaces/ILotteryFactory.sol";
import "./interfaces/ILotteryTable.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract LotteryTable is ILotteryTable, ReentrancyGuard{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    address public immutable factory;
    address public immutable managerContract;
    TableInfo private tableInfo;
    Counters.Counter private _roundCount;

    struct Round {
        address[] players;//玩家
        uint256[] numbers;//号码
        uint256[] counts;//下注数

        address[] winners;//赢家
        mapping(address => uint256) winnerCountMap;//赢家下注数
        uint256[] winnerCount;//赢家多次下注数
        uint256 winnerAllCount;//压中的总下注数
    }
    Round private _round;

    modifier onlyFactoryOwner() {
        require(msg.sender == ILotteryFactory(factory).owner());
        _;
    }
    modifier onlyManagerContract() {
        require(msg.sender == managerContract);
        _;
    }

    constructor() {
        ILotteryTableDeployer.Parameters memory params = ILotteryTableDeployer(msg.sender).getParameters();
        managerContract = params.managerContract;
        factory = params.factory;
        tableInfo =  TableInfo({creator: params.creator,
                                amount:params.amount,
                                minPPL:params.minPPL,
                                maxPPL:params.maxPPL,
                                coolDownTime:params.amount,
                                gameTime:params.gameTime,
                                bankerCommission:params.bankerCommission,
                                referralCommission:params.referralCommission,
                                bankerWallet:params.bankerWallet});
    }

    //msg.sender is manager contract
    function joinTable(JoinInfo memory joinInfo) onlyManagerContract external override {
        _joinTable(joinInfo);
    }

    function _joinTable(JoinInfo memory joinInfo) private {
        _round.players.push(joinInfo.player);
        _round.numbers.push(joinInfo.number);
        _round.counts.push(joinInfo.count);
    }

    //msg.sender is manager contract
    function start() external nonReentrant onlyManagerContract returns(RoundResult memory roundResult) {
        _roundCount.increment();

        uint256 randomNumber = _getRandom(_round.players.length);
        uint256 roundNumber = randomNumber.mod(10);
        for(uint256 i = 0; i < _round.numbers.length; i++) {
            if (roundNumber == _round.numbers[i]) {
                _round.winners.push(_round.players[i]);
                _round.winnerCountMap[_round.players[i]] += _round.counts[i];
                _round.winnerAllCount += _round.counts[i];
            }
        }
        for (uint256 i = 0; i < _round.winners.length; i++) {
            _round.winnerCount.push(_round.winnerCountMap[_round.winners[i]]);
        }

        roundResult.round = _roundCount.current();
        roundResult.roundNumber = roundNumber;
        roundResult.winnerAllCount = _round.winnerAllCount;
        roundResult.players = _round.players;
        roundResult.winners = _round.winners;
        roundResult.winnerCount = _round.winnerCount;

        delete _round;
    }

    function _getRandom(uint256 playersLength) private view returns(uint256 randomNumber) {
        randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, playersLength)));
    }

    function getTableInfo() external view returns(TableInfo memory _tableInfo) {
        _tableInfo = tableInfo;
    }

    function getAllPlayers() external view returns(address[] memory allPlayers) {
        allPlayers = _round.players;
    }

    function nextRound() external view returns(uint256 round) {
        round = _roundCount.current() + 1;
    }

    function updateTableInfo(TableInfo memory _tableInfo) external onlyManagerContract {
        delete tableInfo;
        tableInfo = _tableInfo;
    }

    function getRoundInfo() external view onlyManagerContract returns(RoundInfo memory roundInfo) {
        roundInfo = RoundInfo({players:_round.players, numbers:_round.numbers, counts:_round.counts});
    }

}
