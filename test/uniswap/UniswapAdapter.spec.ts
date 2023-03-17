import { expect } from "chai";
import { ethers } from "hardhat";
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

// These are the topics[0] for given events
// src: https://dashboard.tenderly.co/tx/optimistic/0xb0c1a0a5accb79ee72ba62226898bfc9957ec0a22695cd45b080a9462b7062f0/logs
const SWAP_SIG =
  "0xc42079f94a6350d7e6235f29174924f928cc2ac818eb64fed8004e115fbcca67";
const XCALL_SIG =
  "0xed8e6ba697dd65259e5ce532ac08ff06d1a3607bcec58f8f0937fe36a5666c54";
const SWEPT_SIG =
  "0xed8e6ba697dd65259e5ce532ac08ff06d1a3607bcec58f8f0937fe36a5666c54";
// src: https://optimistic.etherscan.io/tx/0xa50d4a2774326ccff37cf89d90dfbef006a40ceea63da2b6aa1f25f2cf65a0c0#eventlog
const DEPOSIT_SIG =
  "0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c";

describe("UniswapAdapter", function () {
  // Set up constants (will mirror what deploy fixture uses)
  //   const [CONNEXT, WETH, adapter_ASSET, adapter_DOMAIN] = DEFAULT_ARGS[31337];
  const [CONNEXT, WETH, ADAPTER_ADDRESS, DONATION_ASSET, DONATION_DOMAIN] =
    DEFAULT_ARGS[31337];
  const UNISWAP_SWAP_ROUTER = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
  const WHALE = "0x385BAe68690c1b86e2f1Ad75253d080C14fA6e16"; // this is the address that should have weth, adapter, and random addr
  const UNPERMISSIONED = "0x7088C5611dAE159A640d940cde0a3221a4af8896";
  const RANDOM_TOKEN = "0x4200000000000000000000000000000000000042"; // this is OP
  const adapter_ASSET_DECIMALS = 6; // USDC decimals on op

  // Set up variables
  let adapter: Contract;
  let wallet: Wallet;
  let whale: Wallet;
  let unpermissioned: Wallet;
  let tokenA: Contract;
  let tokenB: Contract;
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

    const UniswapAdapter = await ethers.getContractFactory("UniswapAdapter");
    adapter = await UniswapAdapter.deploy();

    const Token = await ethers.getContractFactory("TestERC20");
    tokenA = await Token.deploy("TestA", "TestA");
    tokenB = await Token.deploy("TestB", "TestB");

    await tokenA.transfer(adapter.address, 50);
    // setup tokens
    // tokenA = new ethers.Contract(ADAPTER_ADDRESS, ERC20_ABI, ethers.provider);
    // weth = new ethers.Contract(WETH, ERC20_ABI, ethers.provider);
    // randomToken = new ethers.Contract(RANDOM_TOKEN, ERC20_ABI, ethers.provider);
  });

  describe("constructor", () => {
    it("should deploy correctly", async () => {
      // Ensure all properties set correctly
      expect(await adapter.swapRouter()).to.be.eq(UNISWAP_SWAP_ROUTER);
      // Ensure whale is okay
      expect(whale.address).to.be.eq(WHALE);
      //   expect(tokenA.address).to.be.eq(ADAPTER_ADDRESS);
    });
  });

  describe("swap", () => {
    before(async () => {
      // fund the adapter contract with eth, random token, and adapter asset
      //   await fund(constants.AddressZero, utils.parseEther("1"), wallet, adapter.address);
      //   await fund(adapter_ASSET, utils.parseUnits("1", adapter_ASSET_DECIMALS), whale, adapter.address);
      //   await fund(tokenA.address, utils.parseUnits("1", await tokenA.decimals()), whale, adapter.address);
    });

    it("should work for adapter asset", async () => {
      // get initial connext balances
      console.log(await tokenA.decimals());
      // send sweep tx
      const amount = await tokenA.balanceOf(adapter.address);
      await expect(
        adapter
          .connect(wallet)
          .swap(tokenA.address, tokenB.address, amount, amount, 100)
      ).to.emit(adapter, "log");
      // await adapter.connect(wallet).swap(tokenA.address, tokenB.address, amount, amount, 100)

      // Ensure tokens got sent to connext
      expect((await tokenA.balanceOf(adapter.address)).toString()).to.be.eq(
        "0"
      );
    });

    it.skip("should work for random token", async () => {
      // get initial connext balances
      const initConnext = await tokenA.balanceOf(CONNEXT);

      // get reasonable amount out
      const sweeping = await randomToken.balanceOf(adapter.address);
      const randomDecimals = await randomToken.decimals();
      const normalized =
        randomDecimals > adapter_ASSET_DECIMALS
          ? sweeping.div(
              BigNumber.from(10).pow(randomDecimals - adapter_ASSET_DECIMALS)
            )
          : sweeping.mul(
              BigNumber.from(10).pow(adapter_ASSET_DECIMALS - randomDecimals)
            );
      // use 0.1% slippage (OP is > $2, adapter = usdc)
      const lowerBound = normalized.mul(10).div(10_000);

      // send sweep tx
      const tx = await adapter
        .connect(wallet)
        .swap(randomToken.address, 3000, sweeping, lowerBound, 1000);
      const receipt = await tx.wait();

      const emittedTopics = receipt.events.map((e) => e.topics[0]);
      expect(emittedTopics.includes(SWEPT_SIG)).to.be.true;
      expect(emittedTopics.includes(XCALL_SIG)).to.be.true;
      expect(emittedTopics.includes(SWAP_SIG)).to.be.true;

      // Ensure tokens got sent to connext
      expect(
        (await randomToken.balanceOf(adapter.address)).toString()
      ).to.be.eq("0");
      // Only asserting balance increased
      expect((await tokenA.balanceOf(CONNEXT)).gt(initConnext)).to.be.true;
    });

    it.skip("should work for native asset", async () => {
      // get initial connext balances
      const initConnext = await tokenA.balanceOf(CONNEXT);

      // get reasonable amount out
      const sweeping = await ethers.provider.getBalance(adapter.address);
      const normalized = sweeping.div(
        BigNumber.from(10).pow(18 - adapter_ASSET_DECIMALS)
      );
      // use 10% diff to account for eth price / slippage (OP is > $2, adapter = usdc)
      const lowerBound = normalized.mul(1000).div(10_000);

      // send sweep tx
      const tx = await adapter
        .connect(wallet)
        .sweep(constants.AddressZero, 3000, sweeping, lowerBound, 100);
      const receipt = await tx.wait();

      const emittedTopics = receipt.events.map((e) => e.topics[0]);
      expect(emittedTopics.includes(SWEPT_SIG)).to.be.true;
      expect(emittedTopics.includes(XCALL_SIG)).to.be.true;
      expect(emittedTopics.includes(DEPOSIT_SIG)).to.be.true;
      expect(emittedTopics.includes(SWAP_SIG)).to.be.true;

      // Ensure tokens got sent to connext
      expect(
        (await ethers.provider.getBalance(adapter.address)).toString()
      ).to.be.eq("0");
      // Only asserting balance increased
      expect((await tokenA.balanceOf(CONNEXT)).gt(initConnext)).to.be.true;
    });
  });
});
