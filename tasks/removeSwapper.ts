import { Contract } from "ethers";
import { task } from "hardhat/config";

type TaskArgs = {
  target?: string;
  swapper?: string;
};

export default task("remove-swapper", "Remove swapper contract address to Midas Target")
  .addOptionalParam("target", "The address of the Midas Target")
  .addOptionalParam("swapper", "The address of the swapper")
  .setAction(async ({ target: _target, swapper: _swappper }: TaskArgs, { deployments, ethers }) => {
    // Get the deployer
    const [deployer] = await ethers.getSigners();
    if (!deployer) {
      throw new Error(`Cannot find signer to deploy with`);
    }

    console.log("deployer: ", deployer.address);

    const deployment = await deployments.get("MidasProtocolTarget");
    const target = _target ?? deployment.address;
    console.log("MidasProtocolTarget address: ", target);

    const swapper = _swappper ?? (await deployments.get("UniV3Swapper")).address;
    console.log("Swapper address: ", swapper);

    const instance = new Contract(target, deployment.abi, deployer);

    const tx = await instance.removeSwapper(swapper);
    const receipt = await tx.wait();

    console.log(receipt);
  });
