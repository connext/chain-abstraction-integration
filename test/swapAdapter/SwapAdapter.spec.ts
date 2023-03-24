import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, constants, Contract, utils, Wallet } from "ethers";
import { DEFAULT_ARGS } from "../../deploy";
import { fund, deploy, ERC20_ABI } from "../helpers";
import TestERC20 from "../../artifacts/contracts/TestERC20/TestERC20.sol/TestERC20.json";

describe.skip("SwapAdapter", function () {
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
    unpermissioned = (await ethers.getImpersonatedSigner(
      UNPERMISSIONED
    )) as unknown as Wallet;
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

  describe("swap", () => {
    before(async () => {
      //   // fund the adapter contract with eth, random token, and adapter asset
      //   await fund(
      //     constants.AddressZero,
      //     utils.parseEther("1"),
      //     wallet,
      //     adapter.address
      //   );
      //   await fund(
      //     USDC,
      //     utils.parseUnits("1", ASSET_DECIMALS),
      //     whale,
      //     adapter.address
      //   );
      //   await fund(
      //     randomToken.address,
      //     utils.parseUnits("1", await randomToken.decimals()),
      //     whale,
      //     adapter.address
      //   );
    });

    it("should work", async () => {
      // get initial connext balances
      // send sweep tx

      const iface = new utils.Interface(TestERC20.abi);
      const fragment = iface.getFunction("transfer");
      const selector = iface.getSighash(fragment);
      console.log(selector);

      const tx = await adapter
        .connect(wallet)
        .addSelector(wallet.address, selector);
      const receipt = await tx.wait();

      const response = await adapter
        .connect(wallet)
        .swapEncoderSelector(wallet.address);

      console.log(response);

      const res = await adapter.connect(wallet).transferSelector();

      console.log(res);
      // Ensure tokens got sent to connext
    });
  });
});
