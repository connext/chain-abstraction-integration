// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ForwarderXReceiver} from "../ForwarderXReceiver.sol";
import {SwapAdapter} from "./SwapAdapter.sol";

abstract contract SwapForwarderXReceiver is ForwarderXReceiver, SwapAdapter {
  using Address for address;

  constructor(address _connext) ForwarderXReceiver(_connext) {}

  /// INTERNAL
  function _prepare(
    bytes32 /*_transferId*/,
    bytes memory _data,
    uint256 _amount,
    address _asset
  ) internal override returns (bytes memory) {
    (address _swapper, bytes memory _swapData, bytes memory _forwardCallData) = abi.decode(
      _data,
      (address, bytes, bytes)
    );

    uint256 _amountOut = this.exactSwap(_swapper, _amount, _asset, _swapData);

    return abi.encode(_amountOut, _forwardCallData);
  }
}
