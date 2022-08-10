//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILotteryTableDeployerV3 {

    struct Parameters {
        address managerContract;
        address factory;
        address creator;
        uint256 amount;
        uint256 minPPL;
        uint256 maxPPL;
        uint256 coolDownTime;
        uint256 gameTime;
        uint256 bankerCommission;
        uint256 referralCommission;
        address bankerWallet;
        uint256 delayBlocks;
    }

    function getParameters() external view returns (Parameters memory parameters);
}
