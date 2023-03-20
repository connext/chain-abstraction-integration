import { Contract } from "ethers";
import { task } from "hardhat/config";

type callDataParams = {
  poolFee: number;
  amountOutMin: string;
  from: string;
  to: string;
  amountOfSwaps: number;
  swapInterval: string;
  owner: string;
  permissions: any;
};
type TaskArgs = {
  target: string;
  destination: string;
  inputAsset: string;
  connextAsset: string;
  amountIn: string;
  sourceAmountOutMin: string;
  sourcePoolFee?: number;
  connextSlippage?: number;
};

export default task("xdeposit", "Mean finance create position via xcall")
  .addParam("target", "Mean Finance Target address")
  .addParam("destination", "destination domain")
  .addParam("asset", "input asset of ")
  .setAction(async ({}: TaskArgs, { deployments, ethers }) => {
    // Get the deployer
    const [deployer] = await ethers.getSigners();
    if (!deployer) {
      throw new Error(`Cannot find signer to deploy with`);
    }

    console.log("deployer: ", deployer.address);

    const deployment = await deployments.get("MeanFinanceSource");
    const instance = new Contract(deployment.address, deployment.abi, deployer);
    console.log("MeanFinanceSource Address: ", deployment.address);

  });
