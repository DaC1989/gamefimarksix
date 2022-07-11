//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryTableDeployer.sol";
import "./LotteryTable.sol";

contract LotteryTableDeployer is ILotteryTableDeployer{

    Parameters public params;

    function getParameters() override external view returns (Parameters memory parameters) {
        parameters = params;
    }

    function deploy(address managerContract, address factory, address creator, uint256 amount, uint256 minPPL,
        uint256 maxPPL, uint256 coolDownTime, uint256 gameTime,
        uint256 bankerCommission, uint256 referralCommission, address bankerWallet)
    internal returns (address table) {
        params = Parameters({managerContract:managerContract, factory: factory, creator: creator, amount: amount, minPPL: minPPL, maxPPL:maxPPL, coolDownTime:coolDownTime, gameTime:gameTime, bankerCommission:bankerCommission, referralCommission:referralCommission, bankerWallet:bankerWallet });
        table = address(new LotteryTable{salt: keccak256(abi.encode(creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet))}());
        delete params;
    }

}
