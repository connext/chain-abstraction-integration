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
    (bytes memory _forwardCallData, uint256 _amountOut, , ) = abi.decode(
      _preparedData,
      (bytes, uint256, address, address)
    );
    (address _cTokenAddress, address _asset, address _minter) = abi.decode(
      _forwardCallData,
      (address, address, address)
    );

    _mint(_cTokenAddress, _asset, _amountOut, _minter);

    return true;
  }
}
