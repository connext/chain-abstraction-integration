import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { config as envConfig } from "dotenv";
import { DEFAULT_ARGS } from "../index";

envConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  // Get the chain id
  const chainId = +(await hre.getChainId());
  console.log("chainId", chainId);

  // Get the deployer
  const [deployer] = await hre.ethers.getSigners();
  if (!deployer) {
    throw new Error(`Cannot find signer to deploy with`);
  }
  console.log(
    "\n============================= Deploying MeanFinanceAdapter ==============================="
  );
  console.log("deployer: ", deployer.address);

  // Deploy contract
  const adapter = await hre.deployments.deploy("MeanFinanceAdapter", {
    from: deployer.address,
    skipIfAlreadyDeployed: true,
    log: true,
    // deterministicDeployment: true,
  });
  console.log(`MeanFinanceAdapter deployed to ${adapter.address}`);
};
export default func;
func.tags = ["meanfinanceadapter", "test"];
