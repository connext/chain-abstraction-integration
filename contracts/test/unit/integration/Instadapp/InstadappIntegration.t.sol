// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {TestHelper} from "../../../utils/TestHelper.sol";
import {InstadappAdapter} from "../../../../integration/Instadapp/InstadappAdapter.sol";
import {InstadappTarget} from "../../../../integration/Instadapp/InstadappTarget.sol";

interface IDSA {
  function cast(
    string[] calldata _targetNames,
    bytes[] calldata _datas,
    address _origin
  ) external payable returns (bytes32);
}

interface IndexInterface {
  function master() external view returns (address);
}

interface ConnectorInterface {
  function name() external view returns (string memory);

  function addConnectors(string[] calldata _connectorNames, address[] calldata _connectors) external;
}

contract InstadappIntegrationTest is TestHelper {
  // ============ Storage ============

  // Optimism as origin
  address public immutable OP_DSA = 0xaB8c8a4638269Ae0e764F14de7011718C9e59126;
  address public immutable OP_AUTH = 0x6d2A06543D23Cc6523AE5046adD8bb60817E0a94;
  address public immutable OP_USDC = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
  address public immutable OP_USDC_WHALE = 0x625E7708f30cA75bfd92586e17077590C60eb4cD;
  address public immutable CONNEXT_CONNECTOR = 0x0492B77bafd78E7124b0A6d81eFB470bF9aE53fC;
  address public immutable INSTA_CONNECTORS = 0x127d8cD0E2b2E0366D522DeA53A787bfE9002C14;
  address public immutable INSTA_INDEX = 0x6CE3e607C808b4f4C26B7F6aDAeB619e49CAbb25;

  // Arbitrum as destination
  address public immutable ARB_DSA = 0xF4335D224ad8425dDE0A5671820fF6b6Ba09Fab2;
  address public immutable ARB_AUTH = 0x6d2A06543D23Cc6523AE5046adD8bb60817E0a94;
  address public immutable ARB_USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
  address public immutable INSTADAPP_TARGET = 0x9E12F9D65DBfF6350a7526dC65005f6A3BFD835A;

  // ============ Events ============
  event AuthCast(bytes32 transferId, address dsaAddress, address auth, bool success, bytes returnedData);

  // ============ Data Types ============
  struct CastData {
    string[] _targetNames;
    bytes[] _datas;
    address _origin;
  }

  struct XCallParams {
    uint32 destination;
    address to;
    address asset;
    address delegate;
    uint256 amount;
    uint256 slippage;
    uint256 relayerFee;
    bytes callData;
  }

  uint256 AMOUNT = 1_000_000; // 1 USDC
  uint256 RELAYER_FEE = 0.03 ether; // conservative estimate

  // ============ Test set up ============
  function utils_setUpOrigin() public {
    setUpOptimism(91662662);
    vm.prank(OP_USDC_WHALE);
    TransferHelper.safeTransfer(OP_USDC, OP_DSA, AMOUNT); // send 1 USDC to DSA
    vm.deal(OP_DSA, RELAYER_FEE); // give DSA enough oETH for the relayer fee

    // register Connext connector
    address master = IndexInterface(INSTA_INDEX).master();
    vm.prank(master);
    string[] memory CONNEXT_CONNECTOR_NAME_ARRAY = new string[](1);
    address[] memory CONNEXT_CONNECTOR_ARRAY = new address[](1);
    CONNEXT_CONNECTOR_NAME_ARRAY[0] = "CONNEXT-A";
    CONNEXT_CONNECTOR_ARRAY[0] = CONNEXT_CONNECTOR;
    ConnectorInterface(INSTA_CONNECTORS).addConnectors(CONNEXT_CONNECTOR_NAME_ARRAY, CONNEXT_CONNECTOR_ARRAY);

    vm.label(OP_DSA, "OP_DSA");
    vm.label(OP_AUTH, "OP_AUTH");
    vm.label(OP_USDC, "OP_USDC");
    vm.label(OP_USDC_WHALE, "OP_USDC_WHALE");
    vm.label(CONNEXT_CONNECTOR, "ConnextConnector");
  }

  function utils_setUpDestination() public {
    setUpArbitrum(81518561);

    vm.label(ARB_DSA, "ARB_DSA");
    vm.label(ARB_AUTH, "ARB_AUTH");
    vm.label(ARB_USDC, "ARB_USDC");
    vm.label(INSTADAPP_TARGET, "InstadappTarget");
  }

  function setUp() public override {
    utils_setUpOrigin();
    utils_setUpDestination();
  }

  function test_CastXCallAndDepositUSDC__works() public {
    vm.selectFork(optimismForkId);
    assertEq(vm.activeFork(), optimismForkId);

    TransferHelper.safeApprove(OP_USDC, OP_DSA, AMOUNT);

    // construct the destination-side cast for a basic DSA deposit
    string[] memory _destinationTargets = new string[](1);
    bytes[] memory _destinationData = new bytes[](1);

    _destinationTargets[0] = "BASIC-A";

    bytes4 basicDeposit = bytes4(keccak256("deposit(address,uint256,uint256,uint256)"));

    _destinationData[0] = abi.encodeWithSelector(basicDeposit, ARB_USDC, AMOUNT, 0, 0);

    CastData memory destinationCastData = CastData(_destinationTargets, _destinationData, address(0));

    // construct the origin-side cast containing xcall
    string[] memory _originTargets = new string[](1);
    bytes[] memory _originData = new bytes[](1);

    _originTargets[0] = "CONNEXT-A";

    bytes4 xcall = bytes4(
      keccak256("xcall((uint32,address,address,address,uint256,uint256,uint256,bytes),uint256,uint256)")
    );
    uint256 slippage = 10000;
    bytes32 salt = bytes32(abi.encode(1));

    // generated offchain
    bytes
      memory signature = hex"28a88d49786afddb77f00cfcbd1032095e4109937c82e054a54dcddcf22dc9c247b4fae09369be5302d5e39355ebdc43dff77769ed077040972384534886676a1c";

    // to be decoded in xReceive of InstadappTarget
    bytes memory callData = abi.encode(ARB_DSA, ARB_AUTH, signature, destinationCastData, salt);

    XCallParams memory xCallParams = XCallParams(
      ARBITRUM_DOMAIN_ID,
      INSTADAPP_TARGET,
      ARB_USDC,
      OP_AUTH,
      AMOUNT,
      slippage,
      RELAYER_FEE,
      callData
    );

    _originData[0] = abi.encodeWithSelector(xcall, xCallParams, 0, 0);

    // cast!
    vm.prank(OP_AUTH);
    IDSA(OP_DSA).cast(_originTargets, _originData, address(0));

    // check destination calls
    vm.selectFork(arbitrumForkId);
    assertEq(vm.activeFork(), arbitrumForkId);
    vm.prank(CONNEXT_ARBITRUM);

    uint256 ammSwapSlippageAmount = 1000;
    InstadappTarget(INSTADAPP_TARGET).xReceive(
      bytes32(""), // transferId
      AMOUNT - ammSwapSlippageAmount, // amount
      ARB_USDC, // asset
      OP_AUTH, // originSender
      OPTIMISM_DOMAIN_ID, // origin
      callData // callData
    );

    // TODO: need InstadappAdapter interface but verify is internal
    // vm.expectCall(
    //   INSTADAPP_TARGET,
    //   abi.encodeWithSelector(InstadappAdapter.verify.selector, OP_AUTH, signature, destinationCastData, salt)
    // );
  }
}
