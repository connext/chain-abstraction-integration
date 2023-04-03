// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { TransferHelper } from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {ForwarderXReceiver} from "./ForwarderXReceiver.sol";

abstract contract UniswapV3ForwarderXReceiver is ForwarderXReceiver {
  ISwapRouter public immutable uniswapSwapRouter;

  constructor(address _connext, address _uniswapSwapRouter) ForwarderXReceiver(_connext) {
    uniswapSwapRouter = ISwapRouter(_uniswapSwapRouter);
  }

  /// INTERNAL
  function _forwardFunctionCall(
    bytes32 /*_transferId*/,
    bytes memory _data,
    uint256 _amount,
    address _asset
  ) internal virtual returns (bool) {
    (
      address toAsset,
      uint24 poolFee,
      uint256 amountOutMin,
      address recipient,
      uint256 value
    ) = abi.decode(_data, (address, uint24, uint256, address, uint256));

    uint256 amountOut = _amount;
    if (_asset != toAsset) {
      TransferHelper.safeApprove(_asset, address(uniswapSwapRouter), _amount);
      // Set up uniswap swap params.
      ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams({
          tokenIn: _asset,
          tokenOut: toAsset,
          fee: poolFee,
          recipient: recipient,
          deadline: block.timestamp,
          amountIn: _amount,
          amountOutMinimum: amountOutMin,
          sqrtPriceLimitX96: 0
        });

      // The call to `exactInputSingle` executes the swap.
      amountOut = ISwapRouter(uniswapSwapRouter).exactInputSingle{ value: value }(params);
    }

    // Overrider implements additional forwarding logic.
  }
}
