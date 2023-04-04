// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { TransferHelper } from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import { ForwarderXReceiver } from "../shared/ForwarderXReceiver.sol";

abstract contract GenericSwapForwarderXReceiver is ForwarderXReceiver {
  using Address for address;
  using Address for address payable;

  mapping(address => bool) public allowedSwappers;

  address public immutable uniswapSwapRouter =
    address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  constructor() {
    allowedSwappers[address(this)] = true;
    allowedSwappers[uniswapSwapRouter] = true;
  }

  /// INTERNAL
  function _prepare(
    bytes32 /*_transferId*/,
    bytes memory _data,
    uint256 _amount,
    address _asset
  ) internal override returns (bytes memory) {
    (address swapper, bytes4 _selector, bytes calldata _swapData) = abi.decode(
      _data,
      (address, bytes4, bytes)
    );

    _swapper.functionCallWithValue(_swapData, "!directSwapperCallFailed");

    return abi.encode(amounts, toAsset, path, amountOutMin, forwardCallData);
  }
}
