import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, constants, Contract, utils, Wallet } from "ethers";
import { DEFAULT_ARGS } from "../../deploy";
import { fund, deploy, ERC20_ABI } from "../helpers";
import ISwapAdapter from "../../artifacts/contracts/xreceivers/Swap/SwapAdapter.sol/SwapAdapter.json";

describe("SwapAdapter", function () {
  // Set up constants (will mirror what deploy fixture uses)
  const { WETH, USDC } = DEFAULT_ARGS[31337];
  const UNISWAP_SWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
  const WHALE = "0x385BAe68690c1b86e2f1Ad75253d080C14fA6e16"; // this is the address that should have weth, adapter, and random addr
  const UNPERMISSIONED = "0x7088C5611dAE159A640d940cde0a3221a4af8896";
  const RANDOM_TOKEN = "0x4200000000000000000000000000000000000042"; // this is OP
  const ASSET_DECIMALS = 6; // USDC decimals on op

  // Set up variables
  let adapter: Contract;
  let wallet: Wallet;
  let whale: Wallet;
  let unpermissioned: Wallet;
  let tokenA: Contract;
  let weth: Contract;
  let randomToken: Contract;

  before(async () => {
    // get wallet
    [wallet] = (await ethers.getSigners()) as unknown as Wallet[];
    // get whale
    whale = (await ethers.getImpersonatedSigner(WHALE)) as unknown as Wallet;
    // get unpermissioned
    unpermissioned = (await ethers.getImpersonatedSigner(UNPERMISSIONED)) as unknown as Wallet;
    // deploy contract
    const { instance } = await deploy("SwapAdapter");
    adapter = instance;
    // setup tokens
    tokenA = new ethers.Contract(USDC, ERC20_ABI, ethers.provider);
    weth = new ethers.Contract(WETH, ERC20_ABI, ethers.provider);
    randomToken = new ethers.Contract(RANDOM_TOKEN, ERC20_ABI, ethers.provider);
  });

  describe("constructor", () => {
    it("should deploy correctly", async () => {
      // Ensure all properties set correctly
      // Ensure whale is okay
      expect(whale.address).to.be.eq(WHALE);
      expect(tokenA.address).to.be.eq(USDC);
    });
  });

  describe("_exactSwap", () => {
    before(async () => {
      //   // fund the adapter contract with eth, random token, and adapter asset
      await fund(constants.AddressZero, utils.parseEther("1"), wallet, adapter.address);
      await fund(USDC, utils.parseUnits("1", ASSET_DECIMALS), whale, adapter.address);
      await fund(randomToken.address, utils.parseUnits("1", await randomToken.decimals()), whale, adapter.address);
    });

    it("should work", async () => {
      // get initial connext balances
      // send sweep tx

      const functionName = "uniswapV3ExactInputSingle";
      const iface = new utils.Interface(ISwapAdapter.abi);
      const fragment = iface.getFunction(functionName);
      const selector = iface.getSighash(fragment);

      const adapterBalance = await randomToken.balanceOf(adapter.address);
      const decimals = await randomToken.decimals();
      const normalized =
        decimals > ASSET_DECIMALS
          ? adapterBalance.div(BigNumber.from(10).pow(decimals - ASSET_DECIMALS))
          : adapterBalance.mul(BigNumber.from(10).pow(ASSET_DECIMALS - decimals));
      // use 0.1% slippage (OP is > $2, adapter = usdc)
      const lowerBound = normalized.mul(10).div(10_000);

      const abi = utils.defaultAbiCoder;
      const swapData = abi.encode(
        ["address", "address", "uint24", "uint256", "uint256", "address"],
        [randomToken.address, tokenA.address, 3000, adapterBalance, lowerBound, adapter.address],
      );

      const tx = await adapter.connect(wallet)._exactSwap(UNISWAP_SWAP_ROUTER, selector, swapData);
      const receipt = await tx.wait();
    });
  });
});
