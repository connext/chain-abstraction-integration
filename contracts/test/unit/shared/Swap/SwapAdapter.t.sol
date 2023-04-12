// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SwapAdapter} from "../../../../shared/Swap/SwapAdapter.sol";
import {ISwapper} from "../../../../shared/Swap/interfaces/ISwapper.sol";
import {TestHelper} from "../../../utils/TestHelper.sol";

contract SwapAdapterTest is TestHelper {
  // ============ Storage ============
  SwapAdapter swapAdapter;
  address owner = address(0x1);

  // ============ Test set up ============
  function setUp() public override {
    super.setUp();

    vm.prank(owner);
    swapAdapter = new SwapAdapter();
  }

  // ============ SwapAdapter.addSwapper ============
  function test_SwapAdapter__addSwapper_revertIfNotOwner() public {
    address swapper = address(0x111);
    vm.prank(address(0x2));
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    swapAdapter.addSwapper(swapper);
    assertEq(swapAdapter.allowedSwappers(swapper), false);
  }

  function test_SwapAdapter__addSwapper_shouldWork() public {
    address swapper = address(0x111);
    vm.prank(owner);
    swapAdapter.addSwapper(swapper);
    assertEq(swapAdapter.allowedSwappers(swapper), true);
  }

  // ============ SwapAdapter.removeSwapper ============
  function test_SwapAdapter__removeSwapper_revertIfNotOwner() public {
    address swapper = address(0x111);
    vm.prank(owner);
    swapAdapter.addSwapper(swapper);
    assertEq(swapAdapter.allowedSwappers(swapper), true);

    vm.prank(address(0x2));
    vm.expectRevert(bytes("Ownable: caller is not the owner"));
    swapAdapter.removeSwapper(swapper);
    assertEq(swapAdapter.allowedSwappers(swapper), true);
  }

  function test_SwapAdapter__removeSwapper_shouldWork() public {
    address swapper = address(0x111);
    vm.prank(owner);
    swapAdapter.addSwapper(swapper);
    assertEq(swapAdapter.allowedSwappers(swapper), true);

    vm.prank(owner);
    swapAdapter.removeSwapper(swapper);
    assertEq(swapAdapter.allowedSwappers(swapper), false);
  }

  // ============ SwapAdapter.exactSwap ============
  function test_SwapAdapter__exactSwap_revertIfNotAllowedSwap() public {
    address swapper = address(0x111);
    vm.mockCall(swapper, abi.encodeWithSelector(ISwapper.swap.selector), abi.encode(100));

    uint256 amountIn = 100;
    address fromAsset = address(0x12345);
    address toAsset = address(0x54321);
    bytes memory swapData = bytes("0x");
    vm.expectRevert(bytes("!allowedSwapper"));
    swapAdapter.exactSwap(swapper, amountIn, fromAsset, toAsset, swapData);
  }

  function test_SwapAdapter__exactSwap_shouldWork() public {
    address swapper = address(0x111);
    vm.prank(owner);
    swapAdapter.addSwapper(swapper);

    uint256 amountIn = 100;
    address fromAsset = address(0x12345);
    address toAsset = address(0x54321);
    bytes memory swapData = bytes("0x");

    vm.mockCall(fromAsset, abi.encodeWithSelector(IERC20.allowance.selector), abi.encode(0));
    vm.mockCall(fromAsset, abi.encodeWithSelector(IERC20.approve.selector), abi.encode(true));
    vm.mockCall(swapper, abi.encodeWithSelector(ISwapper.swap.selector), abi.encode(100));

    swapAdapter.exactSwap(swapper, amountIn, fromAsset, toAsset, swapData);
  }

  // ============ SwapAdapter.directSwapperCall ============
  function testFail_SwapAdapter__directSwapperCall_shouldWork() public {
    address swapper = address(0x111);
    vm.prank(owner);
    swapAdapter.addSwapper(swapper);
    bytes memory swapData = bytes("0x");
    swapAdapter.directSwapperCall(swapper, swapData);
  }
}
