//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryFactory.sol";
import "./NoDelegateCall.sol";
import "./LotteryTableDeployer.sol";

import "hardhat/console.sol";

contract LotteryFactory is ILotteryFactory, LotteryTableDeployer, NoDelegateCall{

    address public override owner;

    mapping(address => mapping(uint256 => address)) private tableMap;

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);
    }

    function getTable(address creator, uint256 amount, uint256 minPPL,
        uint256 maxPPL, uint256 coolDownTime, uint256 gameTime,
        uint256 bankerCommission, uint256 referralCommission, address bankerWallet) external view override
    returns (address table) {
        uint256 hash = uint256(keccak256(abi.encodePacked(amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet)));
        table = tableMap[creator][hash];
        console.log("getTable", table);
    }

    function createTable(address creator, uint256 amount, uint256 minPPL,
        uint256 maxPPL, uint256 coolDownTime, uint256 gameTime,
        uint256 bankerCommission, uint256 referralCommission, address bankerWallet)
    external override noDelegateCall
    returns (address table) {
        require(creator != address(0));
        require(amount > 0);
        require(minPPL > 0);
        require(maxPPL > 0);
        require(coolDownTime > 0);
        require(gameTime > 0);
        require(bankerCommission > 0);
        require(referralCommission > 0);
        require(bankerWallet != address(0));

        uint256 hash = uint256(keccak256(abi.encodePacked(amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet)));
        console.log("hash", hash);
        require(tableMap[creator][hash] == address(0));
        table = deploy(address(this), creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet);
        tableMap[creator][hash] = table;

        emit tableCreated(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

}
