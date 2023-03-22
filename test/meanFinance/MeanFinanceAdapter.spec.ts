import { expect } from 'chai'
import { ethers } from 'hardhat'
import { BigNumber, constants, Contract, utils, Wallet } from 'ethers'
import { DEFAULT_ARGS } from '../../deploy'
import { SwapInterval } from '../../utils/interval-utils'
import { deploy, fund, ERC20_ABI } from '../helpers'

describe('MeanFinanceAdapter', function () {
  // Set up constants (will mirror what deploy fixture uses)
  const { WETH, USDC } = DEFAULT_ARGS[31337]
  const MEAN_FINANCE_IDCAHUB = '0xA5AdC5484f9997fBF7D405b9AA62A7d88883C345'
  const WHALE = '0x385BAe68690c1b86e2f1Ad75253d080C14fA6e16' // this is the address that should have weth, adapter, and random addr
  const NOT_ZERO_ADDRESS = '0x7088C5611dAE159A640d940cde0a3221a4af8896'
  const RANDOM_TOKEN = '0x4200000000000000000000000000000000000042' // this is OP
  const ASSET_DECIMALS = 6 // USDC decimals on op

  // Set up variables
  let adapter: Contract
  let wallet: Wallet
  let whale: Wallet
  let tokenA: Contract
  let weth: Contract
  let randomToken: Contract

  enum Permission {
    INCREASE,
    REDUCE,
    WITHDRAW,
    TERMINATE,
  }

  before(async () => {
    // get wallet
    ;[wallet] = ((await ethers.getSigners()) as unknown) as Wallet[]
    // get whale
    whale = ((await ethers.getImpersonatedSigner(WHALE)) as unknown) as Wallet

    const { instance } = await deploy('MeanFinanceAdapter')
    adapter = instance

    // setup tokens
    tokenA = new ethers.Contract(USDC, ERC20_ABI, ethers.provider)
    weth = new ethers.Contract(WETH, ERC20_ABI, ethers.provider)
    randomToken = new ethers.Contract(RANDOM_TOKEN, ERC20_ABI, ethers.provider)
  })

  describe('constructor', () => {
    it('should deploy correctly', async () => {
      // Ensure all properties set correctly
      expect(await adapter.hub()).to.be.eq(MEAN_FINANCE_IDCAHUB)
      // Ensure whale is okay
      expect(whale.address).to.be.eq(WHALE)
      expect(tokenA.address).to.be.eq(USDC)
    })
  })

  describe('deposit', () => {
    before(async () => {
      // fund the adapter contract with eth, random token, and adapter asset
      await fund(
        constants.AddressZero,
        utils.parseEther('1'),
        wallet,
        adapter.address,
      )

      await fund(
        USDC,
        utils.parseUnits('1', ASSET_DECIMALS),
        whale,
        adapter.address,
      )

      await fund(
        randomToken.address,
        utils.parseUnits('1', await randomToken.decimals()),
        whale,
        adapter.address,
      )
    })

    it('should work', async () => {
      // get reasonable amount out
      const adapterBalance = await randomToken.balanceOf(adapter.address)

      const permissions = [
        { operator: NOT_ZERO_ADDRESS, permissions: [Permission.INCREASE] },
      ]

      const swaps = 10
      const interval = SwapInterval.ONE_DAY.seconds

      // send sweep tx
      const tx = await adapter
        .connect(wallet)
        .deposit(
          randomToken.address,
          tokenA.address,
          BigNumber.from(adapterBalance),
          swaps,
          interval,
          wallet.address,
          permissions,
        )
      const receipt = await tx.wait()
      // Ensure tokens got sent to connext
      expect(
        (await randomToken.balanceOf(adapter.address)).toString(),
      ).to.be.eq('0')
    })
  })
})
