//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryTableDeployer.sol";
import "./interfaces/ILotteryFactory.sol";
import "./interfaces/ILotteryTable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./RoundInfo.sol";
import "hardhat/console.sol";

contract LotteryTable is ILotteryTable, ReentrancyGuard{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    address public immutable factory;
    address public immutable managerContract;
    TableInfo private tableInfo;
    RoundInfo roundInfo = new RoundInfo();
    uint256[] private _playersCount;//玩家下注数
    Counters.Counter private _roundCount;

    address[] private _robots;

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
        require(roundInfo.getCount(joinInfo.player) == 0, "duplicated bet!");

        _joinTable(joinInfo);
    }

    function _joinTable(JoinInfo memory joinInfo) private {
        roundInfo.pushPlayers(joinInfo.player);
        roundInfo.setCount(joinInfo.player, joinInfo.count);
        roundInfo.setNumber(joinInfo.player, joinInfo.number);
        roundInfo.addNumberCount(joinInfo.number, joinInfo.count);
    }


    //msg.sender is manager contract
    function start() external nonReentrant onlyManagerContract returns(uint256 round, uint256 roundResult, address[] memory roundWinnerArray, uint256 allCount, uint256[] memory playersCount) {
        _roundCount.increment();
        round = _roundCount.current();

        uint256 randomNumber = _getRandom(roundInfo.getPlayers().length);
        roundResult = randomNumber.mod(10);
        roundWinnerArray = roundInfo.getNumberPlayers(roundResult);
        allCount = roundInfo.getNumberCount(roundResult);
        if (roundWinnerArray.length > 0) {
            for (uint256 i = 0; i < roundWinnerArray.length; i++) {
                address winner = roundWinnerArray[i];
                uint256 count = roundInfo.getCount(winner);
                _playersCount.push(count);
            }
        }
        playersCount = _playersCount;
    }

    //重置游戏数据
    function reset() external onlyManagerContract returns (bool) {
        delete roundInfo;
        delete _playersCount;
        roundInfo = new RoundInfo();
        return true;
    }

    function _getRandom(uint256 playersLength) private view returns(uint256 randomNumber) {
        randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, playersLength)));
    }

    function getTableInfo() external view returns(TableInfo memory _tableInfo) {
        _tableInfo = tableInfo;
    }

    function getAllPlayers() external view returns(address[] memory allPlayers) {
        allPlayers = roundInfo.getPlayers();
    }

    function nextRound() external view returns(uint256 round) {
        round = _roundCount.current() + 1;
    }

    function updateTableInfo(TableInfo memory _tableInfo) external onlyManagerContract {
        delete tableInfo;
        tableInfo = _tableInfo;
    }

}
