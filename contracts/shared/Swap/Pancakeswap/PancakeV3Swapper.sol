// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {IPancakeSmartRouter, IV3SwapRouter} from "../interfaces/IPancakeSmartRouter.sol";
import {ISwapper} from "../interfaces/ISwapper.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";

/**
 * @title PancakeV3Swapper
 * @notice Swapper contract for PancakeV3 swaps.
 */
contract PancakeV3Swapper is ISwapper {
  IPancakeSmartRouter public immutable uniswapV3Router;

  constructor(address _uniV3Router) {
    uniswapV3Router = IPancakeSmartRouter(_uniV3Router);
  }

  /**
   * @notice Swap the given amount of tokens using PancakeSwapV3.
   * @dev Decode the passed in data and re-encode it with the correct amountIn. This is because the amountIn is not known
   * until the funds are transferred to this contract.
   * @param _amountIn Amount of tokens to swap.
   * @param _fromAsset Address of the token to swap from.
   * @param _toAsset Address of the token to swap to.
   * @param _swapData Data to pass to the PancakeV3 router.
   */
  function swap(
    uint256 _amountIn,
    address _fromAsset,
    address _toAsset,
    bytes calldata _swapData
  ) external override returns (uint256 amountOut) {
    // transfer the funds to be swapped from the sender into this contract
    TransferHelper.safeTransferFrom(_fromAsset, msg.sender, address(this), _amountIn);

    (uint24 poolFee, uint256 amountOutMin) = abi.decode(_swapData, (uint24, uint256));

    if (_fromAsset != _toAsset) {
      TransferHelper.safeApprove(_fromAsset, address(uniswapV3Router), _amountIn);

      bool toNative = _toAsset == address(0);
      IWETH9 weth9 = IWETH9(uniswapV3Router.WETH9());

      // Set up uniswap swap params.
      IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
        tokenIn: _fromAsset,
        tokenOut: toNative ? address(weth9) : _toAsset,
        fee: poolFee,
        recipient: address(this),
        amountIn: _amountIn,
        amountOutMinimum: amountOutMin,
        sqrtPriceLimitX96: 0
      });

      // The call to `exactInputSingle` executes the swap.
      amountOut = uniswapV3Router.exactInputSingle(params);

      if (toNative) {
        weth9.withdraw(amountOut);
        TransferHelper.safeTransferETH(msg.sender, amountOut);
      } else {
        TransferHelper.safeTransfer(_toAsset, msg.sender, amountOut);
      }
    } else {
      amountOut = _amountIn;
      TransferHelper.safeTransfer(_toAsset, msg.sender, amountOut);
    }
  }

  /**
   * @notice Swap the given amount of ETH using PancakeSwapV3.
   * @dev Decode the passed in data and re-encode it with the correct amountIn. This is because the amountIn is not known
   * until the funds are transferred to this contract.
   * @param _amountIn Amount of tokens to swap.
   * @param _toAsset Address of the token to swap to.
   * @param _swapData Data to pass to the PancakeV3 router.
   */
  function swapETH(
    uint256 _amountIn,
    address _toAsset,
    bytes calldata _swapData
  ) external payable override returns (uint256 amountOut) {
    // check if msg.value is same as amountIn
    require(msg.value >= _amountIn, "PancakeV3Swapper: msg.value != _amountIn");

    (uint24 poolFee, uint256 amountOutMin) = abi.decode(_swapData, (uint24, uint256));

    IWETH9 weth9 = IWETH9(uniswapV3Router.WETH9());
    if (_toAsset != address(0)) {
      weth9.deposit{value: _amountIn}();

      // Set up uniswap swap params.
      IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
        tokenIn: address(weth9),
        tokenOut: _toAsset,
        fee: poolFee,
        recipient: msg.sender,
        amountIn: _amountIn,
        amountOutMinimum: amountOutMin,
        sqrtPriceLimitX96: 0
      });

      // The call to `exactInputSingle` executes the swap.
      amountOut = uniswapV3Router.exactInputSingle(params);
    } else {
      amountOut = _amountIn;
      TransferHelper.safeTransferETH(msg.sender, amountOut);
    }
  }
}
