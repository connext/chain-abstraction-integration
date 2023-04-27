import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { config as envConfig } from "dotenv";
import { DEFAULT_ARGS, MIDAS_CONFIG } from "../index";

envConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  // Get the chain id
  const chainId = +(await hre.getChainId());
  console.log("chainId", chainId);

  if (!MIDAS_CONFIG[chainId]) {
    throw new Error(`No defaults provided for ${chainId}`);
  }

  // Get the constructor args
  const args = [
    process.env.CONNEXT ?? DEFAULT_ARGS[chainId].CONNEXT,
    process.env.COMPTROLLER ?? MIDAS_CONFIG[chainId].COMPTROLLER,
  ];

  // Get the deployer
  const [deployer] = await hre.ethers.getSigners();
  if (!deployer) {
    throw new Error(`Cannot find signer to deploy with`);
  }
  console.log("\n============================= Deploying MidasProtocolTarget ===============================");
  console.log("deployer: ", deployer.address);
  console.log("constructorArgs:", args);

  // Deploy contract
  const adapter = await hre.deployments.deploy("MidasProtocolTarget", {
    from: deployer.address,
    args: args,
    skipIfAlreadyDeployed: true,
    log: true,
    // deterministicDeployment: true,
  });
  console.log(`MidasProtocolTarget deployed to ${adapter.address}`);
};
export default func;
func.tags = ["midasprotocoltarget", "test", "prod"];
