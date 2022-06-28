//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryFactory.sol";
import "./libraries/TableAddress.sol";

import "hardhat/console.sol";
import "./interfaces/ILotteryTable.sol";

contract LotteryManager {

    address public immutable factory;

    address owner;

    mapping(address => address) private referralMap;

    mapping(uint256 => address) private hashTable;

    mapping(address => uint256) private tableHash;

    constructor(address _factory) {
        factory = _factory;
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
    external onlyManagerOwner payable returns (bool result) {
        require(msg.sender == owner, "Only contract owner is allowed to call this function");
        address table = ILotteryFactory(factory).getTable(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet);
        if (table == address(0)) {
            table = ILotteryFactory(factory).createTable(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet);
        }
        console.log("table is:", table);
        uint256 hash = uint256(keccak256(abi.encode(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet)));
        hashTable[hash] = table;
        tableHash[table] = hash;
        result = true;
    }

    //msg.sender is player
    // count: 下注数量, number:下注数字
    function joinTableV1(uint32 count, uint8 number, ILotteryTable.TableInfo memory tableInfo)
    external payable returns (bool result) {
        console.log("tableInfo is:", tableInfo.creator);
        address referraler = referralMap[msg.sender];
        uint256 hash = uint256(keccak256(abi.encode(tableInfo.creator, tableInfo.amount, tableInfo.minPPL, tableInfo.maxPPL, tableInfo.coolDownTime, tableInfo.gameTime, tableInfo.bankerCommission, tableInfo.referralCommission, tableInfo.bankerWallet)));
        address tableAddress = hashTable[hash];
        require(tableAddress != address(0), "please check the address!");

//        TableAddress.TableKey memory tableKey = TableAddress.TableKey({factory: factory, creator: tableInfo.creator, amount: tableInfo.amount, minPPL:tableInfo.minPPL, maxPPL: tableInfo.maxPPL, coolDownTime: tableInfo.coolDownTime, gameTime: tableInfo.gameTime, bankerCommission: tableInfo.bankerCommission, referralCommission: tableInfo.referralCommission, bankerWallet: tableInfo.bankerWallet});
//        address tableAddress = TableAddress.computeAddressV1(factory, tableKey);
        console.log("tableAddress is", tableAddress);
        console.log("tableHash[tableAddress]", tableHash[tableAddress]);
        require(tableHash[tableAddress] != 0);
        console.log("tableAddress", tableAddress);
        LotteryTable lotteryTable = LotteryTable(tableAddress);
        ILotteryTable.JoinInfo memory joinInfo = ILotteryTable.JoinInfo({count:count, number: number, referraler:referraler});
        lotteryTable.joinTable(joinInfo);
        result = true;
    }

    //msg.sender is manager
    function startRound(ILotteryTable.TableInfo memory tableInfo) external onlyManagerOwner payable returns (bool result) {
        uint256 hash = uint256(keccak256(abi.encode(tableInfo.creator, tableInfo.amount, tableInfo.minPPL, tableInfo.maxPPL, tableInfo.coolDownTime, tableInfo.gameTime, tableInfo.bankerCommission, tableInfo.referralCommission, tableInfo.bankerWallet)));
        address tableAddress = hashTable[hash];
        require(tableAddress != address(0), "please check the address!");

        LotteryTable lotteryTable = LotteryTable(tableAddress);
        lotteryTable.start();
        result = true;

    }

    //referral a:被邀请人；b：邀请人
    function referral(address a, address b) external onlyManagerOwner returns (bool result) {
        require(a != address(0));
        require(b != address(0));
        require(a != b);
        referralMap[a] = b;

        result = true;
    }

}
