// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract UniswapV3 {
    function uniswapV3ExactInputSingle(
        address swapper,
        bytes calldata _data,
        uint256 value
    ) public returns (uint256 amountOut) {
        (
            address fromAsset,
            address toAsset,
            uint24 poolFee,
            uint256 amountIn,
            uint256 amountOutMin,
            address recipient
        ) = abi.decode(
                _data,
                (address, address, uint24, uint256, uint256, address)
            );

        TransferHelper.safeApprove(fromAsset, address(swapper), amountIn);
        // Set up uniswap swap params.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: fromAsset,
                tokenOut: toAsset,
                fee: poolFee,
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = ISwapRouter(swapper).exactInputSingle{value: value}(params);
    }
}
