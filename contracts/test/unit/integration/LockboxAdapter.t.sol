// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "../../utils/TestHelper.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {LockboxAdapter} from "../../../../contracts/integration/LockboxAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IXERC20Lockbox} from "../../../shared/IXERC20/IXERC20Lockbox.sol";
import {IConnext} from "@connext/interfaces/core/IConnext.sol";

interface IXERC20Registry {
  function getXERC20(address erc20) external view returns (address xerc20);

  function getLockbox(address erc20) external view returns (address xerc20);
}

contract LockboxAdapterTest is TestHelper {
  LockboxAdapter public adapter;
  address public registry = address(0xFa6c35C88e03338b13cffC9a5A143a2951B7f2fF);

  // NEXT token uses Lockbox on Ethereum
  address public erc20 = address(0xFE67A4450907459c3e1FFf623aA927dD4e28c67a);
  address public xerc20 = address(0x58b9cB810A68a7f3e1E4f8Cb45D1B9B3c79705E8);
  address public lockbox = address(0x22f424Bca11FE154c403c277b5F8dAb54a4bA29b);

  // Default params for xcall
  uint32 _destination = ARBITRUM_DOMAIN_ID;
  address _to = USER_CHAIN_A;
  address _delegate = USER_CHAIN_A;
  uint256 _slippage = 10000;
  bytes _callData = "";
  uint256 _amount = 1e18;
  uint256 _relayerFee = 1e17;

  function utils_setUpEthereum() public {
    setUpEthereum(18516267); // Registry added NEXT
    adapter = new LockboxAdapter(CONNEXT_ETHEREUM, registry);

    vm.label(address(erc20), "NEXT (ERC20)");
    vm.label(address(xerc20), "NEXT (xERC20)");
    vm.label(address(lockbox), "Lockbox");
    vm.label(address(adapter), "Adapter");
    vm.label(address(this), "AdapterTest");
  }

  function test_LockboxAdapter__xcall_revertsIfZeroAmount() public {
    utils_setUpEthereum();
    vm.selectFork(ethereumForkId);

    vm.expectRevert(abi.encodePacked("Amount must be greater than 0"));
    vm.startPrank(USER_CHAIN_A);
    adapter.xcall(_destination, _to, erc20, _delegate, 0, _slippage, _callData);
    vm.stopPrank();
  }

  function test_LockboxAdapter__xcall_revertsIfNativeAmountNotEnough() public {
    utils_setUpEthereum();
    vm.selectFork(ethereumForkId);
    vm.deal(USER_CHAIN_A, _amount);

    vm.mockCall(registry, abi.encodeWithSelector(IXERC20Registry.getXERC20.selector, erc20), abi.encode(xerc20));
    vm.mockCall(registry, abi.encodeWithSelector(IXERC20Registry.getLockbox.selector, erc20), abi.encode(lockbox));
    vm.mockCall(lockbox, abi.encodeWithSelector(IXERC20Lockbox.IS_NATIVE.selector), abi.encode(true));

    vm.expectRevert(abi.encodePacked("Value sent must be at least equal to the amount specified"));
    vm.startPrank(USER_CHAIN_A);
    adapter.xcall{value: _amount - 1}(_destination, _to, erc20, _delegate, _amount, _slippage, _callData);
    vm.stopPrank();
  }

  function test_LockboxAdapter__xcall_worksWithNative() public {
    utils_setUpEthereum();
    vm.selectFork(ethereumForkId);
    vm.deal(USER_CHAIN_A, _amount);

    uint256 connextInitialAmount = IERC20(xerc20).balanceOf(CONNEXT_ETHEREUM);

    vm.mockCall(registry, abi.encodeWithSelector(IXERC20Registry.getXERC20.selector, erc20), abi.encode(xerc20));
    vm.mockCall(registry, abi.encodeWithSelector(IXERC20Registry.getLockbox.selector, erc20), abi.encode(lockbox));
    vm.mockCall(lockbox, abi.encodeWithSelector(IXERC20Lockbox.IS_NATIVE.selector), abi.encode(true));

    // Switch out mocked calls with a native xERC20 eventually
    vm.mockCall(lockbox, abi.encodeWithSelector(IXERC20Lockbox.depositNative.selector), abi.encode(true));

    // Since we mocked the deposit call, we need to deal the amount to adapter
    deal(xerc20, address(adapter), _amount);

    vm.expectCall(xerc20, abi.encodeWithSelector(IERC20.approve.selector, CONNEXT_ETHEREUM, _amount));

    vm.startPrank(USER_CHAIN_A);
    adapter.xcall{value: _amount}(_destination, _to, erc20, _delegate, _amount, _slippage, _callData);
    vm.stopPrank();

    assertEq(IERC20(xerc20).balanceOf(CONNEXT_ETHEREUM), connextInitialAmount + _amount);
  }

  function test_LockboxAdapter__xcall_worksWithNonNative() public {
    utils_setUpEthereum();
    vm.selectFork(ethereumForkId);
    deal(erc20, USER_CHAIN_A, _amount);
    vm.deal(USER_CHAIN_A, _relayerFee);

    uint256 userInitialAmount = IERC20(erc20).balanceOf(USER_CHAIN_A);
    uint256 lockboxInitialAmount = IERC20(erc20).balanceOf(lockbox);
    uint256 connextInitialAmount = IERC20(xerc20).balanceOf(CONNEXT_ETHEREUM);

    vm.startPrank(USER_CHAIN_A);
    IERC20(erc20).approve(address(adapter), _amount);
    adapter.xcall{value: _relayerFee}(_destination, _to, erc20, _delegate, _amount, _slippage, _callData);
    vm.stopPrank();

    assertEq(IERC20(erc20).balanceOf(USER_CHAIN_A), userInitialAmount - _amount);
    assertEq(IERC20(erc20).balanceOf(lockbox), lockboxInitialAmount + _amount);
    assertEq(IERC20(xerc20).balanceOf(CONNEXT_ETHEREUM), connextInitialAmount + _amount);
  }

  function test_LockboxAdapter__xReceive_worksWithNonNative() public {
    utils_setUpEthereum();
    vm.selectFork(ethereumForkId);
    deal(xerc20, address(adapter), _amount);

    uint256 userInitialAmount = IERC20(erc20).balanceOf(USER_CHAIN_A);
    uint256 lockboxInitialAmount = IERC20(erc20).balanceOf(lockbox);
    uint256 adapterInitialAmount = IERC20(xerc20).balanceOf(address(adapter));

    vm.startPrank(CONNEXT_ETHEREUM);
    adapter.xReceive(bytes32(0), _amount, xerc20, USER_CHAIN_A, 1869640809, abi.encode(USER_CHAIN_A));
    vm.stopPrank();

    assertEq(IERC20(erc20).balanceOf(USER_CHAIN_A), userInitialAmount + _amount);
    assertEq(IERC20(erc20).balanceOf(lockbox), lockboxInitialAmount - _amount);
    assertEq(IERC20(xerc20).balanceOf(address(adapter)), adapterInitialAmount - _amount);
  }
}
