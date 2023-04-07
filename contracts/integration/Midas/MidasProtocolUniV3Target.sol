// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MidasProtocolAdapter} from "./MidasProtocolAdapter.sol";
import {UniswapV3ForwarderXReceiver} from "../../destination/xreceivers/Uniswap/UniswapV3ForwarderXReceiver.sol";

contract MidasProtocolUniV3Target is MidasProtocolAdapter, UniswapV3ForwarderXReceiver {
  constructor(
    address _connext,
    address _uniswapSwapRouter,
    address _comptroller
  ) UniswapV3ForwarderXReceiver(_connext, _uniswapSwapRouter) MidasProtocolAdapter(_comptroller) {}

  function _forwardFunctionCall(
    bytes memory _preparedData,
    bytes32,
    uint256,
    address
  ) internal override returns (bool) {
    // Decode calldata
    (uint256 amountOut, address toAsset, , , bytes memory forwardCallData) = abi.decode(
      _preparedData,
      (uint256, address, uint24, uint256, bytes)
    );

    (address cTokenAddress, address minter) = abi.decode(forwardCallData, (address, address));

    _mint(cTokenAddress, toAsset, amountOut, minter);
  }
}
