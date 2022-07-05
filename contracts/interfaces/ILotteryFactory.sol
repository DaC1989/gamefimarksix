//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface ILotteryFactory {

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    event tableCreated(address creator, uint256 amount, uint256 minPPL,
        uint256 maxPPL, uint256 coolDownTime, uint256 gameTime,
        uint256 bankerCommission, uint256 referralCommission, address bankerWallet);

    function owner() external view returns (address);

    function getTable(address creator, uint256 amount, uint256 minPPL,
        uint256 maxPPL, uint256 coolDownTime, uint256 gameTime,
        uint256 bankerCommission, uint256 referralCommission, address bankerWallet) external view returns (address table);

    function createTable(address managerContract, address creator, uint256 amount, uint256 minPPL,
        uint256 maxPPL, uint256 coolDownTime, uint256 gameTime,
        uint256 bankerCommission, uint256 referralCommission, address bankerWallet) external returns (address table);

    function setOwner(address _owner) external;

}
