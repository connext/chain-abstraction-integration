// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDCAHubPositionHandler, IDCAPermissionManager} from "@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol";

import {TestHelper} from "../../../../utils/TestHelper.sol";
import {OneInchUniswapV3, IUniswapV3Router} from "../../../../../shared/Swap/OneInch/OneInchUniswapV3.sol";

// data from 1inch API: 0xe449022e000000000000000000000000000000000000000000000000002386f26fc10000000000000000000000000000000000000000000000000000000000000120fd1200000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001c00000000000000000000000e0554a476a092703abdb3ef35c80e0d76d32939fcfee7c08

contract OneInchUniswapV3Test is TestHelper {
  OneInchUniswapV3 public swapper;

  function setUp() public override {
    super.setUp();
    swapper = new OneInchUniswapV3(address(1));

    vm.label(address(this), "TestContract");
  }

  function test_OneInchUniswapV3Test__works() public {
    uint256 _amountIn = 1;
    address _tokenIn = address(2);
    address _toAsset = address(3);

    bytes
      memory _swapData = hex"e449022e000000000000000000000000000000000000000000000000002386f26fc10000000000000000000000000000000000000000000000000000000000000120fd1200000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001c00000000000000000000000e0554a476a092703abdb3ef35c80e0d76d32939fcfee7c08";

    vm.mockCall(_tokenIn, abi.encodeWithSelector(IERC20.transferFrom.selector), abi.encode(true));
    vm.mockCall(_tokenIn, abi.encodeWithSelector(IERC20.allowance.selector), abi.encode(0));
    vm.mockCall(_tokenIn, abi.encodeWithSelector(IERC20.approve.selector), abi.encode(true));
    vm.mockCall(address(1), abi.encodeWithSelector(IUniswapV3Router.uniswapV3Swap.selector), abi.encode(10));
    vm.mockCall(_toAsset, abi.encodeWithSelector(IERC20.transfer.selector), abi.encode(true));
    uint256 amountOut = swapper.swap(_amountIn, _tokenIn, _toAsset, _swapData);
    assertEq(amountOut, 10);
  }
}
