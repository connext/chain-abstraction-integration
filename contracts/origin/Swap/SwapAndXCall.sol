// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IConnext} from "connext-interfaces/core/IConnext.sol";
import {SwapAdapter} from "../../shared/Swap/SwapAdapter.sol";

contract SwapAndXCall is SwapAdapter {
  IConnext connext;

  constructor(address _connext) SwapAdapter() {
    connext = IConnext(_connext);
  }

  function swapAndXCall(
    address _fromAsset,
    address _toAsset,
    uint256 _amountIn,
    address _swapper,
    bytes calldata _swapData,
    uint32 _destination,
    address _to,
    address _delegate,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable {
    uint256 amountOut = _setupAndSwap(_fromAsset, _toAsset, _amountIn, _swapper, _swapData);

    connext.xcall{value: msg.value - _amountIn}(
      _destination,
      _to,
      _toAsset,
      _delegate,
      amountOut,
      _slippage,
      _callData
    );
  }

  function swapAndXCall(
    address _fromAsset,
    address _toAsset,
    uint256 _amountIn,
    address _swapper,
    bytes calldata _swapData,
    uint32 _destination,
    address _to,
    address _delegate,
    uint256 _slippage,
    bytes calldata _callData,
    uint256 _relayerFee
  ) external payable {
    uint256 amountOut = _setupAndSwap(_fromAsset, _toAsset, _amountIn, _swapper, _swapData);

    connext.xcall(_destination, _to, _toAsset, _delegate, amountOut, _slippage, _callData, _relayerFee);
  }

  function _setupAndSwap(
    address _fromAsset,
    address _toAsset,
    uint256 _amountIn,
    address _swapper,
    bytes calldata _swapData
  ) internal returns (uint256 amountOut) {
    if (_fromAsset != address(0)) {
      TransferHelper.safeTransferFrom(_fromAsset, msg.sender, address(this), _amountIn);
    } else {
      require(msg.value >= _amountIn, "SwapAndXCall: msg.value != _amountIn");
    }

    if (IERC20(_fromAsset).allowance(address(this), _swapper) < _amountIn) {
      IERC20(_fromAsset).approve(_swapper, type(uint256).max);
    }
    amountOut = this.directSwapperCall{value: _fromAsset == address(0) ? _amountIn : 0}(_swapper, _swapData);

    if (IERC20(_toAsset).allowance(address(this), address(connext)) < _amountIn) {
      IERC20(_toAsset).approve(address(connext), type(uint256).max);
    }
  }
}
