// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {GelatoOneBalanceAdapter} from "./GelatoOnebalanceAdapter.sol";
import {SwapForwarderXReceiver} from "../../destination/xreceivers/Swap/SwapForwarderXReceiver.sol";

contract GelatoOneBalanceTarget is GelatoOneBalanceAdapter, SwapForwarderXReceiver {
    constructor (address _connext, address _gelato1balance) SwapForwarderXReceiver(_connext) GelatoOneBalanceAdapter(_gelato1balance) {}

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
    (address _sponsor, address _asset) = abi.decode(
        _forwardCallData, 
        (address, address)
    );

    depositTokens(_sponsor, _asset, _amountOut);
    return true;
  } 
}