//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryFactory.sol";
//import "./libraries/TableAddress.sol";

import "hardhat/console.sol";
import "./interfaces/ILotteryTable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./LotteryTable.sol";

contract LotteryManager {
    using SafeMath for uint256;
    using Strings for uint256;

    address public immutable factory;
    IERC20 private token;
    address public owner;
    mapping(address => address) private referralMap;
    mapping(string => address) private hashTableMap;
    mapping(address => string) private tableHashMap;
    mapping(address => uint256) private tablePool;
    mapping(address => int256[]) private rewardsMap;

    int256[] rewardsArray;//玩家

    mapping(address => ILotteryTable.TableInfo) private waitEdit;
    mapping(string => bool) roundLock;

    event CreateTableIfNecessary(string hash);
    event EditTable(string beforeHash, string newHash);
    event JoinTable(address player, uint256 count, uint256 number, string hash);
    //table的hash、第几轮、奖金池大小、开奖结果、赢家、赢家获得的金额、所有玩家、玩家下注号码、玩家下注数量
    event StartRound(
        string hash,//table的hash
        uint256 round,//第几轮
        uint256 poolAmount,//奖金池大小
        uint256 roundNumber,//开奖结果
        address[] roundWinnerArray,//赢家
        uint256[] winnerCount,//赢家下注数量
        int256[] rewards,//玩家本局输赢金额
        address[] allPlayers,//所有玩家
        uint256[] numbers,//玩家下注号码
        uint256[] counts//玩家下注数量
    );
    event BankerCommission(address player, address banker, uint256 amount);
    event ReferCommission(address player, address refer, uint256 amount);
    //table的hash、第几轮、所有玩家, 玩家下注号码，玩家下注数量
    event HoldingTicket(string hash, uint256 round, address[] players, uint256[] numbers, uint256[] counts);

    constructor(address _factory, address _tokenAddress) {
        factory = _factory;
        token = IERC20(address(_tokenAddress));
        owner = msg.sender;
    }

    modifier onlyManagerOwner() {
        require(msg.sender == owner, "msg.sender is not the owner");
        _;
    }

    modifier roundNoReentrant(string memory hash) {
        require(!roundLock[hash], "No re-entrancy round");
        roundLock[hash] = true;
        _;
        roundLock[hash] = false;
    }

    //创建table
    //msg.sender is manager
    //return table的hash
    function createTableIfNecessary(address creator, uint256 amount, uint256 minPPL,
                                    uint256 maxPPL, uint256 coolDownTime, uint256 gameTime,
                                    uint256 bankerCommission, uint256 referralCommission, address bankerWallet)
    external onlyManagerOwner payable returns (string memory hashString) {
        require(msg.sender == owner, "Only contract owner is allowed to call this function");
        address table = ILotteryFactory(factory).getTable(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet);
        if (table == address(0)) {
            table = ILotteryFactory(factory).createTable(address(this), creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet);
        }
        uint256 hash = uint256(keccak256(abi.encode(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet)));
        hashString = hash.toString();
        hashTableMap[hashString] = table;
        tableHashMap[table] = hashString;
        console.log("table is:", table);
        console.log("table hashString is", hashString);

        emit CreateTableIfNecessary(hashString);
    }

    //msg.sender is mananger
    function editTable(string memory hashString, ILotteryTable.TableInfo memory tableInfo) external onlyManagerOwner {
        address tableAddress = hashTableMap[hashString];
        require(tableAddress != address(0), "No table with the hash, please check the hash!");

        waitEdit[tableAddress] = tableInfo;
    }

    function _tryEditTable(address tableAddress) private returns(bool){
        ILotteryTable.TableInfo memory tableInfo = waitEdit[tableAddress];
        if(tableInfo.creator != address(0)) {
            string memory beforeHash = tableHashMap[tableAddress];
            LotteryTable lotteryTable = LotteryTable(tableAddress);
            lotteryTable.updateTableInfo(tableInfo);
            //更新hash
            uint256 hash = uint256(keccak256(abi.encode(tableInfo.creator, tableInfo.amount, tableInfo.minPPL, tableInfo.maxPPL, tableInfo.coolDownTime, tableInfo.gameTime, tableInfo.bankerCommission, tableInfo.referralCommission, tableInfo.bankerWallet)));
            hashTableMap[hash.toString()] = tableAddress;
            tableHashMap[tableAddress] = hash.toString();
            //删除数据
            delete waitEdit[tableAddress];
            console.log("before, after", beforeHash, hash.toString());
            emit EditTable(beforeHash, hash.toString());
            return true;
        } else {
            return false;
        }
    }

    //msg.sender is player
    // count: 下注数量, number:下注数字, tableInfo:创建合约参数
    function joinTableV2(uint256 count, uint256 number, string memory hash)
    external payable returns (bool result) {
        address referraler = referralMap[msg.sender];
        address tableAddress = hashTableMap[hash];
        require(tableAddress != address(0), "no table with the hash, please check the hash!");

        LotteryTable lotteryTable = LotteryTable(tableAddress);
        ILotteryTable.JoinInfo memory joinInfo = ILotteryTable.JoinInfo({player: msg.sender, count:count, number: number, referraler:referraler});
        lotteryTable.joinTable(joinInfo);

        ILotteryTable.TableInfo memory tableInfo = lotteryTable.getTableInfo();
        _afterJoinTable(count, tableInfo, tableAddress);

        emit JoinTable(msg.sender, count, number, hash);
        result = true;
    }

    function _afterJoinTable(uint256 count, ILotteryTable.TableInfo memory tableInfo, address tableAddress) private {
        uint256 betAmount = count.mul(tableInfo.amount);
        //player转给manager contract
        token.transferFrom(msg.sender, address(this), betAmount);
        //增加资金池
        tablePool[tableAddress] += betAmount;

        //bankerCommission
        if (tableInfo.bankerCommission > 0) {
            uint256 bankerCommissionAmount = betAmount.div(10000).mul(tableInfo.bankerCommission);
            require(tablePool[tableAddress] >= bankerCommissionAmount, "Table pool not enough for bankerCommission!");
            //减少资金池
            tablePool[tableAddress] -= bankerCommissionAmount;
            token.transfer(tableInfo.bankerWallet, bankerCommissionAmount);
            emit BankerCommission(msg.sender, tableInfo.bankerWallet, bankerCommissionAmount);
        }

        //referralCommission
        address referraler = referralMap[msg.sender];
        if (referraler != address(0) && tableInfo.referralCommission > 0) {
            uint256 referralCommission = betAmount.div(10000).mul(tableInfo.referralCommission);
            require(tablePool[tableAddress] >= referralCommission, "Table pool not enough for referralCommission!");
            //减少资金池
            tablePool[tableAddress] -= referralCommission;
            token.transfer(referraler, referralCommission);
            emit ReferCommission(msg.sender, referraler, referralCommission);
        }
    }

    //msg.sender is manager owner
    //启动一局
    //hash:合约hash
    function startRoundV2(string memory hash) external onlyManagerOwner roundNoReentrant(hash) payable returns (bool) {
        address tableAddress = hashTableMap[hash];
        require(tableAddress != address(0), "please check the address!");

        LotteryTable lotteryTable = LotteryTable(tableAddress);
        ILotteryTable.TableInfo memory tableInfo = lotteryTable.getTableInfo();
        //机器人下注
        _robotJoinTable(tableInfo, tableAddress);
        //获取开奖结果
        ILotteryTable.RoundResult memory roundResult = lotteryTable.start();
        console.log("round, roundNumber, roundResult.winnerAllCount", roundResult.round, roundResult.roundNumber, roundResult.winnerAllCount);
        uint256 poolAmount = tablePool[tableAddress];
        console.log("poolAmount, roundResult.winners.length", poolAmount, roundResult.winners.length);
        //计算一份奖金是多少
        (bool flag, uint256 onePieceReward) = poolAmount.tryDiv(roundResult.winnerAllCount);
        console.log("onePieceReward", onePieceReward);
        //按allPlayers计算玩家输赢多少
        for(uint256 i = 0; i < roundResult.players.length; i++) {
            int256 reward;
            if (roundResult.numbers[i] == roundResult.roundNumber) {
                reward = int256(onePieceReward.mul(roundResult.counts[i]));
            } else {
                reward = (-1) * int256(tableInfo.amount.mul(roundResult.counts[i]));
            }
            rewardsMap[tableAddress].push(reward);
        }

        //根据结果转账
        if (roundResult.winners.length == 0) {
            //没有赢家就全部转给banker
            tablePool[tableAddress] = 0;
            token.transfer(tableInfo.bankerWallet, poolAmount);
        } else {
            for (uint256 i = 0; i < roundResult.winners.length; i++) {
                address winner = roundResult.winners[i];
                uint256 count = roundResult.winnerCount[i];
                //给赢家转账
                uint256 winAmount = onePieceReward.mul(count);
                console.log("tablePool[tableAddress], winAmount", tablePool[tableAddress], winAmount);
                //require(tablePool[tableAddress] >= winAmount, "table pool not enough for winAmount!");
                //TODO 为啥polygon会报错？先这么设置
                if (tablePool[tableAddress] < winAmount) {
                    winAmount = tablePool[tableAddress];
                }
                tablePool[tableAddress] -= winAmount;
                if (uint160(winner) < uint160(1000000000)) {
                    console.log("winner is robot, winAmount", winAmount);
                    token.transfer(msg.sender, winAmount);
                } else {
                    token.transfer(winner, winAmount);
                }
            }
        }
        //尝试修改桌子
        _tryEditTable(tableAddress);
        //事件
        emit StartRound(hash, roundResult.round, poolAmount, roundResult.roundNumber, roundResult.winners, roundResult.winnerCount, rewardsMap[tableAddress], roundResult.players, roundResult.numbers, roundResult.counts);
        delete rewardsMap[tableAddress];
        return true;
    }

    function _robotJoinTable(ILotteryTable.TableInfo memory tableInfo, address tableAddress) private {
        LotteryTable lotteryTable = LotteryTable(tableAddress);
        address[] memory allPlayers = lotteryTable.getAllPlayers();
        uint256 allPlayersLength = allPlayers.length;
        if(allPlayersLength < tableInfo.minPPL) {
            uint256 gap = tableInfo.minPPL.sub(allPlayersLength);
            //机器人下注
            for(uint256 i = 0; i < gap; i++) {
                uint256 number = _getRandom(i).mod(10);
                address robotAddress = address(uint160(i));
                //
                ILotteryTable.JoinInfo memory joinInfo = ILotteryTable.JoinInfo({player:robotAddress, count: 1, number:number, referraler:address(0)});
                lotteryTable.joinTable(joinInfo);
                _afterJoinTable(1, tableInfo, tableAddress);
            }
        }
    }

    function _getRandom(uint256 playersLength) private view returns(uint256 randomNumber) {
        randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, playersLength)));
    }

    //referral a:被邀请人；b：邀请人
    function referral(address a, address b) external onlyManagerOwner returns (bool result) {
        require(a != address(0));
        require(b != address(0));
        require(a != b);
        referralMap[a] = b;

        result = true;
    }

    //table下注情况
    function holdingTicket(string memory hash)
    external
    view
    returns(
        string memory tableHash,
        uint256 round,
        address[] memory players,
        uint256[] memory numbers,
        uint256[] memory counts
    ) {
        address tableAddress = hashTableMap[hash];
        require(tableAddress != address(0), "please check the address!");

        LotteryTable lotteryTable = LotteryTable(tableAddress);
        ILotteryTable.RoundInfo memory roundInfo = lotteryTable.getRoundInfo();
        uint256 roundCount = lotteryTable.nextRound();

        tableHash = hash;
        round = roundCount;
        players = roundInfo.players;
        numbers = roundInfo.numbers;
        counts = roundInfo.counts;
    }

    //修改table的manage contract
    function changeTableManager(string memory hash, address newManagerContract)
    external
    onlyManagerOwner
    returns(bool result) {
        address tableAddress = hashTableMap[hash];
        require(tableAddress != address(0), "please check the address!");

        LotteryTable lotteryTable = LotteryTable(tableAddress);
        result = lotteryTable.changeManager(newManagerContract);
    }

    //
    function changeOwner(address newOwner)
    external
    onlyManagerOwner
    returns(bool result){
        owner = newOwner;
        result = true;
    }

}
