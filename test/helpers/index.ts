import { ethers } from "hardhat";
import {
  BigNumberish,
  constants,
  Contract,
  providers,
  Wallet,
} from "ethers";
import { ERC20_ABI } from "@0xgafu/common-abi";

export const deploy = async (contractName: string) => {
  // Contracts are deployed using the first signer/account by default
  const [owner, otherAccount] = await ethers.getSigners();
  const contract = await ethers.getContractFactory(contractName);
  const instance = await contract.deploy();
  await instance.deployed();

  return { instance, owner, otherAccount };
};

export const fund = async (
  asset: string,
  wei: BigNumberish,
  from: Wallet,
  to: string
): Promise<providers.TransactionReceipt> => {
  if (asset === constants.AddressZero) {
    const tx = await from.sendTransaction({ to, value: wei });
    // send eth
    return await tx.wait();
  }

  // send tokens
  const token = new Contract(asset, ERC20_ABI, from);
  const tx = await token.transfer(to, wei);
  return await tx.wait();
};

export { ERC20_ABI };


