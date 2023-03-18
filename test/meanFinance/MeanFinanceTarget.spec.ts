import { expect } from "chai";
import { deployments, ethers } from "hardhat";
import {
  BigNumber,
  BigNumberish,
  constants,
  Contract,
  providers,
  utils,
  Wallet,
} from "ethers";
import { DEFAULT_ARGS } from "../../deploy";
import { ERC20_ABI } from "@0xgafu/common-abi";
import { getRandomBytes32 } from "@connext/utils";
import { SwapInterval } from "./interval-utils";
import IDCAHubInterface from "../../artifacts/@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol/IDCAHub.json";
import ConnextInterface from "../../artifacts/@connext/interfaces/core/IConnext.sol/IConnext.json";

const fund = async (
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

describe("MeanFinanceTarget", function () {
  // Set up constants (will mirror what deploy fixture uses)
  const { WETH, USDC, CONNEXT, DOMAIN } = DEFAULT_ARGS[31337];
  const MEAN_FINANCE_IDCAHUB = "0xA5AdC5484f9997fBF7D405b9AA62A7d88883C345";
  const WHALE = "0x385BAe68690c1b86e2f1Ad75253d080C14fA6e16"; // this is the address that should have weth, target, and random addr
  const NOT_ZERO_ADDRESS = "0x7088C5611dAE159A640d940cde0a3221a4af8896";
  const RANDOM_TOKEN = "0x4200000000000000000000000000000000000042"; // this is OP
  const ASSET_DECIMALS = 6; // USDC decimals on op

  // Set up variables
  let connext: Contract;
  let target: Contract;
  let wallet: Wallet;
  let whale: Wallet;
  let tokenA: Contract;
  let weth: Contract;
  let randomToken: Contract;

  enum Permission {
    INCREASE,
    REDUCE,
    WITHDRAW,
    TERMINATE,
  }

  before(async () => {
    // get wallet
    [wallet] = (await ethers.getSigners()) as unknown as Wallet[];
    // get whale
    whale = (await ethers.getImpersonatedSigner(WHALE)) as unknown as Wallet;
    // deploy contract
    const { MeanFinanceTarget } = await deployments.fixture([
      "meanfinancetarget",
    ]);
    target = new Contract(
      MeanFinanceTarget.address,
      MeanFinanceTarget.abi,
      ethers.provider
    );

    connext = new Contract(CONNEXT, ConnextInterface.abi, ethers.provider);
    // setup tokens
    tokenA = new ethers.Contract(USDC, ERC20_ABI, ethers.provider);
    weth = new ethers.Contract(WETH, ERC20_ABI, ethers.provider);
    randomToken = new ethers.Contract(RANDOM_TOKEN, ERC20_ABI, ethers.provider);
  });

  describe("constructor", () => {
    it("should deploy correctly", async () => {
      // Ensure all properties set correctly
      expect(await target.hub()).to.be.eq(MEAN_FINANCE_IDCAHUB);
      // Ensure whale is okay
      expect(whale.address).to.be.eq(WHALE);
      expect(tokenA.address).to.be.eq(USDC);
    });
  });

  describe("xReceive", () => {
    before(async () => {
      // fund the target contract with eth, random token, and target asset
      await fund(
        constants.AddressZero,
        utils.parseEther("1"),
        wallet,
        target.address
      );

      await fund(
        USDC,
        utils.parseUnits("1", ASSET_DECIMALS),
        whale,
        target.address
      );

      await fund(
        randomToken.address,
        utils.parseUnits("1", await randomToken.decimals()),
        whale,
        target.address
      );
    });

    it("should work", async () => {
      // get reasonable amount out
      const adapterBalance = await randomToken.balanceOf(target.address);

      const permissions = [
        { operator: NOT_ZERO_ADDRESS, permissions: [Permission.INCREASE] },
      ];

      const rate = 10;
      const swaps = 10;
      const interval = SwapInterval.ONE_DAY.seconds;

      // const iface = new ethers.utils.Interface(IDCAHubInterface.abi);
      // const calldata = iface.encodeFunctionData(
      //   "deposit(address,address,uint256,uint32,uint32,address,(address,uint8[])[])",
      //   [
      //     randomToken.address,
      //     tokenA.address,
      //     BigNumber.from(adapterBalance),
      //     swaps,
      //     interval,
      //     wallet.address,
      //     permissions,
      //   ]
      // );

      const calldata = await target
        .connect(wallet)
        .encode(
          randomToken.address,
          tokenA.address,
          BigNumber.from(adapterBalance),
          swaps,
          interval,
          wallet.address,
          permissions
        );

      const transferId = getRandomBytes32();

      // send tx
      const tx = await target
        .connect(wallet)
        .xReceive(
          transferId,
          BigNumber.from(adapterBalance),
          randomToken.address,
          wallet.address,
          DOMAIN,
          calldata
        );

      const receipt = await tx.wait();
      // Ensure tokens got sent to connext
      expect((await randomToken.balanceOf(target.address)).toString()).to.be.eq(
        "0"
      );
    });
  });
});
