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

describe("MeanFinanceSource", function () {
  // Set up constants (will mirror what deploy fixture uses)
  const { WETH, USDC, CONNEXT, DOMAIN } = DEFAULT_ARGS[31337];
  const UNISWAP_SWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
  const WHALE = "0x385BAe68690c1b86e2f1Ad75253d080C14fA6e16"; // this is the address that should have weth, source, and random addr
  const NOT_ZERO_ADDRESS = "0x7088C5611dAE159A640d940cde0a3221a4af8896";
  const RANDOM_TOKEN = "0x4200000000000000000000000000000000000042"; // this is OP
  const ASSET_DECIMALS = 6; // USDC decimals on op

  // Set up variables
  let connext: Contract;
  let source: Contract;
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
    const { MeanFinanceSource } = await deployments.fixture([
      "meanfinancesource",
    ]);
    source = new Contract(
      MeanFinanceSource.address,
      MeanFinanceSource.abi,
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
      expect(await source.swapRouter()).to.be.eq(UNISWAP_SWAP_ROUTER);
      // Ensure whale is okay
      expect(whale.address).to.be.eq(WHALE);
      expect(tokenUSDC.address).to.be.eq(USDC);
    });
  });

  describe("xDeposit", () => {
    before(async () => {
      // fund wallet with eth, random token, and source asset
      await fund(
        USDC,
        utils.parseUnits("1", ASSET_DECIMALS),
        whale,
        wallet.address
      );

      await fund(
        randomToken.address,
        utils.parseUnits("1", await randomToken.decimals()),
        whale,
        wallet.address
      );
    });

    it("should work input non-connext ERC20", async () => {
      const target = NOT_ZERO_ADDRESS;
      const destinationDomain = "6648936";
      const inputAsset = randomToken;
      const connextAsset = tokenUSDC;

      const inputBalance = await inputAsset.balanceOf(wallet.address);
      const inputDecimals = await inputAsset.decimals();
      const outputDecimals = await connextAsset.decimals();
      const normalized =
        inputDecimals > outputDecimals
          ? inputBalance.div(
              BigNumber.from(10).pow(inputDecimals - outputDecimals)
            )
          : inputBalance.mul(
              BigNumber.from(10).pow(outputDecimals - inputDecimals)
            );
      // use 0.1% slippage (OP is > $2, adapter = usdc)
      const lowerBound = normalized.mul(10).div(10_000);
      const calldata = utils.defaultAbiCoder.encode(["string"], ["hello"]);

      const approveTx = await inputAsset
        .connect(wallet)
        .approve(source.address, inputBalance);

      const approveReceipt = await approveTx.wait();

      // send tx
      const tx = await source
        .connect(wallet)
        .xDeposit(
          target,
          destinationDomain,
          inputAsset.address,
          connextAsset.address,
          inputBalance,
          3000,
          3000,
          lowerBound,
          calldata,
          { value: 0 }
        );

      const receipt = await tx.wait();
      // Ensure tokens got sent to connext
      expect((await inputAsset.balanceOf(source.address)).toString()).to.be.eq(
        "0"
      );
    });

    it.skip("should work input AddressZero", async () => {
      const target = NOT_ZERO_ADDRESS;
      const destinationDomain = "6648936";
      const inputAsset = constants.AddressZero;
      const connextAsset = weth;

      const inputBalance = utils.parseEther("0.5");
      const calldata = utils.defaultAbiCoder.encode(["string"], ["hello"]);

      // send tx
      const tx = await source
        .connect(wallet)
        .xDeposit(
          target,
          destinationDomain,
          inputAsset,
          connextAsset.address,
          inputBalance,
          3000,
          0,
          0,
          calldata,
          { value: inputBalance }
        );

      const receipt = await tx.wait();
      // Ensure tokens got sent to connext

      expect((await wallet.getBalance(source.address)).toString()).to.be.eq(
        "0"
      );
    });
  });
});
