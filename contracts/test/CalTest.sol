//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

contract CalTest {
    using SafeMath for uint256;
    using Strings for uint256;

    function subTest(uint256 a, uint256 b) public pure returns (uint256 result) {
        result = a - b;
    }

    function safeSubTest (uint256 a, uint256 b) public pure returns (bool flag, uint256 result) {
        (flag, result) = a.trySub(b);
    }

    function divTest(uint256 a, uint256 b) public pure returns (uint256 result) {
        result = a.div(b);
    }

//    function getResultBlockHash(uint256 coolDownTimeBlock) public view returns(uint256 randomNumber) {
//        bytes32 result = blockhash(coolDownTimeBlock.add(2));
//        randomNumber = bytesToUint(result);
//    }

    function bytesToUint(bytes32 b) public view returns (uint256) {
        uint256 number;
        for(uint i= 0; i<b.length; i++){
            number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

    function test(bytes32 b) public view returns (uint256 result, bytes1 last) {
//        result = b.length;
//        console.log("result", result);
        b = 0xe8b3a52a8dec17becfd10223bf290296717d49a4c37a32697950b3f55fde43c7;
        last = b[b.length - 1];
        uint256 toUint = bytesToUint(b);
        console.log("toUint", toUint);
        uint256 other = uint256(b);
        console.log("other", other);
    }

    function test02() public view returns (bytes1 result){
        bytes32 b9 = 0xe8b3a52a8dec17becfd10223bf290296717d49a4c37a32697950b3f55fde43c7;
        console.log("b9", b9.length);
        result = b9[b9.length -1];

        uint8 resultInt = uint8(result);
        console.log("resultInt8", resultInt);
        console.log("resultInt8 % 16", resultInt % 16);
        console.log("resultInt>>4", resultInt>>4);
        console.log("resultInt<<4", uint8(resultInt<<4));
        console.log("resultIntStr", uint256(resultInt).toHexString());

        uint256 toInt = uint256(b9);

        string memory str = toInt.toString();
        console.log("str", str);
        string memory str2 = toInt.toHexString();
        console.log("str2", str2);
    }

    function getFirstDecimalFromHash(bytes32 hash) public returns (uint256 result) {
        for(uint256 i = 1; i < hash.length; i++) {
            uint8 toInt = uint8(hash[hash.length - i]);
            uint8 firstIndex = toInt % 16;
            uint8 secondIndex = toInt >> 4;
            if (firstIndex < 10) {
                result = firstIndex;
                break;
            } else if (secondIndex < 10) {
                result = secondIndex;
                break;
            }
        }
    }

}
