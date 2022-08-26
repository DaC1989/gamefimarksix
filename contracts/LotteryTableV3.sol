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

        uint256[] prizeNumbers;//中奖号码
        address[] winners;//赢家
        uint256[] winnerCount;//赢家多次下注数
        uint256 winnerAllCount;//压中的总下注数

        mapping(address => bool) winnersMap;//判断玩家是否为winner
        mapping(uint256 => bool) prizeNumbersMap;
        uint256[] uniquePrizeNumbers;
        mapping(uint256 => mapping(address => bool)) numberHad;
        mapping(uint256 => address[]) numberWinnersMap;

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
                coolDownTime:params.coolDownTime,
                gameTime:params.gameTime,
                bankerCommission:params.bankerCommission,
                referralCommission:params.referralCommission,
                bankerWallet:params.bankerWallet,
                delayBlocks:params.delayBlocks,
                jackpotCommission:params.jackpotCommission
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

        bytes32 hash = _getResultBlockHash(coolDownTimeBlock);
        uint256 roundNumber = _getFirstDecimalFromHash(hash);

        //与roundNumber差值最小的号码为中奖号码
        int256 minimum;//最小差值
        for(uint256 i = 0; i < _round.numbers.length; i++) {
            int256 diff = int256(_round.numbers[i]) - int256(roundNumber);
            if (diff < 0) {
                diff = diff * (-1);
            }
            if (i == 0) {
                minimum = diff;
                continue;
            }
            if (diff < minimum) {
                minimum = diff;
            }
        }
        console.log("minimum", uint256(minimum));
        for(uint256 i = 0; i < _round.numbers.length; i++) {
            int256 diff = int256(_round.numbers[i]) - int256(roundNumber);
            if (diff < 0) {
                diff = diff * (-1);
            }
            if (diff == minimum) {
                console.log("prizeNumber", _round.numbers[i]);
                _round.prizeNumbers.push(_round.numbers[i]);
                _round.winners.push(_round.players[i]);
                _round.winnerCount.push(_round.counts[i]);
                _round.winnerAllCount += _round.counts[i];

                //for jackpot feature
                _round.winnersMap[_round.players[i]] = true;
                if(_round.prizeNumbersMap[_round.numbers[i]] == false) {
                    _round.prizeNumbersMap[_round.numbers[i]] = true;
                    _round.uniquePrizeNumbers.push(_round.numbers[i]);
                }
                if(_round.numberHad[_round.numbers[i]][_round.players[i]] == false) {
                    _round.numberHad[_round.numbers[i]][_round.players[i]] = true;
                    _round.numberWinnersMap[_round.numbers[i]].push(_round.players[i]);
                }
            }
        }

        roundResult.round = _roundCount.current();
        roundResult.roundNumber = roundNumber;
        roundResult.prizeNumbers = _round.prizeNumbers;
        roundResult.winnerAllCount = _round.winnerAllCount;
        roundResult.players = _round.players;
        roundResult.numbers = _round.numbers;
        roundResult.counts = _round.counts;
        roundResult.winners = _round.winners;
        roundResult.winnerCount = _round.winnerCount;

//        roundResult.jackpotWinners = _handleJackpot(_round.winnersMap, _round.winners, _round.prizeNumbers);

        delete _round;
    }

    mapping(address => uint256[]) recordNumbers;
    mapping(address => mapping(uint256 => uint256)) recordTimes;
    address[] lastWinners;
    address[] jackpotWinners;

    mapping(uint256 => mapping(address => bool)) numberHad;

    function _handleJackpotV2(
        mapping(address => bool) storage winnersMap,
        address[] memory winners,
        uint256[] memory winnerNumbers,
        uint256[] memory uniquePrizeNumbers,
        mapping(uint256 => mapping(address => bool)) storage numberHad,
        mapping(uint256 => address[]) storage numberWinnersMap
    ) private {
        //
        //清除本次没有中奖的玩家
        for(uint256 i = 0; i < lastWinners.length; i++) {
            if(winnersMap[lastWinners[i]] == false) {
                uint256[] memory numbers = recordNumbers[lastWinners[i]];
                for(uint256 j = 0; j < numbers.length; j++) {
                    delete recordTimes[lastWinners[i]][numbers[j]];
                }
                delete recordNumbers[lastWinners[i]];
            }
        }
        //清除中奖号码不一致的玩家

        //
        for(uint256 i = 0; i < uniquePrizeNumbers.length; i++) {
            uint256 number = uniquePrizeNumbers[i];
            address[] memory numberWinners = numberWinnersMap[number];
            for(uint256 j = 0; j < numberWinners.length; j++) {
                address winner = numberWinners[j];



                if(recordTimes[winner][number] == 2) {
                    jackpotWinners.push(winner);
                    delete recordTimes[winner][number];
                } else {
                    recordTimes[winner][number] += 1;
                    lastWinners.push(winner);
                }
            }
        }
    }

//    function _handleJackpot(mapping(address => bool) storage winnersMap, address[] memory winners, uint256[] memory winnerNumbers) private returns(address[] memory) {
//        delete jackpotWinners;
//        //清除本次没有中奖的玩家
//        for(uint256 i = 0; i < lastWinners.length; i++) {
//            if(winnersMap[lastWinners[i]] == false) {
//                uint256[] memory numbers = recordNumber[lastWinners[i]];
//                for (uint256 j = 0; j < numbers.length; j++) {
//                    delete recordTimes[lastWinners[i]][numbers[j]];
//                }
//                delete recordNumber[lastWinners[i]];
//            }
//        }
//        delete lastWinners;
//
//        for(uint256 i = 0; i < winners.length; i++) {
//            address winner = winners[i];//赢家
//            uint256 number = winnerNumbers[i];//下注号码
//
//            if (recordTimes[winner][number] == 0) {//本轮玩家上局不存在
//                recordNumber[winner].push(number);
//                recordTimes[winner][number] = 1;
//            } else if (recordTimes[winner][number] == 1) {//本轮玩家上局存在
//                if (recordNumber[winner][0] == number) {
//                    recordTimes[winner][0] += 1;
//
//                } else {
//                }
//            }
//
//            if (recordTimes[winner] == 0) {
//                recordNumber[winner] = number;
//                recordTimes[winner] = 1;
//            } else {
//                if (recordNumber[winner] == number) {
//                    recordTimes[winner] += 1;
//                } else {
//                    recordNumber[winner] = number;
//                    recordTimes[winner] = 1;
//                }
//            }
//            if (recordTimes[winner] == 3) {
//                jackpotWinners.push(winner);
//                delete recordNumber[winner];
//                delete recordTimes[winner];
//            } else {
//                lastWinners.push(winner);
//            }
//        }
//        return jackpotWinners;
//    }

    function _getResultBlockHash(uint256 coolDownTimeBlock) private view returns(bytes32 hash) {
        uint resultBlock = coolDownTimeBlock.add(tableInfo.delayBlocks);
        require(block.number > resultBlock, "current block height must higher than result block!");
        require(block.number - resultBlock < 256, "result block is too old!");
        hash = blockhash(coolDownTimeBlock.add(tableInfo.delayBlocks));
        console.log("hash to uint", uint256(hash));
        console.log("hash to toHexString", uint256(hash).toHexString());
    }

    function _getFirstDecimalFromHash(bytes32 hash) private pure returns (uint256 number) {
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
