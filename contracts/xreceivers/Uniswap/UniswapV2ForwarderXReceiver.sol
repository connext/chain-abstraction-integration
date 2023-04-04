// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {ForwarderXReceiver} from "../ForwarderXReceiver.sol";

abstract contract UniswapV2ForwarderXReceiver is ForwarderXReceiver {
  IUniswapV2Router02 public immutable uniswapSwapRouter;

  constructor(address _connext, address _uniswapSwapRouter) ForwarderXReceiver(_connext) {
    uniswapSwapRouter = IUniswapV2Router02(_uniswapSwapRouter);
  }

  /// INTERNAL
  function _prepare(
    bytes32 /*_transferId*/,
    bytes memory _data,
    uint256 _amount,
    address _asset
  ) internal override returns (bytes memory) {
    (address toAsset, uint256 amountOutMin, bytes memory forwardCallData) = abi.decode(
      _data,
      (address, uint256, bytes)
    );

    uint[] memory amounts = new uint[](1);
    amounts[0] = _amount;
    address[] memory path = new address[](2);
    path[0] = _asset;
    path[1] = toAsset;
    if (_asset != toAsset) {
      TransferHelper.safeApprove(_asset, address(uniswapSwapRouter), _amount);
      amounts = uniswapSwapRouter.swapExactTokensForTokens(_amount, amountOutMin, path, address(this), block.timestamp);
    }

    return abi.encode(amounts, toAsset, path, amountOutMin, forwardCallData);
  }
}
