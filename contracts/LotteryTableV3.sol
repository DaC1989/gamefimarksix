//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryTableDeployerV3.sol";
import "./interfaces/ILotteryFactoryV3.sol";
import "./interfaces/ILotteryTableV3.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

contract LotteryTableV3 is ILotteryTableV3, ReentrancyGuard{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    address public immutable factory;
    address public _managerContract;
    TableInfo private tableInfo;
    Counters.Counter private _roundCount;

    struct Round {
        address[] players;//玩家
        uint256[] numbers;//下注号码
        uint256[] counts;//下注数

        address[] winners;//赢家
        mapping(address => uint256) winnerCountMap;//赢家下注数
        uint256[] winnerCount;//赢家多次下注数
        uint256 winnerAllCount;//压中的总下注数
    }
    Round private _round;

    modifier onlyFactoryOwner() {
        require(msg.sender == ILotteryFactoryV3(factory).owner());
        _;
    }
    modifier onlyManagerContract() {
        require(msg.sender == _managerContract, "not contract manager");
        _;
    }

    constructor() {
        ILotteryTableDeployerV3.Parameters memory params = ILotteryTableDeployerV3(msg.sender).getParameters();
        _managerContract = params.managerContract;
        factory = params.factory;
        tableInfo =  TableInfo(
            {
                creator: params.creator,
                amount:params.amount,
                minPPL:params.minPPL,
                maxPPL:params.maxPPL,
                coolDownTime:params.amount,
                gameTime:params.gameTime,
                bankerCommission:params.bankerCommission,
                referralCommission:params.referralCommission,
                bankerWallet:params.bankerWallet,
                delayBlocks:params.delayBlocks
            }
        );
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
    function start(uint256 coolDownTimeBlock) external nonReentrant onlyManagerContract returns(RoundResult memory roundResult) {
        _roundCount.increment();

        uint256 resultBlock = coolDownTimeBlock.add(tableInfo.delayBlocks);
        bytes32 hash = _getResultBlockHash(coolDownTimeBlock);
        uint256 roundNumber = _getFirstDecimalFromHash(hash);
        for(uint256 i = 0; i < _round.numbers.length; i++) {
            if (roundNumber == _round.numbers[i]) {
                _round.winners.push(_round.players[i]);
                _round.winnerCount.push(_round.counts[i]);
                _round.winnerAllCount += _round.counts[i];
            }
        }

        roundResult.round = _roundCount.current();
        roundResult.roundNumber = roundNumber;
        roundResult.winnerAllCount = _round.winnerAllCount;
        roundResult.players = _round.players;
        roundResult.numbers = _round.numbers;
        roundResult.counts = _round.counts;
        roundResult.winners = _round.winners;
        roundResult.winnerCount = _round.winnerCount;

        delete _round;
    }

    function _getRandom(uint256 playersLength) private view returns(uint256 randomNumber) {
        randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, playersLength)));
    }

    function _getResultBlockHash(uint256 coolDownTimeBlock) private view returns(bytes32 hash) {
        hash = blockhash(coolDownTimeBlock.add(tableInfo.delayBlocks));
        console.log("hash to uint", uint256(hash));
        console.log("hash to toHexString", uint256(hash).toHexString());
    }

    function _getFirstDecimalFromHash(bytes32 hash) private view returns (uint256 number) {
        uint256 result;
        for(uint256 i = 0; i < hash.length; i++) {
            uint8 toInt = uint8(hash[hash.length - i - 1]);
            uint8 firstIndex = toInt % 16;
            uint8 secondIndex = toInt >> 4;
            if (firstIndex < 10) {
                result = firstIndex;
                break;
            } else if (secondIndex < 10) {
                result = secondIndex;
                break;
            }
        }
        number =  result;
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

    function changeManager(address managerContract) external onlyManagerContract returns(bool result) {
        _managerContract = managerContract;
        result = true;
    }

}
