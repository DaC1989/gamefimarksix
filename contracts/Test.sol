//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Test{

    address owner;
    string symbol;

    constructor(string memory _symbol) {
        owner = msg.sender;
        symbol = _symbol;
    }

    function f() public pure returns (string memory){
        return "method f()";
    }
    function g() public pure returns (string memory){
        return "method g()";
    }
}
