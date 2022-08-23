//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./NoDelegateCall.sol";
import "./LotteryTableDeployerV3.sol";

import "hardhat/console.sol";
import "./interfaces/ILotteryFactoryV3.sol";

contract LotteryFactoryV3 is ILotteryFactoryV3, LotteryTableDeployerV3, NoDelegateCall{

    address public override owner;

    mapping(address => mapping(uint256 => address)) private tableMap;

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);
    }

    function getTable(address managerContract, address creator, uint256 amount, uint256 minPPL,
        uint256 maxPPL, uint256 coolDownTime, uint256 gameTime,
        uint256 bankerCommission, uint256 referralCommission, address bankerWallet, uint256 delayBlock, uint256 jackpotCommission) external view override
    returns (address table) {
        uint256 hash = uint256(keccak256(abi.encodePacked(managerContract, address(this), amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet, delayBlock, jackpotCommission)));
        table = tableMap[creator][hash];
    }

    //TODO 测试是否安全
    function createTable(address managerContract, address creator, uint256 amount, uint256 minPPL,
        uint256 maxPPL, uint256 coolDownTime, uint256 gameTime,
        uint256 bankerCommission, uint256 referralCommission, address bankerWallet, uint256 delayBlock, uint256 jackpotCommission)
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
        //require(delayBlock > 0);

        uint256 hash = uint256(keccak256(abi.encodePacked(address(this), amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet, delayBlock, jackpotCommission)));
        require(tableMap[creator][hash] == address(0), "already have the table");
        table = deploy(managerContract, address(this), creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet, delayBlock, jackpotCommission);
        tableMap[creator][hash] = table;

        emit tableCreated(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet, delayBlock, jackpotCommission);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

}
