//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryFactory.sol";
import "./libraries/TableAddress.sol";

import "hardhat/console.sol";
import "./interfaces/ILotteryTable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LotteryManager {
    using SafeMath for uint256;
    using Strings for uint256;

    address public immutable factory;
    IERC20 private token;
    address public owner;
    mapping(address => address) private referralMap;
    mapping(string => address) private hashTable;
    mapping(address => string) private tableHash;
    mapping(address => uint256) private tablePool;

    mapping(address => ILotteryTable.TableInfo) private waitEdit;

    event CreateTableIfNecessary(string hash);
    event EditTable(string beforeHash, string newHash);
    event JoinTable(address player, uint256 count, uint256 number, string hash);
    //table的hash、第几轮、开奖结果、赢家、所有玩家
    event StartRound(string hash, uint256 round, uint256 roundResult, address[] roundWinnerArray, address[] allPlayers);

    constructor(address _factory, address _tokenAddress) {
        factory = _factory;
        token = IERC20(address(_tokenAddress));
        owner = msg.sender;
    }

    modifier onlyManagerOwner() {
        require(msg.sender == owner);
        _;
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
        hashTable[hashString] = table;
        tableHash[table] = hashString;
        console.log("table is:", table);
        console.log("hashString is:", hashString);

        emit CreateTableIfNecessary(hashString);
    }

    //msg.sender is mananger
    function editTable(string memory hashString, ILotteryTable.TableInfo memory tableInfo) external onlyManagerOwner {
        address tableAddress = hashTable[hashString];
        require(tableAddress != address(0), "No table with the hash, please check the hash!");

        waitEdit[tableAddress] = tableInfo;
    }

    function _editTable(address tableAddress) private returns(bool){
        ILotteryTable.TableInfo memory tableInfo = waitEdit[tableAddress];
        console.log("ask", tableInfo.minPPL);
        if(tableInfo.creator != address(0)) {
            string memory beforeHash = tableHash[tableAddress];
            LotteryTable lotteryTable = LotteryTable(tableAddress);
            lotteryTable.updateTableInfo(tableInfo);
            console.log("now", lotteryTable.getTableInfo().minPPL);
            //更新hash
            uint256 hash = uint256(keccak256(abi.encode(tableInfo.creator, tableInfo.amount, tableInfo.minPPL, tableInfo.maxPPL, tableInfo.coolDownTime, tableInfo.gameTime, tableInfo.bankerCommission, tableInfo.referralCommission, tableInfo.bankerWallet)));
            hashTable[hash.toString()] = tableAddress;
            tableHash[tableAddress] = hash.toString();
            //删除数据
            delete waitEdit[tableAddress];
            console.log("beforeHash, hash.toString()", beforeHash, hash.toString());
            emit EditTable(beforeHash, hash.toString());
            return true;
        } else {
            return false;
        }
    }

    function joinTableV1(ILotteryTable.TableInfo memory tableInfo)
    external payable returns (bool result) {
        console.log("tableInfo is:", tableInfo.creator);
        TableAddress.TableKey memory tableKey = TableAddress.TableKey({factory: factory, creator: tableInfo.creator, amount: tableInfo.amount,
            minPPL:tableInfo.minPPL, maxPPL: tableInfo.maxPPL, coolDownTime: tableInfo.coolDownTime,
            gameTime: tableInfo.gameTime, bankerCommission: tableInfo.bankerCommission, referralCommission: tableInfo.referralCommission,
            bankerWallet: tableInfo.bankerWallet});
        address tableAddress = TableAddress.computeAddressV1(factory, tableKey);
        console.log("tableAddress is", tableAddress);
        result = true;
    }

    //msg.sender is player
    // count: 下注数量, number:下注数字, tableInfo:创建合约参数
    function joinTableV2(uint256 count, uint256 number, string memory hash)
    external payable returns (bool result) {
        console.log("joinTableV2 hash is", hash);
        address referraler = referralMap[msg.sender];
        address tableAddress = hashTable[hash];
        console.log("tableAddress is", tableAddress);
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
        console.log("_afterJoinTable", msg.sender);
        console.log("balance of address(this):" , address(this), token.balanceOf(address(this)));
        token.transferFrom(msg.sender, address(this), betAmount);
        console.log("balance of address(this):" , address(this), token.balanceOf(address(this)));
        //增加资金池
        tablePool[tableAddress] += betAmount;

        //bankerCommission
        console.log("betAmount, tableInfo.bankerCommission", betAmount, tableInfo.bankerCommission);
        if (tableInfo.bankerCommission > 0) {
            uint256 bankerCommissionAmount = betAmount.div(10000).mul(tableInfo.bankerCommission);
            console.log("bankerCommissionAmount", bankerCommissionAmount);
            require(tablePool[tableAddress] >= bankerCommissionAmount, "Table pool not enough for bankerCommission!");
            //减少资金池
            tablePool[tableAddress] -= bankerCommissionAmount;
            token.transfer(tableInfo.bankerWallet, bankerCommissionAmount);
            console.log("balance of address(this):" , address(this), token.balanceOf(address(this)));
        }

        //referralCommission
        address referraler = referralMap[msg.sender];
        if (referraler != address(0) && tableInfo.referralCommission > 0) {
            uint256 referralCommission = betAmount.div(10000).mul(tableInfo.referralCommission);
            require(tablePool[tableAddress] >= referralCommission, "Table pool not enough for referralCommission!");
            //减少资金池
            tablePool[tableAddress] -= referralCommission;
            token.transfer(referraler, referralCommission);
        }
    }

    //msg.sender is manager owner
    //启动一局
    //hash:合约hash
    function startRoundV2(string memory hash) external onlyManagerOwner payable returns (bool) {
        address tableAddress = hashTable[hash];
        require(tableAddress != address(0), "please check the address!");

        LotteryTable lotteryTable = LotteryTable(tableAddress);
        ILotteryTable.TableInfo memory tableInfo = lotteryTable.getTableInfo();
        //机器人下注
        _robotJoinTable(tableInfo, tableAddress);
        //获取开奖结果
        (uint256 round, uint256 roundResult, address[] memory roundWinnerArray, uint256 allCount, uint256[] memory playersCount) = lotteryTable.start();
        console.log("roundResult", roundResult);
        //根据结果转账
        uint256 poolAmount = tablePool[tableAddress];
        console.log("poolAmount", poolAmount);
        if (roundWinnerArray.length == 0) {
            //没有赢家就全部转给banker
            tablePool[tableAddress] = 0;
            token.transfer(tableInfo.bankerWallet, poolAmount);
        } else {
            for (uint256 i = 0; i < roundWinnerArray.length; i++) {
                address winner = roundWinnerArray[i];
                uint256 count = playersCount[i];
                console.log("count, allCount", count, allCount);
                //给赢家转账
                uint256 winAmount = poolAmount.div(allCount).mul(count);
                console.log("winAmount", winAmount);
                require(tablePool[tableAddress] >= winAmount, "table pool not enough for winAmount!");
                tablePool[tableAddress] -= winAmount;
                console.log("winner", winner);
                if (uint160(winner) < uint160(1000000000)) {
                    console.log("token.balanceOf(msg.sender)", token.balanceOf(msg.sender));
                    token.transfer(msg.sender, winAmount);
                    console.log("token.balanceOf(msg.sender)", token.balanceOf(msg.sender));
                } else {
                    console.log("token.balanceOf(winner)", token.balanceOf(winner));
                    token.transfer(winner, winAmount);
                    console.log("token.balanceOf(winner)", token.balanceOf(winner));
                }
            }
        }
        //_reset
        lotteryTable.reset();
        //尝试修改桌子
        _editTable(tableAddress);
        //事件
        address[] memory allPlayers = lotteryTable.getAllPlayers();
        emit StartRound(hash, round, roundResult, roundWinnerArray, allPlayers);
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
                console.log("add robot ", i);
                uint256 number = _getRandom(i).mod(10);
                address robotAddress = address(uint160(i));
                console.log("robots address", robotAddress);
                console.log("robots address uint160", uint160(robotAddress));
                console.log("robots number", number);
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

    function _afterRound() internal {}

    //referral a:被邀请人；b：邀请人
    function referral(address a, address b) external onlyManagerOwner returns (bool result) {
        require(a != address(0));
        require(b != address(0));
        require(a != b);
        referralMap[a] = b;

        result = true;
    }


}
