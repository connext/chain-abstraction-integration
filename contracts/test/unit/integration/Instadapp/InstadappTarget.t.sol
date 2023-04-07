// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "../../../utils/TestHelper.sol";

contract InstadappTargetTest is TestHelper {
  function setUp() public override {}

  function test_InstadappAdapter__xReceive_shouldRevertIfCallerNotConnext() public {}

  function test_InstadappAdapter__xReceive_shouldRevertIfFallbackAddressInvalid() public {}

  function test_InstadappAdapter__xReceive_shouldWork() public {}
}
