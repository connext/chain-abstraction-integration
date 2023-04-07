// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {SwapForwarderXReceiver} from "../../destination/xreceivers/Swap/SwapForwarderXReceiver.sol";

interface IGreeter {
  function greetWithTokens(address _token, uint256 _amount, string calldata _greeting) external;
}

contract XSwapAndGreetTarget is SwapForwarderXReceiver {
  IGreeter public immutable greeter;

  constructor(address _greeter, address _connext) SwapForwarderXReceiver(_connext) {
    greeter = IGreeter(_greeter);
  }

  /// INTERNAL
  function _forwardFunctionCall(
    bytes memory _preparedData,
    bytes32 /*_transferId*/,
    uint256 /*_amount*/,
    address /*_asset*/
  ) internal override returns (bool) {
    (bytes memory _forwardCallData, uint256 _amountOut, , address _toAsset) = abi.decode(
      _preparedData,
      (bytes, uint256, address, address)
    );

    // Decode calldata
    string memory greeting = abi.decode(_forwardCallData, (string));

    // Forward the call
    TransferHelper.safeApprove(_toAsset, address(greeter), _amountOut);
    greeter.greetWithTokens(_toAsset, _amountOut, greeting);
    return true;
  }
}
