// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

interface ISwapper {
  /// @notice Swaps `amountIn` of _tokenIn for as much as possible of _tokenOut
  /// @param _amountIn The amount of the token to swap
  /// @param _tokenIn The address of the token0
  /// @param _tokenOut The amount of the token1
  /// @return amountOut The amount of the received token
  function swap(
    uint256 _amountIn,
    address _tokenIn,
    address _tokenOut,
    bytes calldata _swapData
  ) external returns (uint256 amountOut);

  /// @notice Swaps `amountIn` of ETH for as much as possible of _tokenOut
  /// @param _amountIn The amount of the token to swap
  /// @param _tokenOut The amount of the token1
  /// @return amountOut The amount of the received token
  function swapETH(
    uint256 _amountIn,
    address _tokenOut,
    bytes calldata _swapData
  ) external payable returns (uint256 amountOut);
}
