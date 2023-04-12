// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MidasProtocolAdapter} from "./MidasProtocolAdapter.sol";
import {SwapForwarderXReceiver} from "../../destination/xreceivers/Swap/SwapForwarderXReceiver.sol";

contract MidasProtocolTarget is MidasProtocolAdapter, SwapForwarderXReceiver {
  constructor(
    address _connext,
    address _comptroller
  ) SwapForwarderXReceiver(_connext) MidasProtocolAdapter(_comptroller) {}

  function _forwardFunctionCall(
    bytes memory _preparedData,
    bytes32 /*_transferId*/,
    uint256 /*_amount*/,
    address /*_asset*/
  ) internal override returns (bool) {
    (uint256 _amountOut, bytes memory _forwardCallData) = abi.decode(_preparedData, (uint256, bytes));
    (address _cTokenAddress, address _asset, address _minter) = abi.decode(
      _forwardCallData,
      (address, address, address)
    );

    _mint(_cTokenAddress, _asset, _amountOut, _minter);

    return true;
  }
}
