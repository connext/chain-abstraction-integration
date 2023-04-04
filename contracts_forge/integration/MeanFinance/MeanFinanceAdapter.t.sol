// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "../../utils/TestHelper.sol";
import {MeanFinanceAdapter} from "../../../contracts/integration/MeanFinance/MeanFinanceAdapter.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@mean-finance/nft-descriptors/solidity/interfaces/IDCAHubPositionDescriptor.sol";
import {IDCAHub} from "@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol";

contract MeanFinanceAdapterTest is TestHelper {
  // ============ Errors ============
  // error ProposedOwnable__onlyOwner_notOwner();

  // ============ Events ============
  // ============ Storage ============
  address private connext = address(1);
  address public notOriginSender = address(bytes20(keccak256("NotOriginSender")));

  address private deposit_from;
  address private deposit_to;
  uint32 private deposit_amount;
  uint32 private deposit_amountOfSwaps;
  uint32 private deposit_swapInterval;
  address private deposit_owner;
  IDCAPermissionManager.Permission[] private permissions;
  IDCAPermissionManager.PermissionSet[] private deposit_permissions;
  // [    IDCAPermissionManager.PermissionSet(address(5), permissions)];

  MeanFinanceAdapter private adapter;
  IERC20 private tokenA;
  IERC20 private tokenB;
  bytes32 public transferId = keccak256("12345");
  uint32 public amount = 10;

  function setUp() public override {
    super.setUp();
    // adapter = new MeanFinanceAdapter();
    // tokenA = new ERC20("TokenA", "TokenA");
    // tokenB = new ERC20("TokenB", "TokenB");

    // vm.label(address(this), "TestContract");
    // vm.label(address(adapter), "MeanFinanceAdapter");

    // deposit_from = address(tokenA);
    // deposit_to = address(tokenB);
    // deposit_amount = 10;
    // deposit_amountOfSwaps = 10;
    // deposit_swapInterval = 2 * 60 * 1000; // 2mins
    // deposit_owner = address(4);
    // permissions = [IDCAPermissionManager.Permission.TERMINATE];
    // deposit_permissions = [IDCAPermissionManager.PermissionSet(address(5), permissions)];
  }

  // ============ MeanFinanceAdapter.xReceive ============
  function test_MeanFinanceAdapterTest__deposit_shouldWork() public {
    // vm.prank(MOCK_CONNEXT);
    // vm.expectEmit(true, true, false, true);
    // emit log("here");
    // adapter.deposit(
    //   deposit_from,
    //   deposit_to,
    //   deposit_amount,
    //   deposit_amountOfSwaps,
    //   deposit_swapInterval,
    //   deposit_owner,
    //   deposit_permissions
    // );
  }
}
