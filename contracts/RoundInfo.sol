//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract RoundInfo {
    address[] public players; //玩家列表
    address[] winners; //赢家
    mapping(address => uint256)  public playersCount;//玩家下注数
    mapping(address => uint256)  playersNumber;//玩家选择的number
    mapping(address => uint256)  playersBet;//玩家实际投入资金（扣除commission）
    mapping(uint256 => address[])  numberPlayers;//number有哪些玩家
    mapping(uint256 => uint256)  numberCount; //number对应的下注数

    function getPlayers() external view returns(address[] memory) {
        return players;
    }

    function pushPlayers(address player) external {
        players.push(player);
    }

    function getWinners() external view returns(address[] memory) {
        return players;
    }

    function pushWinners(address winner) external {
        winners.push(winner);
    }

    function getCount(address player) external view returns(uint256) {
        return playersCount[player];
    }

    function setCount(address player, uint256 count) external {
        playersCount[player] = count;
    }

    function getNumber(address player) external view returns(uint256) {
        return playersNumber[player];
    }

    function setNumber(address player, uint256 number) external {
        playersNumber[player] = number;
    }

    //playersBet TODO

    function getNumberPlayers(uint256 number) external view returns(address[] memory) {
        return numberPlayers[number];
    }

    function setNumberPlayers(uint256 number, address player) external {
        numberPlayers[number].push(player);
    }

    function addNumberCount(uint256 number, uint256 count) external {
        numberCount[number] += count;
    }

    function getNumberCount(uint256 number) external view returns(uint256) {
        return numberCount[number];
    }


}
