// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "../../utils/TestHelper.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {LockboxAdapter} from "../../../../contracts/integration/LockboxAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IXERC20Lockbox} from "../../../shared/IXERC20/IXERC20Lockbox.sol";
import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {XERC20Lockbox} from "@defi-wonderland/xerc20/solidity/contracts/XERC20Lockbox.sol";
import {XERC20} from "@defi-wonderland/xerc20/solidity/contracts/XERC20.sol";
import {IXERC20} from "@defi-wonderland/xerc20/solidity/interfaces/IXERC20.sol";

interface IXERC20Registry {
  // ========== Events ===========
  event XERC20Registered(address indexed XERC20, address indexed ERC20);

  event XERC20Deregistered(address indexed XERC20, address indexed ERC20);

  // ========== Custom Errors ===========
  error AlreadyRegistered(address XERC20);

  error XERC20NotRegistered(address XERC20);

  error InvalidXERC20Address(address XERC20);

  // ========== Function Signatures ===========
  function initialize() external;

  function registerXERC20(address _XERC20, address _ERC20) external;

  function deregisterXERC20(address _xERC20) external;

  function getERC20(address _XERC20) external view returns (address);

  function getXERC20(address _ERC20) external view returns (address);

  function getLockbox(address _XERC20) external view returns (address);

  function isXERC20(address _XERC20) external view returns (bool);
}

contract LockboxAdapterTest is TestHelper {
  LockboxAdapter public adapter;
  address public registry = address(0xBbA4b5130Fb918A6E2Dbc94b430397D3d2EA1e2F);
  address public registrar = address(0xade09131C6f43fe22C2CbABb759636C43cFc181e);

  // NEXT token details (registered)
  address public erc20 = address(0xFE67A4450907459c3e1FFf623aA927dD4e28c67a);
  address public xerc20 = address(0x58b9cB810A68a7f3e1E4f8Cb45D1B9B3c79705E8);
  address public lockbox = address(0x22f424Bca11FE154c403c277b5F8dAb54a4bA29b);

  // ALCX token details (non-registered)
  address public alcxERC20 = address(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
  address public alcxXERC20 = address(0xbD18F9be5675A9658335e6B7E79D9D9B394aC043);

  // Native token details (non-registered)
  address public xerc20ForNative;
  address public nativeLockbox;

  // Default params for xcall
  uint32 _destination = ARBITRUM_DOMAIN_ID;
  address _to = USER_CHAIN_A;
  address _delegate = USER_CHAIN_A;
  uint256 _slippage = 10000;
  bytes _callData = "";
  uint256 _amount = 1e18;
  uint256 _relayerFee = 1e17;

  function utils_setUpEthereum() public {
    setUpEthereum(18530675); // Registry added only NEXT
    adapter = new LockboxAdapter(CONNEXT_ETHEREUM, registry);

    vm.label(address(erc20), "NEXT (ERC20)");
    vm.label(address(xerc20), "NEXT (xERC20)");
    vm.label(address(lockbox), "Lockbox");
    vm.label(address(adapter), "Adapter");
    vm.label(address(registry), "Registry");
    vm.label(address(this), "AdapterTest");
  }

  function utils_registerNative() public {
    address factory = address(0x100);
    xerc20ForNative = address(new XERC20("testTKN", "TTKN", factory));
    nativeLockbox = address(new XERC20Lockbox(address(xerc20ForNative), address(0), true));

    vm.prank(factory);
    IXERC20(xerc20ForNative).setLockbox(nativeLockbox);
    vm.prank(registrar);
    IXERC20Registry(registry).registerXERC20(address(xerc20ForNative), address(0));

    vm.label(xerc20ForNative, "Native xERC20");
    vm.label(nativeLockbox, "Native Lockbox");
  }

  function test_LockboxAdapter__xcall_revertsIfZeroAmount() public {
    utils_setUpEthereum();
    vm.selectFork(ethereumForkId);
    bytes4 AmountLessThanZeroSelector = bytes4(keccak256("AmountLessThanZero()"));
    vm.expectRevert(abi.encodePacked(AmountLessThanZeroSelector));
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

    bytes4 ValueLessThanAmountSelector = bytes4(keccak256("ValueLessThanAmount(uint256,uint256)"));
    vm.expectRevert(abi.encodePacked(ValueLessThanAmountSelector, abi.encode(_amount - 1, _amount)));
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

  function test_LockboxAdapter__xReceive_worksWithNative() public {
    utils_setUpEthereum();
    vm.selectFork(ethereumForkId);
    utils_registerNative();
    deal(xerc20ForNative, address(adapter), _amount);
    vm.deal(nativeLockbox, _amount);

    uint256 userInitialAmount = address(USER_CHAIN_A).balance;
    uint256 lockboxInitialBalance = address(nativeLockbox).balance;

    vm.startPrank(CONNEXT_ETHEREUM);
    adapter.xReceive(bytes32(0), _amount, xerc20ForNative, USER_CHAIN_A, ARBITRUM_DOMAIN_ID, abi.encode(USER_CHAIN_A));
    vm.stopPrank();

    assertEq(address(USER_CHAIN_A).balance, userInitialAmount + _amount);
    assertEq(address(adapter).balance, 0);
    assertEq(address(lockbox).balance, lockboxInitialBalance - _amount);
  }

  function test_LockboxAdapter__xReceive_revertsIfNotConnext() public {
    utils_setUpEthereum();
    vm.selectFork(ethereumForkId);
    bytes4 NotConnextSelector = bytes4(keccak256("NotConnext(address)"));
    vm.expectRevert(abi.encodePacked(NotConnextSelector, abi.encode(address(this))));
    adapter.xReceive(bytes32(0), _amount, xerc20, USER_CHAIN_A, 1869640809, abi.encode(USER_CHAIN_A));
  }

  function test_LockboxAdapter__xReceive__FallbackWorks() public {
    utils_setUpEthereum();
    vm.selectFork(ethereumForkId);

    // Use ALCX, which is not registered
    deal(alcxXERC20, address(adapter), _amount);

    uint256 userInitialAmount = IERC20(alcxXERC20).balanceOf(USER_CHAIN_A);
    uint256 adapterInitialAmount = IERC20(alcxXERC20).balanceOf(address(adapter));

    vm.startPrank(CONNEXT_ETHEREUM);
    adapter.xReceive(bytes32(0), _amount, alcxXERC20, USER_CHAIN_A, 1869640809, abi.encode(USER_CHAIN_A));
    vm.stopPrank();

    assertEq(IERC20(alcxXERC20).balanceOf(USER_CHAIN_A), userInitialAmount + _amount);
    assertEq(IERC20(alcxXERC20).balanceOf(address(adapter)), adapterInitialAmount - _amount);
  }
}
