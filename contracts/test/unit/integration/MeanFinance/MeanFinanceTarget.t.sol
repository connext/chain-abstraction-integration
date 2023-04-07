// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDCAHubPositionHandler, IDCAPermissionManager} from "@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol";

import {TestHelper} from "../../../utils/TestHelper.sol";
import {MeanFinanceTarget} from "../../../../contracts/integration/MeanFinance/MeanFinanceTarget.sol";
import {MeanFinanceAdapter} from "../../../../contracts/integration/MeanFinance/MeanFinanceAdapter.sol";

contract MeanTest is MeanFinanceTarget {
  constructor(address _connext, address _hub) MeanFinanceTarget(_connext, _hub) {}

  function forwardFunctionCall(
    bytes memory _preparedData,
    bytes32 _transferId,
    uint256 _amount,
    address _asset
  ) public returns (bool) {
    return _forwardFunctionCall(_preparedData, _transferId, _amount, _asset);
  }
}

contract MeanFinanceTargetTest is TestHelper {
  // ============ Errors ============
  // error ProposedOwnable__onlyOwner_notOwner();

  // ============ Events ============
  event XReceiveDeposit(
    // must be amount in bridge asset less fees
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes _callData,
    uint256 _positionId
  );

  // ============ Storage ============
  address private connext = address(1);
  address private hub = address(2);
  address public notOriginSender = address(bytes20(keccak256("NotOriginSender")));

  address private deposit_from = address(2);
  address private deposit_to = address(3);
  uint32 private deposit_amount = 10;
  uint32 private deposit_amountOfSwaps = 10;
  uint32 private deposit_swapInterval = 10;
  address private deposit_owner = address(4);
  // IDCAPermissionManager.Permission[]  permissions;
  IDCAPermissionManager.PermissionSet[] deposit_permissions;
  // [    IDCAPermissionManager.PermissionSet(address(5), permissions)];

  MeanTest private target;
  bytes32 public transferId = keccak256("12345");
  uint32 public amount = 10;

  address public immutable UNISWAP = address(5);

  function setUp() public override {
    super.setUp();
    target = new MeanTest(MOCK_CONNEXT, UNISWAP);

    vm.label(address(this), "TestContract");
    vm.label(address(target), "MeanFinanceTarget");
  }

  // ============ MeanFinanceTarget._forwardFunctionCall ============
  function test_MeanFinanceTargetTest___forwardFunctionCall_shouldWork() public {
    vm.prank(address(target));
    uint256 amountOut = 42;
    address from = address(7);
    address to = address(8);
    uint32 amountOfSwaps = 1;
    uint32 swapInterval = 2;
    address owner = address(9);
    IDCAPermissionManager.PermissionSet[] memory permissions = new IDCAPermissionManager.PermissionSet[](1);
    IDCAPermissionManager.Permission[] memory permission = new IDCAPermissionManager.Permission[](1);
    permission[0] = IDCAPermissionManager.Permission.INCREASE;
    permissions[0] = IDCAPermissionManager.PermissionSet(address(10), permission);
    bytes memory forwardCallData = abi.encode(from, to, amountOfSwaps, swapInterval, owner, permissions);
    bytes memory _preparedData = abi.encode(amountOut, forwardCallData);
    vm.mockCall(address(from), abi.encodeWithSelector(IERC20.approve.selector), abi.encode(10));
    vm.mockCall(
      address(hub),
      abi.encodeWithSignature(
        "deposit(address,address,uint256,uint32,uint32,address,IDCAPermissionManager.PermissionSet[])"
      ),
      abi.encode(10)
    );
    bool ret = target.forwardFunctionCall(_preparedData, transferId, amount, notOriginSender);
    assertEq(ret, true);
  }
}
