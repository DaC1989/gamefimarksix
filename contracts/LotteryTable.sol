//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILotteryTableDeployer.sol";
import "./interfaces/ILotteryFactory.sol";
import "./interfaces/ILotteryTable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./RoundInfo.sol";
import "hardhat/console.sol";

contract LotteryTable is ILotteryTable{
    using SafeMath for uint256;
    address public immutable factory;
    IERC20 usdt;
    TableInfo public tableInfo;
    RoundInfo roundInfo = new RoundInfo();

    modifier onlyFactoryOwner() {
        require(msg.sender == ILotteryFactory(factory).owner());
        _;
    }

    constructor() {
        //hardhat usdt:0x73F7fF55196c525A8273c766BeeA3F61D1b829b2
        //BSC testnet USDT:0x337610d27c682E347C9cD60BD4b3b107C9d34dDd
        //BSC mainnet USDT:0x55d398326f99059ff775485246999027b3197955
        usdt = IERC20(address(0x337610d27c682E347C9cD60BD4b3b107C9d34dDd));

        ILotteryTableDeployer.Parameters memory params = ILotteryTableDeployer(msg.sender).getParameters();
        factory = params.factory;
        tableInfo =  TableInfo({creator: params.creator,
                                amount:params.amount,
                                minPPL:params.minPPL,
                                maxPPL:params.maxPPL,
                                coolDownTime:params.amount,
                                gameTime:params.gameTime,
                                bankerCommission:params.bankerCommission,
                                referralCommission:params.referralCommission,
                                bankerWallet:params.bankerWallet});
    }

    //msg.sender is player
    function joinTable(JoinInfo memory joinInfo) external override payable {
        console.log("roundInfo.getCount(msg.sender)", roundInfo.getCount(msg.sender));
        console.log("address(this)", address(this));
        require(roundInfo.getCount(msg.sender) == 0, "duplicated bet");
        //approve
        //usdt.approve(address(this), msg.value);
        //transfer
        uint256 betAmount = joinInfo.count.mul(tableInfo.amount);
        console.log("betAmount", betAmount);
//        usdt.transferFrom(msg.sender, address(this), betAmount);
        console.log("totalSupply", usdt.totalSupply());
        console.log("msg.sender", msg.sender);
        console.log("usdt.balanceOf(msg.sender):", usdt.balanceOf(msg.sender));
        payable(address(this)).transfer(betAmount);
        console.log("usdt.balanceOf(msg.sender):", usdt.balanceOf(msg.sender));
        //bankerCommission
        uint256 bankerCommissionAmount = msg.value * (tableInfo.bankerCommission.div(10000));
        usdt.transferFrom(msg.sender, tableInfo.bankerWallet, bankerCommissionAmount);
        //referralCommission
        if (joinInfo.referraler != address(0)) {
            uint256 referralAmount = msg.value * (tableInfo.referralCommission.div(10000));
            usdt.transferFrom(msg.sender, joinInfo.referraler, referralAmount);
        }
        roundInfo.pushPlayers(msg.sender);
        roundInfo.setCount(msg.sender, joinInfo.count);
        roundInfo.setNumber(msg.sender, joinInfo.number);
        roundInfo.addNumberCount(joinInfo.number, joinInfo.count);
    }
    //msg.sender is manager
    function start() external payable{
        uint256 randomNumber = getRandom(roundInfo.getPlayers().length);
        uint256 result = randomNumber.mod(10);
        console.log("result", result);
        address[] memory winnerArray = roundInfo.getNumberPlayers(result);

        uint256 allBalance = usdt.balanceOf(msg.sender);
        if (winnerArray.length == 0) {
            //没有赢家就全部转给banker
            usdt.transferFrom(msg.sender, tableInfo.bankerWallet, allBalance);
        } else {
            uint256 allCount = roundInfo.getNumberCount(result);
            for (uint256 i = 0; i < winnerArray.length; i++) {
                address winner = winnerArray[i];
                uint256 count = roundInfo.getCount(winner);
                //给赢家转账
                usdt.transferFrom(msg.sender, winner, allBalance.mul(count.div(allCount)));
            }
        }
        reset();
    }

    //重置游戏数据
    function reset() private {
        delete roundInfo;
        roundInfo = new RoundInfo();
    }

    function getRandom(uint256 playersLength) private view returns(uint256 randomNumber) {
        randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, playersLength)));
    }
}
