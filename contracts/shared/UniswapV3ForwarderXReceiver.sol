// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IConnext } from "@connext/interfaces/core/IConnext.sol";
import { IXReceiver } from "@connext/interfaces/core/IXReceiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { TransferHelper } from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

abstract contract ForwarderXReceiver {
  // The Connext contract on this domain
  IConnext public immutable connext;
  ISwapRouter public immutable uniswapSwapRouter;

  /// Modifier
  modifier onlyConnext() {
    require(msg.sender == address(connext), "Caller must be Connext");
    _;
  }

  constructor(address _connext, address _uniswapSwapRouter) {
    connext = IConnext(_connext);
    uniswapSwapRouter = ISwapRouter(_uniswapSwapRouter);
  }

  function xReceive(
    bytes32 _transferId,
    uint256 _amount, // Final Amount receive via Connext(After AMM calculation)
    address _asset,
    address /*_originSender*/,
    uint32 /*_origin*/,
    bytes calldata _callData
  ) external payable onlyConnext {
    // Decode calldata
    (address fallbackAddress, bytes memory data) = abi.decode(
      _callData,
      (address, bytes)
    );

    require(fallbackAddress != address(0), "!invalidFallback");

    // transfer to fallback address if _forwardFunctionCall fails
    if (!_swapAndForward(_transferId, data, _amount, _asset)) {
      IERC20(_asset).transfer(fallbackAddress, _amount);
    }
  }

  /// INTERNAL
  function _swapAndForward(
    bytes32 _transferId,
    bytes memory _data,
    uint256 _amount,
    address _asset
  ) internal returns (bool) {
    (
      address toAsset,
      uint24 poolFee,
      uint256 amountOutMin,
      address recipient,
      uint256 value
    ) = abi.decode(_data, (address, uint24, uint256, address, uint256));

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
      ISwapRouter(uniswapSwapRouter).exactInputSingle{ value: value }(params);
    }

    // Call the function
    return _forwardFunctionCall(_transferId, _data, _amount, _asset);
  }

  function _forwardFunctionCall(
    bytes32 _transferId,
    bytes memory _data,
    uint256 _amount,
    address _asset
  ) internal virtual returns (bool) {}
}
