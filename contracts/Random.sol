//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Random {

    /**
    * @notice Generates a random number between 0 - 100
    * @param seed The seed to generate different number if block.timestamp is same
    * for two or more numbers.
    */
    function importSeedFromThird(uint256 seed) public view returns (uint8) {
        uint8 randomNumber = uint8(
            uint256(keccak256(abi.encodePacked(block.timestamp, seed))) % 100
        );
    }


}
