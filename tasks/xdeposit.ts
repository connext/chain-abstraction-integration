import { Contract } from "ethers";
import { task } from "hardhat/config";

import { DEFAULT_ARGS } from "../deploy";

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

export default task(
  "xdeposit",
  "Mean finance create position via xcall"
).setAction(async ({}: TaskArgs, { getChainId, deployments, ethers }) => {
  // Get the deployer
  const [deployer] = await ethers.getSigners();
  if (!deployer) {
    throw new Error(`Cannot find signer to deploy with`);
  }

  console.log("deployer: ", deployer.address);

  const deployment = await deployments.get("MeanFinanceSource");
  const instance = new Contract(deployment.address, deployment.abi, deployer);
  console.log("MeanFinanceSource Address: ", deployment.address);

  // prepare params
  const { WETH, USDC, CONNEXT, DOMAIN } = DEFAULT_ARGS[10];

  const { WETH: pWETH , USDC: pUSDC, CONNEXT: pCONNEXT, DOMAIN: pDOMAIN } = DEFAULT_ARGS[137];

  // Hardhat coding Target for testing

  const target = "0x3E64213564cc30107Beb81cd0DCEd3F18dF79B35";
  const destinationDomain = pDOMAIN;
  

  //     const approveTx = await inputAsset
  //     .connect(wallet)
  //     .approve(source.address, inputBalance);

  //   const approveReceipt = await approveTx.wait();
});
