// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IConnext } from "@connext/interfaces/core/IConnext.sol";
import { IXReceiver } from "@connext/interfaces/core/IXReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MeanFinanceAdapter.sol";
import "../Uniswap/UniswapAdapter.sol";

contract MeanFinanceTarget is MeanFinanceAdapter, UniswapAdapter {
  // The Connext contract on this domain
  IConnext public immutable connext;

  receive()
    external
    payable
    virtual
    override(MeanFinanceAdapter, UniswapAdapter)
  {}

  /// Modifier
  modifier onlyConnext() {
    require(msg.sender == address(connext), "Caller must be Connext");
    _;
  }

  constructor(address _connext) {
    connext = IConnext(_connext);
  }

  function xReceive(
    bytes32 _transferId,
    uint256 _amount, // Final Amount receive via Connext(After AMM calculation)
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes calldata _callData
  ) external returns (bytes memory) {
    uint256 amount = _amount;
    // Decode calldata
    (
      uint24 poolFee,
      uint256 amountOutMin,
      address from,
      address to,
      uint32 amountOfSwaps,
      uint32 swapInterval,
      address owner,
      IDCAPermissionManager.PermissionSet[] memory permissions
    ) = decode(_callData);

    require(amount > 0, "!amount");
    require(amountOutMin > 0, "!amountOut");
    require(from != address(0), "!invalid");

    if (from != _asset) {
      // swap to deposit asset if needed
      amount = swap(_asset, from, poolFee, amount, amountOutMin);
      // TODO: add fallback to return funds to user address
    }

    // deposit
    deposit(from, to, amount, amountOfSwaps, swapInterval, owner, permissions);
  }

  function encode(
    uint24 poolFee,
    uint256 amountOutMin,
    address from,
    address to,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] memory permissions
  ) external pure returns (bytes memory) {
    return
      abi.encode(
        poolFee,
        amountOutMin,
        from,
        to,
        amountOfSwaps,
        swapInterval,
        owner,
        permissions
      );
  }

  /// INTERNAL
  function decode(
    bytes calldata data
  )
    internal
    pure
    returns (
      uint24 poolFee,
      uint256 amountOutMin,
      address from,
      address to,
      uint32 amountOfSwaps,
      uint32 swapInterval,
      address owner,
      IDCAPermissionManager.PermissionSet[] memory permissions
    )
  {
    (
      poolFee,
      amountOutMin,
      from,
      to,
      amountOfSwaps,
      swapInterval,
      owner,
      permissions
    ) = abi.decode(
      data,
      (
        uint24,
        uint256,
        address,
        address,
        uint32,
        uint32,
        address,
        IDCAPermissionManager.PermissionSet[]
      )
    );
  }
}
