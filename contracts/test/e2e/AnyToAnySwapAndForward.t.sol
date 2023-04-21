// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {SwapAndXCall} from "../../origin/Swap/SwapAndXCall.sol";
import {TestHelper} from "../utils/TestHelper.sol";
import {Greeter} from "../utils/Greeter.sol";
import {XSwapAndGreetTarget} from "../../example/XSwapAndGreet/XSwapAndGreetTarget.sol";
import {OneInchUniswapV3} from "../../shared/Swap/OneInch/OneInchUniswapV3.sol";

contract AnyToAnySwapAndForwardTest is TestHelper {
  SwapAndXCall swapAndXCall;
  Greeter greeter;
  XSwapAndGreetTarget xSwapAndGreetTarget;
  OneInchUniswapV3 oneInchUniswapV3;

  address public immutable OP_OP = 0x4200000000000000000000000000000000000042;
  address public immutable OP_USDC = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
  address public immutable ARB_USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
  address public immutable ARB_ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;

  address public immutable ONEINCH_SWAPPER = 0x1111111254EEB25477B68fb85Ed929f73A960582;

  address public immutable FALLBACK_ADDRESS = address(1);

  function setUp() public override {
    super.setUp();
    setUpCrossChainE2E(OPTIMISM_CHAIN_ID, ARBITRUM_CHAIN_ID, 87307161, 78000226, ARB_USDC);
  }

  function utils_setUpOrigin() public {
    vm.selectFork(chainConfigs[OPTIMISM_CHAIN_ID].forkId);
    swapAndXCall = new SwapAndXCall(chainConfigs[OPTIMISM_CHAIN_ID].connext);
    deal(OP_OP, address(this), 1000 ether);

    vm.label(address(swapAndXCall), "SwapAndXCall");
    vm.label(address(this), "AnyToAnySwapAndForwardTest");
    vm.label(OP_OP, "OP_OP");
    vm.label(OP_USDC, "OP_USDC");
  }

  function utils_setUpDestination() public {
    vm.selectFork(chainConfigs[ARBITRUM_CHAIN_ID].forkId);
    greeter = new Greeter();
    xSwapAndGreetTarget = new XSwapAndGreetTarget(address(greeter), chainConfigs[ARBITRUM_CHAIN_ID].connext);
    oneInchUniswapV3 = new OneInchUniswapV3(ONEINCH_SWAPPER);
    xSwapAndGreetTarget.addSwapper(address(oneInchUniswapV3)); // 1inch address on arbitrum

    vm.label(address(greeter), "Greeter");
    vm.label(address(xSwapAndGreetTarget), "XSwapAndGreetTarget");
    vm.label(address(oneInchUniswapV3), "OneInchUniswapV3");
    vm.label(ARB_ARB, "ARB_ARB");
    vm.label(ARB_USDC, "ARB_USDC");
  }

  function test_AnyToAnySwapAndForwardTest__works() public {
    utils_setUpOrigin();
    utils_setUpDestination();

    vm.selectFork(chainConfigs[OPTIMISM_CHAIN_ID].forkId);
    assertEq(vm.activeFork(), chainConfigs[OPTIMISM_CHAIN_ID].forkId);

    // origin
    // start with OP and swap to USDC to bridge to destination
    TransferHelper.safeApprove(OP_OP, address(swapAndXCall), 1000 ether);
    bytes
      memory oneInchApiDataOpToUsdc = hex"e449022e00000000000000000000000000000000000000000000003635c9adc5dea00000000000000000000000000000000000000000000000000000000000005073d59500000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000002800000000000000000000000fc1f3296458f9b2a27a0b91dd7681c4020e09d0500000000000000000000000085149247691df622eaf1a8bd0cafd40bc45154a9cfee7c08";

    TransferHelper.safeApprove(OP_OP, ONEINCH_SWAPPER, 1000 ether);
    // destination
    // set up destination swap params
    bytes
      memory oneInchApiDataUsdcToArb = hex"e449022e0000000000000000000000000000000000000000000000000000000005f5e100000000000000000000000000000000000000000000000004188a80f4c2e52ccf00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001800000000000000000000000cda53b1f66614552f834ceef361a8d12a0b8dad8cfee7c08";

    bytes memory _forwardCallData = abi.encode("Hello, Connext!");
    bytes memory _swapperData = abi.encode(
      address(oneInchUniswapV3),
      ARB_ARB,
      oneInchApiDataUsdcToArb,
      _forwardCallData
    );

    // final calldata includes both origin and destination swaps
    bytes memory callData = abi.encode(FALLBACK_ADDRESS, _swapperData);
    // set up swap calldata
    swapAndXCall.swapAndXCall(
      OP_OP,
      OP_USDC,
      1000 ether,
      ONEINCH_SWAPPER,
      oneInchApiDataOpToUsdc,
      chainConfigs[ARBITRUM_CHAIN_ID].domainId,
      address(greeter),
      address(this),
      300,
      callData,
      123 // fake relayer fee, will be in USDC
    );

    vm.selectFork(chainConfigs[ARBITRUM_CHAIN_ID].forkId);
    // vm.prank(ARB_USDC_WHALE);
    // TransferHelper.safeTransfer(ARB_USDC, address(xSwapAndGreetTarget), 99800000);
    // vm.prank(CONNEXT_ARBITRUM);
    // xSwapAndGreetTarget.xReceive(
    //   bytes32(""),
    //   99800000, // Final Amount receive via Connext(After AMM calculation)
    //   ARB_USDC,
    //   address(0),
    //   123,
    //   callData
    // );
    assertEq(greeter.greeting(), "Hello, Connext!");
    assertEq(IERC20(ARB_ARB).balanceOf(address(greeter)), 83059436227592757201);
  }
}
