// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import {TestHelper} from "../../../utils/TestHelper.sol";
import {InstadappAdapter} from "../../../../integration/Instadapp/InstadappAdapter.sol";
import {InstadappTarget} from "../../../../integration/Instadapp/InstadappTarget.sol";
import {TestERC20} from "../../../TestERC20.sol";

contract MockInstadappReceiver is InstadappAdapter {
  constructor() {}

  function tryGetDigest(CastData memory castData, bytes32 salt, uint256 deadline) external returns (bytes32) {
    return getDigest(castData, salt, deadline);
  }
}

contract InstadappTargetTest is TestHelper, EIP712 {
  // ============ Storage ============
  InstadappTarget instadappTarget;
  address instadappReceiver = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;

  // ============ Events ============
  event AuthCast(
    bytes32 indexed transferId,
    address indexed dsaAddress,
    bool indexed success,
    address auth,
    bytes returnedData
  );

  // ============ Test set up ============
  function setUp() public override {
    super.setUp();
    MockInstadappReceiver _instadappReceiver = new MockInstadappReceiver();
    vm.etch(instadappReceiver, address(_instadappReceiver).code);

    instadappTarget = new InstadappTarget(MOCK_CONNEXT);
  }

  constructor() EIP712("InstaTargetAuth", "1") {}

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
    TestERC20 asset = new TestERC20("Test", "TST");

    // Mock callData of `xReceive`
    address originSender = vm.addr(1);
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
    bytes32 salt = bytes32(0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef);
    uint256 deadline = 10000;

    InstadappAdapter.CastData memory castData = InstadappAdapter.CastData(_targetNames, _datas, _origin);
    bytes32 digest = MockInstadappReceiver(instadappReceiver).tryGetDigest(castData, salt, deadline);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
    bytes memory signature = abi.encodePacked(r, s, v);
    address auth = originSender;
    bytes memory callData = abi.encode(dsa, auth, signature, castData);

    bytes memory returnedData = hex"";
    vm.expectEmit(true, false, false, true);
    emit AuthCast(transferId, dsa, false, auth, returnedData);
    deal(address(asset), address(instadappTarget), amount);
    vm.prank(MOCK_CONNEXT);
    instadappTarget.xReceive(transferId, amount, address(asset), address(0), 0, callData);
  }
}
