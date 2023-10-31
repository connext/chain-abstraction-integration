// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "../../utils/TestHelper.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {LockboxAdapter} from "../../../../contracts/integration/LockboxAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IXERC20Registry {
  function ERC20ToXERC20(address erc20) external view returns (address xerc20);
}

contract LockboxAdapterTest is TestHelper {
  LockboxAdapter adapter;

  // NEXT token uses Lockbox on Ethereum
  address erc20 = address(0xFE67A4450907459c3e1FFf623aA927dD4e28c67a);
  address xerc20 = address(0x58b9cB810A68a7f3e1E4f8Cb45D1B9B3c79705E8);
  address lockbox = address(0x22f424Bca11FE154c403c277b5F8dAb54a4bA29b);

  // TODO: temp mock address
  address registry = address(0x1);

  function utils_setUpOrigin() public {
    setUpEthereum(18465500); // TODO: update this after registry is deployed
    adapter = new LockboxAdapter(CONNEXT_ETHEREUM, registry);

    vm.label(address(erc20), "NEXT (ERC20)");
    vm.label(address(xerc20), "NEXT (xERC20)");
    vm.label(address(lockbox), "Lockbox");
    vm.label(address(adapter), "Adapter");
    vm.label(address(this), "AdapterTest");
  }

  function test_LockboxAdapter__xcall_revertsIfZeroAmount(address recipient) public {
    utils_setUpOrigin();
    vm.selectFork(ethereumForkId);
    assertEq(vm.activeFork(), ethereumForkId);

    uint32 _destination = ARBITRUM_DOMAIN_ID;
    address _to = USER_CHAIN_A;
    address _delegate = USER_CHAIN_A;
    uint256 _slippage = 10000;
    bytes memory _callData = "";
    uint256 _amount = 0;

    vm.expectRevert(abi.encodePacked("Amount must be greater than 0"));

    vm.startPrank(USER_CHAIN_A);
    adapter.xcall(_destination, _to, lockbox, _delegate, _amount, _slippage, _callData);
    vm.stopPrank();
  }

  function test_LockboxAdapter__xcall_worksWithNonNative(address recipient) public {
    utils_setUpOrigin();
    vm.selectFork(ethereumForkId);
    assertEq(vm.activeFork(), ethereumForkId);

    uint256 connextInitialAmount = IERC20(xerc20).balanceOf(CONNEXT_ETHEREUM);

    uint32 _destination = ARBITRUM_DOMAIN_ID;
    address _to = USER_CHAIN_A;
    address _delegate = USER_CHAIN_A;
    uint256 _slippage = 10000;
    bytes memory _callData = "";
    uint256 _amount = 1e18;
    uint256 _relayerFee = 1e17;

    deal(erc20, USER_CHAIN_A, _amount);
    assertEq(IERC20(erc20).balanceOf(USER_CHAIN_A), _amount);

    vm.deal(USER_CHAIN_A, _relayerFee);
    assertEq(USER_CHAIN_A.balance, _relayerFee);

    vm.mockCall(
      registry,
      abi.encodeWithSelector(IXERC20Registry.ERC20ToXERC20.selector, address(erc20)),
      abi.encode(xerc20)
    );

    vm.startPrank(USER_CHAIN_A);
    IERC20(erc20).approve(address(adapter), _amount);
    adapter.xcall{value: _relayerFee}(_destination, _to, lockbox, _delegate, _amount, _slippage, _callData);
    vm.stopPrank();

    assertEq(IERC20(erc20).balanceOf(USER_CHAIN_A), 0);
    assertEq(IERC20(xerc20).balanceOf(CONNEXT_ETHEREUM), connextInitialAmount + _amount);
  }
}
