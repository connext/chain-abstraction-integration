import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { config as envConfig } from "dotenv";
import { DEFAULT_ARGS, GRUMPYCAT_CONFIG, MIDAS_CONFIG } from "../index";

envConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  // Get the chain id
  const chainId = +(await hre.getChainId());
  console.log("chainId", chainId);

  if (!GRUMPYCAT_CONFIG[chainId]) {
    throw new Error(`No defaults provided for ${chainId}`);
  }

  // Get the constructor args
  const args = [
    DEFAULT_ARGS[chainId].CONNEXT,
    GRUMPYCAT_CONFIG[chainId].LOCKBOX,
    GRUMPYCAT_CONFIG[chainId].ERC20,
    GRUMPYCAT_CONFIG[chainId].XERC20,
  ];

  // Get the deployer
  const [deployer] = await hre.ethers.getSigners();
  if (!deployer) {
    throw new Error(`Cannot find signer to deploy with`);
  }
  console.log("\n============================= Deploying GrumpyCatLockboxAdapter ===============================");
  console.log("deployer: ", deployer.address);
  console.log("constructorArgs:", args);

  // Deploy contract
  const adapter = await hre.deployments.deploy("GrumpyCatLockboxAdapter", {
    from: deployer.address,
    args: args,
    log: true,
    // deterministicDeployment: true,
  });
  console.log(`GrumpyCatLockboxAdapter deployed to ${adapter.address}`);
};
export default func;
func.tags = ["grumpycat", "test", "prod"];
