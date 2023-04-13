// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ISwapper} from "../interfaces/ISwapper.sol";

/**
 * @title UniV2Swapper
 * @notice Swapper contract for UniswapV2 swaps.
 */
contract UniV2Swapper is ISwapper {
  using Address for address;

  IUniswapV2Router02 public immutable uniswapV2Router;

  constructor(address _uniV2Router) {
    uniswapV2Router = IUniswapV2Router02(_uniV2Router);
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

    uint256 amountOutMin = abi.decode(_swapData, (uint256));

    // Set up swap params
    // Approve the swapper if needed
    if (IERC20(_fromAsset).allowance(address(this), address(uniswapV2Router)) < _amountIn) {
      TransferHelper.safeApprove(_fromAsset, address(uniswapV2Router), type(uint256).max);
    }

    if (_fromAsset != _toAsset) {
      address[] memory path = new address[](2);
      path[0] = _fromAsset;
      path[1] = _toAsset;
      TransferHelper.safeApprove(_fromAsset, address(uniswapV2Router), _amountIn);
      uniswapV2Router.swapExactTokensForTokens(_amountIn, amountOutMin, path, address(this), block.timestamp);
    }

    amountOut = IERC20(_toAsset).balanceOf(address(this));

    // transfer the swapped funds back to the sender
    TransferHelper.safeTransfer(_toAsset, msg.sender, amountOut);
  }
}
