// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ForwarderXReceiver} from "../ForwarderXReceiver.sol";
import {SwapAdapter} from "../../../shared/Swap/SwapAdapter.sol";

/**
 * @title SwapForwarderXReceiver
 * @author Connext
 * @notice Abstract contract to allow for swapping tokens before forwarding a call.
 */
abstract contract SwapForwarderXReceiver is ForwarderXReceiver, SwapAdapter {
  using Address for address;

  /// @dev The address of the Connext contract on this domain.
  constructor(address _connext) ForwarderXReceiver(_connext) {}

  /// INTERNAL
  /**
   * @notice Prepare the data by calling to the swap adapter. Return the data to be swapped.
   * @dev This is called by the xReceive function so the input data is provided by the Connext bridge.
   * @param _transferId The transferId of the transfer.
   * @param _data The data to be swapped.
   * @param _amount The amount to be swapped.
   * @param _asset The incoming asset to be swapped.
   */
  function _prepare(
    bytes32 _transferId,
    bytes memory _data,
    uint256 _amount,
    address _asset
  ) internal override returns (bytes memory) {
    (address _swapper, address _toAsset, bytes memory _swapData, bytes memory _forwardCallData) = abi.decode(
      _data,
      (address, address, bytes, bytes)
    );

    uint256 _amountOut = this.exactSwap(_swapper, _amount, _asset, _toAsset, _swapData);

    return abi.encode(_forwardCallData, _amountOut, _asset, _toAsset, _transferId);
  }
}
