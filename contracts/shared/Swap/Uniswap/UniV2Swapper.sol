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
   * @notice Swap the given amount of tokens using UniV2.
   * @dev Decode the passed in data and re-encode it with the correct amountIn. This is because the amountIn is not known
   * until the funds are transferred to this contract.
   * @param _amountIn Amount of tokens to swap.
   * @param _fromAsset Address of the token to swap from.
   * @param _toAsset Address of the token to swap to.
   * @param _swapData Data to pass to the UniV2 router.
   */
  function swap(
    uint256 _amountIn,
    address _fromAsset,
    address _toAsset,
    bytes calldata _swapData
  ) external override returns (uint256 amountOut) {
    // transfer the funds to be swapped from the sender into this contract
    TransferHelper.safeTransferFrom(_fromAsset, msg.sender, address(this), _amountIn);

    uint256 amountOutMin = abi.decode(_swapData, (uint256));

    if (_fromAsset != _toAsset) {
      address[] memory path = new address[](2);
      path[0] = _fromAsset;
      path[1] = _toAsset;
      TransferHelper.safeApprove(_fromAsset, address(uniswapV2Router), _amountIn);

      uint[] memory amounts;
      if (_toAsset != address(0)) {
        amounts = uniswapV2Router.swapExactTokensForTokens(_amountIn, amountOutMin, path, msg.sender, block.timestamp);
      } else {
        path[1] = uniswapV2Router.WETH();
        amounts = uniswapV2Router.swapExactTokensForETH(_amountIn, amountOutMin, path, msg.sender, block.timestamp);
      }
      amountOut = amounts[amounts.length - 1];
    }
  }

  /**
   * @notice Swap the given amount of ETH using UniV2.
   * @dev Decode the passed in data and re-encode it with the correct amountIn. This is because the amountIn is not known
   * until the funds are transferred to this contract.
   * @param _amountIn Amount of tokens to swap.
   * @param _toAsset Address of the token to swap to.
   * @param _swapData Data to pass to the UniV2 router.
   */
  function swapETH(
    uint256 _amountIn,
    address _toAsset,
    bytes calldata _swapData
  ) public payable override returns (uint256 amountOut) {
    // check if msg.value is same as amountIn
    require(msg.value >= _amountIn, "UniV2Swapper: msg.value != _amountIn");

    uint256 amountOutMin = abi.decode(_swapData, (uint256));

    if (_toAsset != address(0)) {
      address[] memory path = new address[](2);
      path[0] = uniswapV2Router.WETH();
      path[1] = _toAsset;
      uint[] memory amounts = uniswapV2Router.swapExactETHForTokens{value: _amountIn}(
        amountOutMin,
        path,
        msg.sender,
        block.timestamp
      );
      amountOut = amounts[amounts.length - 1];
    } else {
      amountOut = _amountIn;
      TransferHelper.safeTransferETH(msg.sender, amountOut);
    }
  }
}
