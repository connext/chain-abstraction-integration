// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IDSA} from "../../../../integration/Instadapp/interfaces/IDSA.sol";
import {TestHelper} from "../../../utils/TestHelper.sol";
import {InstadappAdapter} from "../../../../integration/Instadapp/InstadappAdapter.sol";
import "forge-std/console.sol";

contract MockInstadappReceiver is InstadappAdapter {
  constructor() {}

  function tryAuthCast(
    address dsaAddress,
    address auth,
    bytes memory signature,
    CastData memory castData,
    bytes32 salt,
    uint256 deadline
  ) external payable {
    authCast(dsaAddress, auth, signature, castData, salt, deadline);
  }

  function tryVerify(
    address auth,
    bytes memory signature,
    CastData memory castData,
    bytes32 salt,
    uint256 deadline
  ) external returns (bool) {
    return verify(auth, signature, castData, salt, deadline);
  }
}

contract InstadappAdapterTest is TestHelper {
  // ============ Storage ============
  address dsa = address(1);
  address instadappReceiver = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;

  uint256 deadline = 100;
  uint256 timestamp = 90;

  // ============ Test set up ============
  function setUp() public override {
    super.setUp();
    MockInstadappReceiver _instadappReceiver = new MockInstadappReceiver();
    vm.etch(instadappReceiver, address(_instadappReceiver).code);
  }

  // ============ Utils ============
  function utils_dsaMocks(bool isAuth) public {
    vm.mockCall(dsa, abi.encodeWithSelector(IDSA.isAuth.selector), abi.encode(isAuth));
    vm.mockCall(dsa, abi.encodeWithSelector(IDSA.cast.selector), abi.encode(bytes32(abi.encode(1))));
  }

  // ============ InstadappAdapter.authCast ============
  function test_InstadappAdapter__authCast_shouldRevertIfInvalidAuth() public {
    utils_dsaMocks(false);

    address originSender = address(0x123);

    string[] memory _targetNames = new string[](2);
    _targetNames[0] = "target1";
    _targetNames[1] = "target2";
    bytes[] memory _datas = new bytes[](2);
    _datas[0] = bytes("data1");
    _datas[1] = bytes("data2");
    address _origin = originSender;

    InstadappAdapter.CastData memory castData = InstadappAdapter.CastData(_targetNames, _datas, _origin);

    bytes memory signature = bytes("0x111");
    address auth = originSender;
    bytes32 salt = bytes32(abi.encode(1));

    vm.expectRevert(bytes("Invalid Auth"));
    MockInstadappReceiver(instadappReceiver).tryAuthCast(dsa, auth, signature, castData, salt, deadline);
  }

  function test_InstadappAdapter__authCast_shouldRevertIfInvalidSignature() public {
    utils_dsaMocks(true);

    address originSender = address(0x123);

    string[] memory _targetNames = new string[](2);
    _targetNames[0] = "target1";
    _targetNames[1] = "target2";
    bytes[] memory _datas = new bytes[](2);
    _datas[0] = bytes("data1");
    _datas[1] = bytes("data2");
    address _origin = originSender;

    InstadappAdapter.CastData memory castData = InstadappAdapter.CastData(_targetNames, _datas, _origin);

    bytes
      memory signature = hex"e91f49cb8bf236eafb590ba328a6ca75f4d189fa51bfce2ac774541801c17d3f2d3df798f18c0520db5a98d33362d507f890d5904c2aea1dd059a9b0f05fb3ad1c";

    address auth = originSender;
    bytes32 salt = bytes32(abi.encode(1));
    vm.expectRevert(bytes("Invalid signature"));
    MockInstadappReceiver(instadappReceiver).tryAuthCast(dsa, auth, signature, castData, salt, deadline);
  }

  function test_InstadappAdapter__authCast_shouldWork() public {
    utils_dsaMocks(true);

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
    bytes32 salt = bytes32(abi.encode(1));

    InstadappAdapter.CastData memory castData = InstadappAdapter.CastData(_targetNames, _datas, _origin);

    bytes
      memory signature = hex"ec163cca0d31ea58537dfff8377fdbd957fb0ba58088f74436af944bf1c3248148910f14a13b7d0b6d707fb7478cfd7f9ae3830b02d0a5e5584ef7648460a8d71c";

    address auth = originSender;
    vm.warp(timestamp);
    MockInstadappReceiver(instadappReceiver).tryAuthCast{value: 1}(dsa, auth, signature, castData, salt, deadline);
  }

  // ============ InstadappAdapter.verify ============
  function test_InstadappAdapter__verify_shouldReturnTrue() public {
    utils_dsaMocks(true);

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
    bytes32 salt = bytes32(abi.encode(1));

    InstadappAdapter.CastData memory castData = InstadappAdapter.CastData(_targetNames, _datas, _origin);

    bytes
      memory signature = hex"ec163cca0d31ea58537dfff8377fdbd957fb0ba58088f74436af944bf1c3248148910f14a13b7d0b6d707fb7478cfd7f9ae3830b02d0a5e5584ef7648460a8d71c";

    address auth = originSender;
    vm.warp(timestamp);
    assertEq(MockInstadappReceiver(instadappReceiver).tryVerify(auth, signature, castData, salt, deadline), true);
  }

  function test_InstadappAdapter__verify_shouldReturnFalse() public {
    utils_dsaMocks(true);

    address originSender = address(0x123);

    string[] memory _targetNames = new string[](2);
    _targetNames[0] = "target1";
    _targetNames[1] = "target2";
    bytes[] memory _datas = new bytes[](2);
    _datas[0] = bytes("data1");
    _datas[1] = bytes("data2");
    address _origin = originSender;

    InstadappAdapter.CastData memory castData = InstadappAdapter.CastData(_targetNames, _datas, _origin);

    bytes
      memory signature = hex"e91f49cb8bf236eafb590ba328a6ca75f4d189fa51bfce2ac774541801c17d3f2d3df798f18c0520db5a98d33362d507f890d5904c2aea1dd059a9b0f05fb3ad1c";

    address auth = originSender;
    bytes32 salt = bytes32(abi.encode(1));
    assertEq(MockInstadappReceiver(instadappReceiver).tryVerify(auth, signature, castData, salt, deadline), false);
  }
}
