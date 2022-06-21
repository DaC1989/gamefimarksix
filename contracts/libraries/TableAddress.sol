//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../LotteryTable.sol";

library TableAddress {

    struct TableKey {
        address creator;
        uint256 amount;
    }

    function getTableKey(address creator, uint256 amount)
    internal pure returns (TableKey memory) {
        return TableKey({creator: creator, amount: amount});
    }

    function computeAddress(address factory, TableKey memory key)
    public pure returns (address table) {
        table = address(
            uint160(
                uint256(keccak256(abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.creator, key.amount)),
                            keccak256(type(LotteryTable).creationCode)
                        )
                    )
                )
            )
        );
    }
}
