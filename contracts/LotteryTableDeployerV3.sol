//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryTableDeployerV3.sol";
import "./LotteryTableV3.sol";

contract LotteryTableDeployerV3 is ILotteryTableDeployerV3{

    Parameters public params;

    function getParameters() override external view returns (Parameters memory parameters) {
        parameters = params;
    }

    function deploy(address managerContract, address factory, address creator, uint256 amount, uint256 minPPL,
        uint256 maxPPL, uint256 coolDownTime, uint256 gameTime,
        uint256 bankerCommission, uint256 referralCommission, address bankerWallet, uint256 delayBlocks)
    internal returns (address table) {
        params = Parameters(
            {
                managerContract:managerContract,
                factory: factory,
                creator: creator,
                amount: amount,
                minPPL: minPPL,
                maxPPL:maxPPL,
                coolDownTime:coolDownTime,
                gameTime:gameTime,
                bankerCommission:bankerCommission,
                referralCommission:referralCommission,
                bankerWallet:bankerWallet,
                delayBlocks:delayBlocks
            }
        );
        table = address(new LotteryTableV3{salt: keccak256(abi.encode(factory, creator, amount, minPPL, maxPPL, coolDownTime, gameTime, bankerCommission, referralCommission, bankerWallet, delayBlocks))}());
        delete params;
    }

}
