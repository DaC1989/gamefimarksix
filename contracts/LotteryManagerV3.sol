//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryFactoryV3.sol";
//import "./libraries/TableAddress.sol";

import "hardhat/console.sol";
import "./interfaces/ILotteryTableV3.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./LotteryTableV3.sol";

contract LotteryManagerV3 {
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
    mapping(address => uint256[]) private jackpotRewardsMap;
    mapping(address => uint256) private tableBlock;//table的cool down time高度
    mapping(address => uint256) private notifyTimestampMap;//table设置cool down time时的时间戳
    mapping(address => uint256) private jackpotPool;//jackpot

    mapping(address => ILotteryTableV3.TableInfo) private waitEdit;
    mapping(string => bool) private roundLock;

    event CreateTableIfNecessary(string hash);
    event EditTable(
        string beforeHash,
        string newHash
    );
    event JoinTable(
        address player,
        uint256 count,
        uint256 number,
        string hash
    );
    event NotifyCoolDownTime(
        string hash,//table的hash
        uint256 coolDownTimeBlock,//cool down time 时刻的高度
        uint256 notifyTimestamp
    );
    struct StartRoundResult {
        string hash;//table的hash
        uint256 round;//第几轮
        uint256 poolAmount;//奖金池大小
        uint256 roundNumber;//开奖结果
        uint256[] prizeNumbers;//中奖号码
        address[] roundWinnerArray;//赢家
        uint256[] winnerCount;//赢家下注数量
        int256[] rewards;//玩家本局输赢金额
        address[] allPlayers;//所有玩家
        uint256[] numbers;//玩家下注号码
        uint256[] counts;//玩家下注数量
        address[] jackpotWinners; //jackpot赢家
        uint256[] jackpotRewards;//jackpot赢家赢的金额
    }

    struct EditTableResult {
        string beforeHash;
        string newHash;
    }

    struct RoundStatus {
        string status;//WAITING, RUNNING, END
        string result;//FAILED, SUCCESS
        string message; //
        StartRoundResult startRoundResult;
        EditTableResult editTableResult;
    }

    mapping(string => mapping(uint256 => RoundStatus)) private roundStorage;

    event StartRound (
        StartRoundResult startRoundResult
    );
    event BankerCommission(
        address player,
        address banker,
        uint256 amount
    );
    event ReferCommission(
        address player,
        address refer,
        uint256 amount
    );
    event JackpotCommission(
        address player,
        uint256 amount,
        uint256 all //当前table的jackpot金额
    );
    event JackpotWinner(
        address player, //jackpot 赢家
        uint256 jackpotPrize //jackpot奖金
    );

    //table的hash、第几轮、所有玩家, 玩家下注号码，玩家下注数量
    event HoldingTicket(
        string hash,
        uint256 round,
        address[] players,
        uint256[] numbers,
        uint256[] counts
    );

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
    function createTableIfNecessary(
        address creator,
        uint256 amount,
        uint256 minPPL,
        uint256 maxPPL,
        uint256 coolDownTime,
        uint256 gameTime,
        uint256 bankerCommission,
        uint256 referralCommission,
        address bankerWallet,
        uint256 delayBlock, //延迟开奖高度数量
        uint256 jackpotCommission //jackpot占bankerCommission比例
        //uint256 jackpotCount //jackpot命中次数
    )
    external
    onlyManagerOwner
    payable
    returns (
        string memory hashString
    ) {
        require(msg.sender == owner, "Only contract owner is allowed to call this function");
        address table = ILotteryFactoryV3(factory).getTable(address(this), creator, amount, minPPL, maxPPL, coolDownTime,
            gameTime, bankerCommission, referralCommission, bankerWallet, delayBlock, jackpotCommission);
        if (table == address(0)) {
            table = ILotteryFactoryV3(factory).createTable(address(this), creator, amount, minPPL, maxPPL, coolDownTime,
                gameTime, bankerCommission, referralCommission, bankerWallet, delayBlock, jackpotCommission);
        }
        uint256 hash = uint256(keccak256(abi.encode(address(this), creator, amount, minPPL, maxPPL, coolDownTime, gameTime,
            bankerCommission, referralCommission, bankerWallet, delayBlock, jackpotCommission)));
        hashString = hash.toString();
        hashTableMap[hashString] = table;
        tableHashMap[table] = hashString;
        console.log("table is:", table);
        console.log("table hashString is", hashString);

        emit CreateTableIfNecessary(hashString);
    }

    //msg.sender is mananger
    function editTable(
        string memory hashString,
        ILotteryTableV3.TableInfo memory tableInfo
    )
    external
    onlyManagerOwner {
        address tableAddress = hashTableMap[hashString];
        require(tableAddress != address(0), "No table with the hash, please check the hash!");

        waitEdit[tableAddress] = tableInfo;
    }

    function _tryEditTable(address tableAddress) private returns(string memory newHash){
        ILotteryTableV3.TableInfo memory tableInfo = waitEdit[tableAddress];
        if(tableInfo.creator != address(0)) {
            string memory beforeHash = tableHashMap[tableAddress];
            LotteryTableV3 lotteryTable = LotteryTableV3(tableAddress);
            lotteryTable.updateTableInfo(tableInfo);
            //更新hash
            uint256 hash = uint256(keccak256(abi.encode(tableInfo.creator, tableInfo.amount, tableInfo.minPPL, tableInfo.maxPPL,
                tableInfo.coolDownTime, tableInfo.gameTime, tableInfo.bankerCommission, tableInfo.referralCommission,
                tableInfo.bankerWallet, tableInfo.delayBlocks, tableInfo.jackpotCommission)));
            hashTableMap[hash.toString()] = tableAddress;
            tableHashMap[tableAddress] = hash.toString();
            //删除数据
            delete waitEdit[tableAddress];
            console.log("before, after", beforeHash, hash.toString());
            emit EditTable(beforeHash, hash.toString());
            newHash = hash.toString();
        }
    }

    //msg.sender is player
    // count: 下注数量, number:选择号码, tableInfo:创建合约参数
    function joinTableV2(
        uint256 count,
        uint256 number,
        string memory hash,
        uint256 currentRound
    )
    external
    payable
    returns (
        bool result
    ) {
        address tableAddress = hashTableMap[hash];
        require(tableAddress != address(0), "no table with the hash, please check the hash!");
        uint256 coolDownTimeBlock = tableBlock[tableAddress];
        if (coolDownTimeBlock != 0 && block.number >= coolDownTimeBlock) {
            revert("arrived cool down time block, can not join this round!");
        }
        address referraler = referralMap[msg.sender];
        LotteryTableV3 lotteryTable = LotteryTableV3(tableAddress);
        ILotteryTableV3.JoinInfo memory joinInfo = ILotteryTableV3.JoinInfo({player: msg.sender, count:count, number: number, referraler:referraler, round:currentRound});
        lotteryTable.joinTable(joinInfo);

        ILotteryTableV3.TableInfo memory tableInfo = lotteryTable.getTableInfo();
        _afterJoinTable(count, tableInfo, tableAddress);

        emit JoinTable(msg.sender, count, number, hash);
        result = true;
    }

    function _afterJoinTable(uint256 count, ILotteryTableV3.TableInfo memory tableInfo, address tableAddress) private {
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

            //jackpotCommission
            if (tableInfo.jackpotCommission > 0) {
                uint256 jackpotCommissionAmount = bankerCommissionAmount.div(10000).mul(tableInfo.jackpotCommission);
                require(tablePool[tableAddress] >= jackpotCommissionAmount, "Table pool not enough for jackpotCommission!");
                //减少资金池
                tablePool[tableAddress] -= jackpotCommissionAmount;
                //增加jackpot池
                jackpotPool[tableAddress] += jackpotCommissionAmount;
                emit JackpotCommission(msg.sender, jackpotCommissionAmount, jackpotPool[tableAddress]);
            }
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

        LotteryTableV3 lotteryTableV3 = LotteryTableV3(tableAddress);
        ILotteryTableV3.TableInfo memory tableInfo = lotteryTableV3.getTableInfo();
        //获取开奖结果
        //校验cool down time的高度
        uint256 coolDownTimeBlock = tableBlock[tableAddress];
        require(coolDownTimeBlock > 0, "wrong coolDownTimeBlock");

        ILotteryTableV3.RoundResult memory roundResult = lotteryTableV3.start(coolDownTimeBlock);
        console.log("round, roundNumber, roundResult.winnerAllCount", roundResult.round, roundResult.roundNumber, roundResult.winnerAllCount);

        uint256 poolAmount = tablePool[tableAddress];
        console.log("poolAmount, roundResult.winners.length", poolAmount, roundResult.winners.length);
        //计算一份奖金是多少
        (bool flag, uint256 onePieceReward) = poolAmount.tryDiv(roundResult.winnerAllCount);
        console.log("onePieceReward", onePieceReward);
        //给赢家转账
        for (uint256 i = 0; i < roundResult.winners.length; i++) {
            address winner = roundResult.winners[i];
            uint256 count = roundResult.winnerCount[i];
            uint256 winAmount = onePieceReward.mul(count);
            console.log("tablePool[tableAddress], winAmount", tablePool[tableAddress], winAmount);
            require(tablePool[tableAddress] >= winAmount, "table pool not enough for winAmount!");
            tablePool[tableAddress] -= winAmount;
            if (uint160(winner) < uint160(1000000000)) {
                console.log("winner is robot, winAmount", winAmount);
                token.transfer(msg.sender, winAmount);
            } else {
                token.transfer(winner, winAmount);
            }
        }
        //给jackpotWinner转账
        if (roundResult.jackpotWinners.length > 0) {
            uint256 jackpotAll = jackpotPool[tableAddress];
            console.log("jackpotAll", jackpotAll);
            console.log("roundResult.jackpotWinners.length", roundResult.jackpotWinners.length);
            (bool flag, uint256 onePieceJackpot) = jackpotAll.tryDiv(roundResult.jackpotWinners.length);
            if (flag && onePieceJackpot > 0) {
                for(uint256 i = 0; i < roundResult.jackpotWinners.length; i++) {
                    address winner = roundResult.jackpotWinners[i];
                    require(jackpotPool[tableAddress] >= onePieceJackpot, "jackpot pool not enough!");
                    jackpotPool[tableAddress] -= onePieceJackpot;
                    jackpotRewardsMap[tableAddress].push(onePieceJackpot);
                    if (uint160(winner) < uint160(1000000000)) {
                        token.transfer(msg.sender, onePieceJackpot);
                    } else {
                        token.transfer(winner, onePieceJackpot);
                    }
                    emit JackpotWinner(winner, onePieceJackpot);
                }
            }
        }
        //计算所有玩家输赢多少
        for(uint256 i = 0; i < roundResult.players.length; i++) {
            int256 reward;
            if (roundResult.prizeNumbers.length == 1) {
                if (roundResult.numbers[i] == roundResult.prizeNumbers[0]) {
                    reward = int256(onePieceReward.mul(roundResult.counts[i]));
                } else {
                    reward = (-1) * int256(tableInfo.amount.mul(roundResult.counts[i]));
                }
            } else if (roundResult.prizeNumbers.length == 2) {
                if (roundResult.numbers[i] == roundResult.prizeNumbers[0] || roundResult.numbers[i] == roundResult.prizeNumbers[1]) {
                    reward = int256(onePieceReward.mul(roundResult.counts[i]));
                } else {
                    reward = (-1) * int256(tableInfo.amount.mul(roundResult.counts[i]));
                }
            }
            rewardsMap[tableAddress].push(reward);
        }

        //尝试修改桌子
        string memory newHash = _tryEditTable(tableAddress);
        //事件
        _roundEvent(hash, poolAmount, roundResult, newHash);

        delete rewardsMap[tableAddress];
        delete jackpotRewardsMap[tableAddress];
        delete tableBlock[tableAddress];
        delete notifyTimestampMap[tableAddress];
        return true;
    }

    function _roundEvent(string memory hash, uint256 poolAmount, ILotteryTableV3.RoundResult memory roundResult, string memory newHash) private {
        address tableAddress = hashTableMap[hash];

        StartRoundResult memory startRoundResult = StartRoundResult(
            {
                hash:hash,
                round:roundResult.round,
                poolAmount:poolAmount,
                roundNumber:roundResult.roundNumber,
                prizeNumbers:roundResult.prizeNumbers,
                roundWinnerArray:roundResult.winners,
                winnerCount:roundResult.winnerCount,
                rewards:rewardsMap[tableAddress],
                allPlayers:roundResult.players,
                numbers:roundResult.numbers,
                counts:roundResult.counts,
                jackpotWinners:roundResult.jackpotWinners,
                jackpotRewards:jackpotRewardsMap[tableAddress]
            }
        );
        EditTableResult memory editTableResult = EditTableResult({
            beforeHash: hash,
            newHash: newHash
        });

        //状态修改
        RoundStatus memory roundStatus = RoundStatus({
            status: "END",
            result: "SUCCESS",
            message:"SUCCESS",
            startRoundResult:startRoundResult,
            editTableResult: editTableResult
        });
        roundStorage[hash][roundResult.round] = roundStatus;
        emit StartRound(startRoundResult);
    }

    //通知合约table已到cool down time
    function notifyCoolDownTime(string memory hash) external onlyManagerOwner returns (uint256 coolDownTimeBlock) {
        address tableAddress = hashTableMap[hash];
        require(tableAddress != address(0), "please check the address!");

        coolDownTimeBlock = block.number;
        console.log("block.number", coolDownTimeBlock);
        tableBlock[tableAddress] = coolDownTimeBlock;
        uint256 timestamp = block.timestamp;
        notifyTimestampMap[tableAddress] = block.timestamp;

        LotteryTableV3 lotteryTableV3 = LotteryTableV3(tableAddress);
        ILotteryTableV3.TableInfo memory tableInfo = lotteryTableV3.getTableInfo();
        //机器人下注
        _robotJoinTable(tableInfo, tableAddress);

        emit NotifyCoolDownTime(hash, coolDownTimeBlock, block.timestamp);
    }

    function _getRandom(uint256 playersLength) private view returns(uint256 randomNumber) {
        randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, playersLength)));
    }

    function _robotJoinTable(ILotteryTableV3.TableInfo memory tableInfo, address tableAddress) private {
        LotteryTableV3 lotteryTable = LotteryTableV3(tableAddress);
        address[] memory allPlayers = lotteryTable.getAllPlayers();
        uint256 allPlayersLength = allPlayers.length;
        if(allPlayersLength < tableInfo.minPPL) {
            uint256 gap = tableInfo.minPPL.sub(allPlayersLength);
            uint256 round = lotteryTable.nextRound();
            //机器人下注
            for(uint256 i = 0; i < gap; i++) {
                uint256 number = _getRandom(i).mod(10);
                address robotAddress = address(uint160(i));
                //
                ILotteryTableV3.JoinInfo memory joinInfo = ILotteryTableV3.JoinInfo({player:robotAddress, count: 1, number:number, referraler:address(0), round:round});
                lotteryTable.joinTable(joinInfo);
                _afterJoinTable(1, tableInfo, tableAddress);

            }
        }
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

        LotteryTableV3 lotteryTable = LotteryTableV3(tableAddress);
        ILotteryTableV3.RoundInfo memory roundInfo = lotteryTable.getRoundInfo();
        uint256 roundCount = lotteryTable.nextRound();

        tableHash = hash;
        round = roundCount;
        players = roundInfo.players;
        numbers = roundInfo.numbers;
        counts = roundInfo.counts;
    }

    //查询cool down time block
    function getCoolDownTimeBlock(string memory hash)
    external
    view
    returns(
        uint256 coolDownTimeBlock,
        uint256 notifyTimestamp
    ) {
        address tableAddress = hashTableMap[hash];
        require(tableAddress != address(0), "please check the address!");

        coolDownTimeBlock = tableBlock[tableAddress];
        notifyTimestamp = notifyTimestampMap[tableAddress];
    }

    function getTableInfo(string memory hash) external
    view
    returns(
        ILotteryTableV3.TableInfo memory tableInfo
    ) {
        address tableAddress = hashTableMap[hash];
        require(tableAddress != address(0), "please check the address!");

        LotteryTableV3 lotteryTable = LotteryTableV3(tableAddress);
        tableInfo = lotteryTable.getTableInfo();
    }

    function getRoundStatus(string memory hash, uint256 round) external view returns(RoundStatus memory roundStatus) {
        roundStatus = roundStorage[hash][round];
    }

    //修改table的manage contract
    function changeTableManager(string memory hash, address newManagerContract)
    external
    onlyManagerOwner
    returns(bool result) {
        address tableAddress = hashTableMap[hash];
        require(tableAddress != address(0), "please check the address!");

        LotteryTableV3 lotteryTable = LotteryTableV3(tableAddress);
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
