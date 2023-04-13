// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ISwapper} from "../interfaces/ISwapper.sol";

/**
 * @title UniV3Swapper
 * @notice Swapper contract for UniswapV3 swaps.
 */
contract UniV3Swapper is ISwapper {
  using Address for address;

  ISwapRouter public immutable uniswapV3Router;

  constructor(address _uniV3Router) {
    uniswapV3Router = ISwapRouter(_uniV3Router);
  }

  /**
   * @notice Swap the given amount of tokens using 1inch.
   * @dev Decode the passed in data and re-encode it with the correct amountIn. This is because the amountIn is not known
   * until the funds are transferred to this contract.
   * @param _amountIn Amount of tokens to swap.
   * @param _fromAsset Address of the token to swap from.
   * @param _toAsset Address of the token to swap to.
   * @param _swapData Data to pass to the 1inch aggregator router.
   */
  function swap(
    uint256 _amountIn,
    address _fromAsset,
    address _toAsset,
    bytes calldata _swapData
  ) public payable override returns (uint256 amountOut) {
    // transfer the funds to be swapped from the sender into this contract
    TransferHelper.safeTransferFrom(_fromAsset, msg.sender, address(this), _amountIn);

    (uint24 poolFee, uint256 amountOutMin) = abi.decode(_swapData, (uint24, uint256));

    if (_fromAsset != _toAsset) {
      TransferHelper.safeApprove(_fromAsset, address(uniswapV3Router), _amountIn);
      // Set up uniswap swap params.
      ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: _fromAsset,
        tokenOut: _toAsset,
        fee: poolFee,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: _amountIn,
        amountOutMinimum: amountOutMin,
        sqrtPriceLimitX96: 0
      });

      // The call to `exactInputSingle` executes the swap.
      amountOut = ISwapRouter(uniswapV3Router).exactInputSingle(params);
    }

    // transfer the swapped funds back to the sender
    TransferHelper.safeTransfer(_toAsset, msg.sender, amountOut);
  }
}
