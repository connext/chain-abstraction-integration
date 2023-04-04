// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol";

import {MeanFinanceAdapter} from "./MeanFinanceAdapter.sol";
import {SwapAdapter} from "../../xreceivers/Swap/SwapAdapter.sol";

contract MeanFinanceTarget is MeanFinanceAdapter, SwapAdapter {
  // The Connext contract on this domain
  IConnext public immutable connext;

  receive() external payable virtual override(MeanFinanceAdapter, SwapAdapter) {}

  /// Modifier
  modifier onlyConnext() {
    require(msg.sender == address(connext), "Caller must be Connext");
    _;
  }

  constructor(address _connext) {
    connext = IConnext(_connext);
  }

  function _forwardFunctionCall(
    bytes memory _preparedData,
    bytes32 /*_transferId*/,
    uint256 /*_amount*/,
    address /*_asset*/
  ) internal virtual returns (bool) {
    (uint256 _amountOut, bytes memory _forwardCallData) = abi.decode(_preparedData, (uint256, bytes));
    (
      address _from,
      address _to,
      uint32 _amountOfSwaps,
      uint32 _swapInterval,
      address _owner,
      IDCAPermissionManager.PermissionSet[] memory _permissions
    ) = abi.decode(
        _forwardCallData,
        (address, address, uint32, uint32, address, IDCAPermissionManager.PermissionSet[])
      );
    IERC20(_from).approve(address(hub), _amountOut);
    hub.deposit(_from, _to, _amountOut, _amountOfSwaps, _swapInterval, _owner, _permissions);
    return true;
  }
}
