// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ISwapper} from "../interfaces/ISwapper.sol";

interface IUniswapV3Router {
  function uniswapV3Swap(
    uint256 amount,
    uint256 minReturn,
    uint256[] calldata pools
  ) external payable returns (uint256 returnAmount);
}

contract OneInchUniswapV3 is ISwapper {
  using Address for address;

  function swap(
    address _swapper,
    uint256 _amountIn,
    address _tokenIn,
    bytes calldata _swapData // from 1inch API
  ) public payable returns (uint256 amountOut) {
    // transfer the funds into this contract
    TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);

    // decode the swap data
    // the data included with the swap encodes with the selector so we need to remove it
    // https://docs.1inch.io/docs/aggregation-protocol/smart-contract/UnoswapV3Router#uniswapv3swap
    (, uint256 _minReturn, uint256[] memory _pools) = abi.decode(_swapData[4:], (uint256, uint256, uint256[]));

    // Set up swap params
    // Approve the swapper if needed
    if (IERC20(_tokenIn).allowance(address(this), _swapper) < _amountIn) {
      TransferHelper.safeApprove(_tokenIn, _swapper, type(uint256).max);
    }

    // The call to `uniswapV3Swap` executes the swap.
    // use actual amountIn that was sent to the xReceiver
    amountOut = IUniswapV3Router(_swapper).uniswapV3Swap(_amountIn, _minReturn, _pools);
  }
}
