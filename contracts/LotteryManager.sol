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
    IERC20 public token;
    address owner;
    mapping(address => address) private referralMap;
    mapping(string => address) private hashTable;
    mapping(address => string) private tableHash;
    mapping(address => uint256) private tablePool;

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
    function createTableIfNecessary(address creator, uint256 amount, uint256 minPPL,
                                    uint256 maxPPL, uint256 coolDownTime, uint256 gameTime,
                                    uint256 bankerCommission, uint256 referralCommission, address bankerWallet)
    external onlyManagerOwner payable returns (string memory hashString) {
        require(msg.sender == owner, "Only contract owner is allowed to call this function");
        address table = ILotteryFactory(factory).getTable(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet);
        if (table == address(0)) {
            table = ILotteryFactory(factory).createTable(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet);
        }
        console.log("table is:", table);
        uint256 hash = uint256(keccak256(abi.encode(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet)));
        hashString = hash.toString();
        hashTable[hashString] = table;
        tableHash[table] = hashString;
    }

    function editTable(string memory hashString, ILotteryTable.TableInfo memory tableInfo) external onlyManagerOwner {
        address tableAddress = hashTable[hashString];
        require(tableAddress != address(0), "no table with the hash, please check the hash!");

        LotteryTable lotteryTable = LotteryTable(tableAddress);

    }


    //msg.sender is player
    // count: 下注数量, number:下注数字, tableInfo:创建合约参数
    function joinTableV1(uint256 count, uint256 number, ILotteryTable.TableInfo memory tableInfo)
    external payable returns (bool result) {
        address referraler = referralMap[msg.sender];
        uint256 hash = uint256(keccak256(abi.encode(tableInfo.creator, tableInfo.amount, tableInfo.minPPL, tableInfo.maxPPL, tableInfo.coolDownTime, tableInfo.gameTime, tableInfo.bankerCommission, tableInfo.referralCommission, tableInfo.bankerWallet)));
        address tableAddress = hashTable[hash.toString()];
        require(tableAddress != address(0), "please check the address!");

        //TableAddress.TableKey memory tableKey = TableAddress.TableKey({factory: factory, creator: tableInfo.creator, amount: tableInfo.amount, minPPL:tableInfo.minPPL, maxPPL: tableInfo.maxPPL, coolDownTime: tableInfo.coolDownTime, gameTime: tableInfo.gameTime, bankerCommission: tableInfo.bankerCommission, referralCommission: tableInfo.referralCommission, bankerWallet: tableInfo.bankerWallet});
        //address tableAddress = TableAddress.computeAddressV1(factory, tableKey);

        LotteryTable lotteryTable = LotteryTable(tableAddress);
        ILotteryTable.JoinInfo memory joinInfo = ILotteryTable.JoinInfo({player: msg.sender, count:count, number: number, referraler:referraler});
        lotteryTable.joinTable(joinInfo);
        _afterJoinTable(count, tableInfo, tableAddress);

        result = true;
    }

    //msg.sender is player
    // count: 下注数量, number:下注数字, tableInfo:创建合约参数
    function joinTableV2(uint256 count, uint256 number, string memory hash)
    external payable returns (bool result) {
        address referraler = referralMap[msg.sender];
        address tableAddress = hashTable[hash];
        require(tableAddress != address(0), "no table with the hash, please check the hash!");

        LotteryTable lotteryTable = LotteryTable(tableAddress);
        ILotteryTable.JoinInfo memory joinInfo = ILotteryTable.JoinInfo({player: msg.sender, count:count, number: number, referraler:referraler});
        lotteryTable.joinTable(joinInfo);

        ILotteryTable.TableInfo memory tableInfo = lotteryTable.getTableInfo();
        _afterJoinTable(count, tableInfo, tableAddress);

        result = true;
    }

    function _afterJoinTable(uint256 count, ILotteryTable.TableInfo memory tableInfo, address tableAddress) internal {
        uint256 betAmount = count.mul(tableInfo.amount);
        //转给manager
        token.transferFrom(msg.sender, address(this), betAmount);
        console.log("balance of address(this):" , address(this), token.balanceOf(address(this)));
        //增加资金池
        tablePool[tableAddress] += betAmount;
        //bankerCommission
        uint256 bankerCommissionAmount = betAmount.div(10000).mul(tableInfo.bankerCommission);
        require(tablePool[tableAddress] > bankerCommissionAmount, "pool not enough for bankerCommission!");
        //减少资金池
        tablePool[tableAddress] -= bankerCommissionAmount;
        token.transfer(tableInfo.bankerWallet, bankerCommissionAmount);
        console.log("balance of address(this):" , address(this), token.balanceOf(address(this)));
        //referralCommission
        address referraler = referralMap[msg.sender];
        if (referraler != address(0)) {
            uint256 referralCommission = betAmount.div(10000).mul(tableInfo.referralCommission);
            require(tablePool[tableAddress] > referralCommission, "pool not enough for referralCommission!");
            //减少资金池
            tablePool[tableAddress] -= referralCommission;
            token.transfer(referraler, referralCommission);
        }
    }

    //msg.sender is manager
    //启动一局
    //tableInfo:创建合约参数
    function startRoundV1(ILotteryTable.TableInfo memory tableInfo) external onlyManagerOwner payable returns (uint256, uint256, address[] memory, address[] memory ) {
        uint256 hash = uint256(keccak256(abi.encode(tableInfo.creator, tableInfo.amount, tableInfo.minPPL, tableInfo.maxPPL, tableInfo.coolDownTime, tableInfo.gameTime, tableInfo.bankerCommission, tableInfo.referralCommission, tableInfo.bankerWallet)));
        address tableAddress = hashTable[hash.toString()];
        require(tableAddress != address(0), "please check the address!");

        LotteryTable lotteryTable = LotteryTable(tableAddress);
        (uint256 round, uint256 roundResult, address[] memory roundWinnerArray, uint256 allCount, uint256[] memory playersCount) = lotteryTable.start();
        console.log("roundResult", roundResult);

        //根据结果转账
        if (roundWinnerArray.length == 0) {
            //没有赢家就全部转给banker
            tablePool[tableAddress] = 0;
            token.transfer(tableInfo.bankerWallet, tablePool[tableAddress]);
        } else {
            uint256 poolAmount = tablePool[tableAddress];
            for (uint256 i = 0; i < roundWinnerArray.length; i++) {
                address winner = roundWinnerArray[i];
                uint256 count = playersCount[i];
                //给赢家转账
                uint256 winAmount = poolAmount.div(allCount).mul(count);
                require(tablePool[tableAddress] > winAmount, "pool not enough for winAmount!");
                tablePool[tableAddress] -= winAmount;
                token.transfer(winner, winAmount);
            }
        }
        address[] memory allPlayers = lotteryTable.getAllPlayers();
        //_reset
        lotteryTable.reset();
        //return
        return (round, roundResult, roundWinnerArray, allPlayers);
    }

    //msg.sender is manager
    //启动一局
    //hash:合约hash
    function startRoundV2(string memory hash) external onlyManagerOwner payable returns (uint256, uint256, address[] memory, address[] memory) {
        address tableAddress = hashTable[hash];
        require(tableAddress != address(0), "please check the address!");

        LotteryTable lotteryTable = LotteryTable(tableAddress);
        ILotteryTable.TableInfo memory tableInfo = lotteryTable.getTableInfo();
        (uint256 round, uint256 roundResult, address[] memory roundWinnerArray, uint256 allCount, uint256[] memory playersCount) = lotteryTable.start();
        console.log("roundResult", roundResult);

        //根据结果转账
        if (roundWinnerArray.length == 0) {
            //没有赢家就全部转给banker
            token.transfer(tableInfo.bankerWallet, tablePool[tableAddress]);
            tablePool[tableAddress] = 0;
        } else {
            uint256 poolAmount = tablePool[tableAddress];
            for (uint256 i = 0; i < roundWinnerArray.length; i++) {
                address winner = roundWinnerArray[i];
                uint256 count = playersCount[i];
                //给赢家转账
                uint256 winAmount = poolAmount.div(allCount).mul(count);
                require(tablePool[tableAddress] > winAmount, "pool not enough for winAmount!");
                token.transfer(winner, winAmount);
                tablePool[tableAddress] -= winAmount;
            }
        }
        address[] memory allPlayers = lotteryTable.getAllPlayers();
        //_reset
        lotteryTable.reset();
        //return
        return (round, roundResult, roundWinnerArray, allPlayers);
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
