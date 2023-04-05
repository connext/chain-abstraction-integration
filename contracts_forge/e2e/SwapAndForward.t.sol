// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {TestHelper} from "../utils/TestHelper.sol";
import {Greeter} from "../utils/Greeter.sol";
import {XSwapAndGreet} from "../../contracts/example/XSwapAndGreet.sol";
import {OneInchUniswapV3} from "../../contracts/xreceivers/Swap/OneInch/OneInchUniswapV3.sol";

// data from 1inch API: 0xe449022e0000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000000000000000000000000000000000000070015a0d00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001000000000000000000000000641c00a822e8b671738d32a431a4fb6074e5c79dcfee7c08
// WETH whale: 0xee9dec2712cce65174b561151701bf54b99c24c8
contract SwapAndForwardTest is TestHelper {
  Greeter greeter;
  XSwapAndGreet xSwapAndGreet;
  OneInchUniswapV3 oneInchUniswapV3;
  address immutable ARBITRUM_1INCH_SWAPPER = 0x1111111254EEB25477B68fb85Ed929f73A960582;
  address immutable WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

  function setUp() public override {
    super.setUp();

    greeter = new Greeter();
    xSwapAndGreet = new XSwapAndGreet(address(greeter), MOCK_CONNEXT);
    oneInchUniswapV3 = new OneInchUniswapV3();
    xSwapAndGreet.addSwapper(address(oneInchUniswapV3)); // 1inch address on arbitrum

    // transfer funds to xreceiver
    vm.prank(0xEE9deC2712cCE65174B561151701Bf54b99C24C8);
    TransferHelper.safeTransfer(WETH, address(xSwapAndGreet), 1 ether);

    vm.label(address(this), "TestContract");
    vm.label(address(greeter), "Greeter");
    vm.label(address(xSwapAndGreet), "XSwapAndGreet");
    vm.label(ARBITRUM_1INCH_SWAPPER, "1inchSwapper");
    vm.label(WETH, "WETH");
  }

  function test_SwapAndForwardTest__works() public {
    vm.prank(MOCK_CONNEXT);
    bytes
      memory _swapData = hex"e449022e0000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000000000000000702370a700000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001000000000000000000000000641c00a822e8b671738d32a431a4fb6074e5c79dcfee7c08";
    bytes memory _forwardCallData = abi.encode("Hello, Connext!");
    bytes memory _swapperData = abi.encode(address(oneInchUniswapV3), _swapData, _forwardCallData);
    bytes memory _callData = abi.encode(address(1), _swapperData);
    xSwapAndGreet.xReceive(bytes32(""), 1 ether, WETH, address(0), 0, _callData);
  }
}
