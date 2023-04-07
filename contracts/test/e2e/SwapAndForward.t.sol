// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TestHelper} from "../utils/TestHelper.sol";
import {Greeter} from "../utils/Greeter.sol";
import {XSwapAndGreet} from "../../example/XSwapAndGreet.sol";
import {OneInchUniswapV3} from "../../shared/Swap/OneInch/OneInchUniswapV3.sol";

// data from 1inch API: 0xe449022e0000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000000000000000000000000000000000000070015a0d00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001000000000000000000000000641c00a822e8b671738d32a431a4fb6074e5c79dcfee7c08
// WETH whale: 0xee9dec2712cce65174b561151701bf54b99c24c8
contract SwapAndForwardTest is TestHelper {
  Greeter greeter;
  XSwapAndGreet xSwapAndGreet;
  OneInchUniswapV3 oneInchUniswapV3;
  address immutable ARBITRUM_1INCH_SWAPPER = 0x1111111254EEB25477B68fb85Ed929f73A960582;
  address immutable WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address immutable USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

  function setUp() public override {
    super.setUp();
    string memory defaultRpc = "https://arb1.arbitrum.io/rpc";
    string memory rpc = vm.envOr("ARBITRUM_RPC_URL", defaultRpc);
    uint256 forkId = vm.createFork(rpc, 77657931);
    vm.selectFork(forkId);
  }

  function utils_testSetup() public {
    greeter = new Greeter();
    xSwapAndGreet = new XSwapAndGreet(address(greeter), MOCK_CONNEXT);
    oneInchUniswapV3 = new OneInchUniswapV3(ARBITRUM_1INCH_SWAPPER);
    xSwapAndGreet.addSwapper(address(oneInchUniswapV3)); // 1inch address on arbitrum

    // transfer funds to xreceiver
    vm.prank(0xEE9deC2712cCE65174B561151701Bf54b99C24C8);
    TransferHelper.safeTransfer(WETH, address(xSwapAndGreet), 1 ether);

    vm.label(address(this), "TestContract");
    vm.label(address(greeter), "Greeter");
    vm.label(address(xSwapAndGreet), "XSwapAndGreet");
    vm.label(address(oneInchUniswapV3), "OneInchUniswapV3");
    vm.label(ARBITRUM_1INCH_SWAPPER, "Real1InchSwapper");
    vm.label(WETH, "WETH");
    vm.label(USDT, "USDT");
  }

  function test_SwapAndForwardTest__works() public {
    utils_testSetup();

    vm.prank(MOCK_CONNEXT);
    bytes
      memory _swapData = hex"e449022e0000000000000000000000000000000000000000000000000de0b6b3a7640000000000000000000000000000000000000000000000000000000000006e21188700000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001000000000000000000000000641c00a822e8b671738d32a431a4fb6074e5c79dcfee7c08";
    bytes memory _forwardCallData = abi.encode("Hello, Connext!");
    bytes memory _swapperData = abi.encode(address(oneInchUniswapV3), USDT, _swapData, _forwardCallData);
    bytes memory _callData = abi.encode(address(1), _swapperData);
    bool success = xSwapAndGreet.xReceive(bytes32(""), 1 ether, WETH, address(0), 0, _callData);
    assertTrue(success);
    assertEq(greeter.greeting(), "Hello, Connext!");
    uint256 _greeterBalance = IERC20(USDT).balanceOf(address(greeter));
    assertEq(_greeterBalance, 1865608674);
  }
}
