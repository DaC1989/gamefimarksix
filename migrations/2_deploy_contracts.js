// var Test = artifacts.require("./Test.sol");

var LotteryFactory = artifacts.require("./LotteryFactory.sol");
var LotteryManager = artifacts.require("./LotteryManager.sol");
var TestERC20 = artifacts.require("./TestERC20.sol");

module.exports = async function (deployer) {
    // deployer.deploy(Test, 'a');
    // await deployer.deploy(LotteryFactory);//TGJmdVugXQLUY8CchvWjDVjeNYrn3iDGLE
    // await deployer.deploy(TestERC20, 'test-usdt', 'test-usdt');//TSDALNALXYbac9rDPqR93RDwtuofax9UkF
    await deployer.deploy(LotteryManager, 'TGJmdVugXQLUY8CchvWjDVjeNYrn3iDGLE', 'TSDALNALXYbac9rDPqR93RDwtuofax9UkF');//TMMN1zJk2WGZVps7FEMSEsU6A7dQy4XL6y

};