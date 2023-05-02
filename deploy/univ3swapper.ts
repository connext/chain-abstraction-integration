import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { config as envConfig } from "dotenv";
import { DEFAULT_ARGS } from "./index";

envConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  // Get the chain id
  const chainId = +(await hre.getChainId());
  console.log("chainId", chainId);

  if (!DEFAULT_ARGS[chainId]) {
    throw new Error(`No defaults provided for ${chainId}`);
  }

  // Get the constructor args
  const args = [process.env.UNIV3_ROUTER ?? DEFAULT_ARGS[chainId].UNIV3_ROUTER];

  // Get the deployer
  const [deployer] = await hre.ethers.getSigners();
  if (!deployer) {
    throw new Error(`Cannot find signer to deploy with`);
  }
  console.log("\n============================= Deploying UniV3Swapper ===============================");
  console.log("deployer: ", deployer.address);
  console.log("constructorArgs:", args);

  // Deploy contract
  if (chainId === 56) {
    // deploy pancake v3 swapper
    const adapter = await hre.deployments.deploy("PancakeV3Swapper", {
      from: deployer.address,
      args: args,
      skipIfAlreadyDeployed: true,
      log: true,
      // deterministicDeployment: true,
    });
    console.log(`PancakeV3Swapper deployed to ${adapter.address}`);
  } else {
    const adapter = await hre.deployments.deploy("UniV3Swapper", {
      from: deployer.address,
      args: args,
      skipIfAlreadyDeployed: true,
      log: true,
      // deterministicDeployment: true,
    });
    console.log(`UniV3Swapper deployed to ${adapter.address}`);
  }
};
export default func;
func.tags = ["univ3swapper", "test", "prod"];
