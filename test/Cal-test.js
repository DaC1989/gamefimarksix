const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const Web3 = require("web3");

describe("CalTest", function () {

    it("subTest", async function () {
        await hre.run('compile');
        const CalTest = await hre.ethers.getContractFactory("CalTest");
        const calTest = await CalTest.deploy();
        await calTest.deployed();
        console.log("CalTest deployed to:", calTest.address);
        const a = await calTest.subTest(3, 2);
        // const subTestTx = await a.wait(1)
        console.log(a);
    }).timeout(10000);

    it("safeSubTest", async function () {
        await hre.run('compile');
        const CalTest = await hre.ethers.getContractFactory("CalTest");
        const calTest = await CalTest.deploy();
        await calTest.deployed();
        console.log("CalTest deployed to:", calTest.address);
        const safeSubTestTx = await calTest.safeSubTest(1, 2);
        console.log(safeSubTestTx);
    }).timeout(10000);

    it("divTest", async function () {
        await hre.run('compile');
        const CalTest = await hre.ethers.getContractFactory("CalTest");
        const calTest = await CalTest.deploy();
        await calTest.deployed();
        console.log("CalTest deployed to:", calTest.address);
        const divTestTx = await calTest.divTest(14, 3);
        console.log("divTestTx", divTestTx);
    }).timeout(10000);

});