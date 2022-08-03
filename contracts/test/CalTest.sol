//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract CalTest {
    using SafeMath for uint256;

    function subTest(uint256 a, uint256 b) public pure returns (uint256 result) {
        result = a - b;
    }

    function safeSubTest (uint256 a, uint256 b) public pure returns (bool flag, uint256 result) {
        (flag, result) = a.trySub(b);
    }

    function divTest(uint256 a, uint256 b) public pure returns (uint256 result) {
        result = a.div(b);
    }

}
