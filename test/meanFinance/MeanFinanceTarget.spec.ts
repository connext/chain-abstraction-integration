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
import { SwapInterval } from "../../utils/interval-utils";
import ConnextInterface from "../../artifacts/@connext/interfaces/core/IConnext.sol/IConnext.json";

enum Permission {
  INCREASE,
  REDUCE,
  WITHDRAW,
  TERMINATE,
}

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

  const permissions = [
    { operator: NOT_ZERO_ADDRESS, permissions: [Permission.INCREASE] },
  ];
  const swaps = 10;
  const interval = SwapInterval.ONE_DAY.seconds;

  // Set up variables
  let connext: Contract;
  let target: Contract;
  let wallet: Wallet;
  let whale: Wallet;
  let tokenUSDC: Contract;
  let weth: Contract;
  let randomToken: Contract;

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
    tokenUSDC = new ethers.Contract(USDC, ERC20_ABI, ethers.provider);
    weth = new ethers.Contract(WETH, ERC20_ABI, ethers.provider);
    randomToken = new ethers.Contract(RANDOM_TOKEN, ERC20_ABI, ethers.provider);
  });

  describe("constructor", () => {
    it("should deploy correctly", async () => {
      // Ensure all properties set correctly
      expect(await target.hub()).to.be.eq(MEAN_FINANCE_IDCAHUB);
      // Ensure whale is okay
      expect(whale.address).to.be.eq(WHALE);
      expect(tokenUSDC.address).to.be.eq(USDC);
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

    it("should work when from is ERC20", async () => {      
      const fromAsset  = randomToken;
      const toAsset = tokenUSDC;
      // get reasonable amount out

      const adapterBalance = await fromAsset.balanceOf(target.address);
      const randomDecimals = await fromAsset.decimals();
      const normalized =
        randomDecimals > ASSET_DECIMALS
          ? adapterBalance.div(
              BigNumber.from(10).pow(randomDecimals - ASSET_DECIMALS)
            )
          : adapterBalance.mul(
              BigNumber.from(10).pow(ASSET_DECIMALS - randomDecimals)
            );
      // use 0.1% slippage (OP is > $2, adapter = usdc)
      const lowerBound = normalized.mul(10).div(10_000);
      const calldata = await target.connect(wallet).encode(
        3000, //0.3%
        lowerBound,
        fromAsset.address,
        toAsset.address,
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
          fromAsset.address,
          wallet.address,
          DOMAIN,
          calldata
        );

      const receipt = await tx.wait();
      // Ensure tokens got sent to connext
      expect((await fromAsset.balanceOf(target.address)).toString()).to.be.eq(
        "0"
      );
    });
  });
});
