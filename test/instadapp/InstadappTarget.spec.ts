import { ethers } from "hardhat";

const deployInstaTarget = async (connextAddress: string, authority: string) => {
    const instaTagetFactory = await ethers.getContractFactory("InstadappTarget");
    const contractInstance = await instaTagetFactory.deploy(connextAddress, authority);
    await contractInstance.deployed();
    return contractInstance
  }