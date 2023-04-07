// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDCAHubPositionHandler, IDCAPermissionManager} from "@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol";

import {TestHelper} from "../../../../utils/TestHelper.sol";
import {OneInchUniswapV3, IUniswapV3Router} from "../../../../../contracts/shared/Swap/OneInch/OneInchUniswapV3.sol";

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
    bytes
      memory _swapData = hex"e449022e000000000000000000000000000000000000000000000000002386f26fc10000000000000000000000000000000000000000000000000000000000000120fd1200000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001c00000000000000000000000e0554a476a092703abdb3ef35c80e0d76d32939fcfee7c08";

    // remove 4 byte selector, not possible with memory bytes to use array indexing???
    bytes
      memory _s = hex"000000000000000000000000000000000000000000000000002386f26fc10000000000000000000000000000000000000000000000000000000000000120fd1200000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001c00000000000000000000000e0554a476a092703abdb3ef35c80e0d76d32939fcfee7c08";
    (, uint256 _minReturn, uint256[] memory _pools) = abi.decode(_s, (uint256, uint256, uint256[]));
    vm.mockCall(_tokenIn, abi.encodeWithSelector(IERC20.approve.selector), abi.encode(true));
    vm.mockCall(address(1), abi.encodeWithSelector(IUniswapV3Router.uniswapV3Swap.selector), abi.encode(10));

    vm.expectCall(address(1), abi.encodeCall(IUniswapV3Router.uniswapV3Swap, (_amountIn, _minReturn, _pools)));

    uint256 amountOut = swapper.swap(_amountIn, _tokenIn, address(3), _swapData);
    assertEq(amountOut, 10);
  }
}
