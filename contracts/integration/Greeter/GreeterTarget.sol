// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {GreeterAdapter} from "./GreeterAdapter.sol";
import {SwapForwarderXReceiver} from "../../destination/xreceivers/Swap/SwapForwarderXReceiver.sol";

contract GreeterTarget is GreeterAdapter, SwapForwarderXReceiver {
  constructor(address _connext) SwapForwarderXReceiver(_connext) {}

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
    (address _token, string memory _greeting) = abi.decode(_forwardCallData, (address, string));

    greetWithTokens(_token, _amountOut, _greeting);
    return true;
  }
}
