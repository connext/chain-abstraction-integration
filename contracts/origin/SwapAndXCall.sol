// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IConnext} from "connext-interfaces/core/IConnext.sol";
import {SwapAdapter} from "../shared/Swap/SwapAdapter.sol";

abstract contract SwapAndXCall is SwapAdapter {
  IConnext connext;

  constructor(address _connext) SwapAdapter() {
    connext = IConnext(_connext);
  }

  function swapAndXCall(
    address _swapper,
    address _toAsset,
    bytes calldata _swapData,
    uint32 _destination,
    address _to,
    address _delegate,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable {
    uint256 amountOut = this.directSwapperCall(_swapper, _swapData);

    // TODO: msg.value can contain swap value as well in the case that user swaps native asset, maybe need a separate var to handle this
    connext.xcall{value: msg.value}(_destination, _to, _toAsset, _delegate, amountOut, _slippage, _callData);
  }

  function swapAndXCall(
    address _swapper,
    address _toAsset,
    bytes calldata _swapData,
    uint32 _destination,
    address _to,
    address _delegate,
    uint256 _slippage,
    bytes calldata _callData,
    uint256 _relayerFee
  ) external payable {
    uint256 amountOut = this.directSwapperCall(_swapper, _swapData);
    connext.xcall(_destination, _to, _toAsset, _delegate, amountOut, _slippage, _callData, _relayerFee);
  }
}
