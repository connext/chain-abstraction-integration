import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { config as envConfig } from "dotenv";
import { DEFAULT_ARGS } from "../index";

envConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  // Get the chain id
  const chainId = +(await hre.getChainId());
  console.log("chainId", chainId);

  if (!DEFAULT_ARGS[chainId]) {
    throw new Error(`No defaults provided for ${chainId}`);
  }

  // Get the constructor args
  const args = [process.env.CONNEXT ?? DEFAULT_ARGS[chainId].CONNEXT, process.env.WETH ?? DEFAULT_ARGS[chainId].WETH];

  // Get the deployer
  const [deployer] = await hre.ethers.getSigners();
  if (!deployer) {
    throw new Error(`Cannot find signer to deploy with`);
  }
  console.log("\n============================= Deploying MeanFinanceSource ===============================");
  console.log("deployer: ", deployer.address);
  console.log("constructorArgs:", args);

  // Deploy contract
  const adapter = await hre.deployments.deploy("MeanFinanceSource", {
    from: deployer.address,
    args: args,
    skipIfAlreadyDeployed: true,
    log: true,
    // deterministicDeployment: true,
  });
  console.log(`MeanFinanceSource deployed to ${adapter.address}`);
};
export default func;
func.tags = ["meanfinancesource", "test", "prod"];
