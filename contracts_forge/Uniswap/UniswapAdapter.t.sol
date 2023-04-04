// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../utils/TestHelper.sol";
import "../../contracts/xreceivers/Swap/SwapAdapter.sol";
import "../../contracts/test/TestERC20/TestERC20.sol";

import "@mean-finance/nft-descriptors/solidity/interfaces/IDCAHubPositionDescriptor.sol";
import {IDCAHub} from "@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol";

contract UniswapAdapterTest is TestHelper {
  // ============ Errors ============
  // error ProposedOwnable__onlyOwner_notOwner();

  // ============ Events ============
  // ============ Storage ============
  SwapAdapter private adapter;
  TestERC20 private tokenA;
  TestERC20 private tokenB;
  bytes32 public transferId = keccak256("12345");
  uint32 public amount = 10;
  address private sender = address(2);

  function setUp() public override {
    super.setUp();
    adapter = new SwapAdapter();
    tokenA = new TestERC20("TokenA", "TokenA");
    tokenB = new TestERC20("TokenB", "TokenB");

    vm.label(address(this), "TestContract");
    vm.label(address(adapter), "UniswapAdapter");
  }

  // ============ UniswapAdapter.xReceive ============
  function test_UniswapAdapterTest__swap_shouldWork() public {
    tokenA.mint(sender, 1 ether);
    vm.prank(sender);
    vm.expectEmit(true, true, false, true);
    emit log("here");
    // adapter.exactSwap(address(tokenA), address(tokenB), 3000, 100, 100);
  }
}
