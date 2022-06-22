//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryFactory.sol";
import "hardhat/console.sol";

contract LotteryManager {

    address public immutable factory;

    address owner;

    constructor(address _factory) {
        factory = _factory;
        owner = msg.sender;
    }

    function createTableIfNecessary(address creator, uint256 amount, uint256 minPPL,
                                    uint256 maxPPL, uint256 coolDownTime, uint256 gameTime,
                                    uint256 bankerCommission, uint256 referralCommission, address bankerWallet)
    external payable returns (bool result) {
        console.log("owner is:", owner);
        console.log("sender is:", msg.sender);
        require(msg.sender == owner, "Only contract owner is allowed to call this function");
        address table = ILotteryFactory(factory).getTable(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet);
        if (table == address(0)) {
            table = ILotteryFactory(factory).createTable(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet);
        }
        console.log("table is:", table);
        result = true;
    }

    function joinTable(string memory token, uint256 amount)
    external payable returns (address table) {

    }

}
