// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IDSA} from "../../../../integration/Instadapp/interfaces/IDSA.sol";
import {TestHelper} from "../../../utils/TestHelper.sol";
import {InstadappAdapter} from "../../../../integration/Instadapp/InstadappAdapter.sol";

contract MockInstadappReceiver is InstadappAdapter {
  constructor() {}

  function tryAuthCast(
    address dsaAddress,
    address auth,
    bytes memory signature,
    CastData memory castData,
    bytes32 salt
  ) external payable {
    authCast(dsaAddress, auth, signature, castData, salt);
  }

  function tryVerify(
    address auth,
    bytes memory signature,
    CastData memory castData,
    bytes32 salt
  ) public view returns (bool) {
    return verify(auth, signature, castData, salt);
  }
}

contract InstadappAdapterTest is TestHelper {
  // ============ Storage ============
  address dsa = address(1);
  MockInstadappReceiver instadappReceiver;

  // ============ Test set up ============
  function setUp() public override {
    super.setUp();
    instadappReceiver = new MockInstadappReceiver();
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
    instadappReceiver.tryAuthCast(dsa, auth, signature, castData, salt);
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
    instadappReceiver.tryAuthCast(dsa, auth, signature, castData, salt);
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
      memory signature = hex"e06eb18ed5fa1258094a9af413275fc057cb5139b4e48c979a7ef9d028e8748e39bfa2ea23722f296a07ae7a2d2fee26c7de3ad067a2c569819bec0fc3c9f0f51b";

    address auth = originSender;
    instadappReceiver.tryAuthCast{value: 1}(dsa, auth, signature, castData, salt);
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
      memory signature = hex"e06eb18ed5fa1258094a9af413275fc057cb5139b4e48c979a7ef9d028e8748e39bfa2ea23722f296a07ae7a2d2fee26c7de3ad067a2c569819bec0fc3c9f0f51b";

    address auth = originSender;
    assertEq(instadappReceiver.tryVerify(auth, signature, castData, salt), true);
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
    assertEq(instadappReceiver.tryVerify(auth, signature, castData, salt), false);
  }
}
