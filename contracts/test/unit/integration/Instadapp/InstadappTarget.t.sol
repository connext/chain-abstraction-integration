// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "../../../utils/TestHelper.sol";
import {InstadappAdapter} from "../../../../integration/Instadapp/InstadappAdapter.sol";
import {InstadappTarget} from "../../../../integration/Instadapp/InstadappTarget.sol";

contract InstadappTargetTest is TestHelper {
  // ============ Storage ============
  InstadappTarget instadappTarget;

  // ============ Events ============
  event AuthCast(bytes32 transferId, address dsaAddress, address auth, bool success, bytes returnedData);

  // ============ Test set up ============
  function setUp() public override {
    super.setUp();

    instadappTarget = new InstadappTarget(MOCK_CONNEXT);
  }

  function test_InstadappTarget__xReceive_shouldRevertIfCallerNotConnext() public {
    bytes32 transferId = keccak256(abi.encode(0x123));
    uint256 amount = 1 ether;
    address asset = address(0x123123123);
    bytes memory callData = bytes("123");

    vm.prank(address(0x456));
    vm.expectRevert(bytes("Caller must be Connext"));
    instadappTarget.xReceive(transferId, amount, asset, address(0), 0, callData);
  }

  function test_InstadappTarget__xReceive_shouldRevertIfFallbackAddressInvalid() public {
    // Mock xReceive data
    bytes32 transferId = keccak256(abi.encode(0x123));
    uint256 amount = 1 ether;
    address asset = address(0x123123123);

    // Mock callData of `xReceive`
    address originSender = address(0xc1aAED5D41a3c3c33B1978EA55916f9A3EE1B397);
    string[] memory _targetNames = new string[](3);
    _targetNames[0] = "target111";
    _targetNames[1] = "target222";
    _targetNames[2] = "target333";
    bytes[] memory _datas = new bytes[](3);
    _datas[0] = bytes("0x111");
    _datas[1] = bytes("0x222");
    _datas[2] = bytes("0x333");
    address _origin = originSender;

    InstadappAdapter.CastData memory castData = InstadappAdapter.CastData(_targetNames, _datas, _origin);
    bytes
      memory signature = hex"d75642b5e0cfceac682011943f3586fefc3709594a89bf8087acc58d2009d85412aca8b1f9b63989de45da85f5ffcea52cc5077a61a2128fa7322a97523afe0e1b";
    address auth = originSender;
    bytes memory callData = abi.encode(address(0), auth, signature, castData);

    vm.prank(MOCK_CONNEXT);
    vm.expectRevert(bytes("!invalidFallback"));
    instadappTarget.xReceive(transferId, amount, asset, address(0), 0, callData);
  }

  function test_InstadappTarget__xReceive_shouldWork() public {
    // Mock xReceive data
    bytes32 transferId = keccak256(abi.encode(0x123));
    uint256 amount = 1 ether;
    address asset = address(0x123123123);

    // Mock callData of `xReceive`
    address originSender = address(0xc1aAED5D41a3c3c33B1978EA55916f9A3EE1B397);
    string[] memory _targetNames = new string[](3);
    _targetNames[0] = "target111";
    _targetNames[1] = "target222";
    _targetNames[2] = "target333";
    bytes[] memory _datas = new bytes[](3);
    _datas[0] = bytes("0x111");
    _datas[1] = bytes("0x222");
    _datas[2] = bytes("0x333");
    address _origin = originSender;
    address dsa = address(0x111222333);

    InstadappAdapter.CastData memory castData = InstadappAdapter.CastData(_targetNames, _datas, _origin);
    bytes
      memory signature = hex"d75642b5e0cfceac682011943f3586fefc3709594a89bf8087acc58d2009d85412aca8b1f9b63989de45da85f5ffcea52cc5077a61a2128fa7322a97523afe0e1b";
    address auth = originSender;
    bytes memory callData = abi.encode(dsa, auth, signature, castData);

    bytes memory returnedData = hex"";
    vm.prank(MOCK_CONNEXT);
    vm.expectEmit(true, false, false, true);
    emit AuthCast(transferId, dsa, auth, false, returnedData);
    instadappTarget.xReceive(transferId, amount, asset, address(0), 0, callData);
  }
}
