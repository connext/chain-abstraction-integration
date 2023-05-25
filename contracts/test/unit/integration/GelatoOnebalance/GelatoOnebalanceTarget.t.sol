// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "../../../utils/TestHelper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {GelatoOneBalanceTarget} from "../../../../integration/GelatoOnebalance/GelatoOnebalanceTarget.sol";

contract GelatoOneBalanceTest is GelatoOneBalanceTarget {
  constructor(address _connext, address _gelato1balance) GelatoOneBalanceTarget(_connext, _gelato1balance) {}

  function forwardFunctionCall(
    bytes memory _preparedData,
    bytes32 _transferId,
    uint256 _amount,
    address _asset
  ) public returns (bool) {
    return _forwardFunctionCall(_preparedData, _transferId, _amount, _asset);
  }
}

contract GelatoOneBalanceTargetTest is TestHelper {
   // ============ Errors ============
  // error ProposedOwnable__onlyOwner_notOwner();

  // ============ Storage ============
  address private connext = address(1);
  address private gelatoOneBalance = address(2);
  address public notOriginSender = address(bytes20(keccak256("NotOriginSender")));
  address private sponsor = address(3);
  address private token = address(4);

  GelatoOneBalanceTest private target;
  bytes32 public transferId = keccak256("12345");
  uint32 public amount = 10;

  function setUp() public override {
    super.setUp();
    target = new GelatoOneBalanceTest(MOCK_CONNEXT, gelatoOneBalance);

    vm.label(address(this), "TestContract");
    vm.label(address(target), "GelatoOneBalanceTarget");

  }

  function test__GelatoOneBalanceTargetTest__forwardCall_works (uint256 _amountOut) public {
    vm.prank(address(target));
    uint256 amountOut = 9;
    bytes memory forwardCallData = abi.encode(sponsor, token);
    bytes memory _preparedData = abi.encode(forwardCallData, amountOut, address(0), address(0));
    vm.mockCall(token, abi.encodeWithSelector(IERC20.approve.selector), abi.encode(true));
    vm.mockCall(
      gelatoOneBalance,
      abi.encodeWithSignature(
        "depositToken(address,address,uint256)"
      ),
      abi.encode(10)
    );

    bool ret = target.forwardFunctionCall(_preparedData, transferId, amount, notOriginSender);
    assertEq(ret, true);
  }
}
