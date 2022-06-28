//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../LotteryTable.sol";

library TableAddress {

    struct TableKey {
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
    }

    function getTableKey(address factory, address creator, uint256 amount, uint256 minPPL, uint256 maxPPL, uint256 coolDownTime, uint256 gameTime, uint256 bankerCommission, uint256 referralCommission, address bankerWallet)
    internal pure returns (TableKey memory) {
        return TableKey({factory: factory, creator: creator, amount: amount, minPPL:minPPL, maxPPL: maxPPL, coolDownTime: coolDownTime, gameTime: gameTime, bankerCommission: bankerCommission, referralCommission: referralCommission, bankerWallet: bankerWallet});
    }

    function computeAddressV1(address factory, TableKey memory key)
    public pure returns (address table) {
        table = address(
            uint160(
                uint256(keccak256(abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.creator, key.amount, key.minPPL, key.maxPPL, key.coolDownTime, key.gameTime, key.bankerCommission, key.referralCommission, key.bankerWallet)),
                            keccak256(type(LotteryTable).creationCode)
                        )
                    )
                )
            )
        );
    }
}
