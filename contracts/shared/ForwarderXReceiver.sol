// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IConnext } from "@connext/interfaces/core/IConnext.sol";
import { IXReceiver } from "@connext/interfaces/core/IXReceiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ForwarderXReceiver {
  // The Connext contract on this domain
  IConnext public immutable connext;

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
    address /*_originSender*/,
    uint32 /*_origin*/,
    bytes calldata _callData
  ) external payable onlyConnext {
    // Decode calldata
    (address fallbackAddress, bytes memory data) = abi.decode(
      _callData,
      (address, bytes)
    );

    require(fallbackAddress != address(0), "!invalidFallback");

    // transfer to fallback address if forwardFunctionCall fails
    if (!_prepareAndForward(_transferId, data, _amount, _asset)) {
      IERC20(_asset).transfer(fallbackAddress, _amount);
    }
  }

  /// INTERNAL
  function _prepareAndForward(
    bytes32 _transferId,
    bytes memory _data,
    uint256 _amount,
    address _asset
  ) internal returns (bool) {
    // Prepare for forwarding
    bytes memory _prepared = _prepare(_transferId, _data, _amount, _asset);

    // Forward the call
    return _forwardFunctionCall(_prepared, _transferId, _data, _amount, _asset);
  }

  function _prepare(
    bytes32 /*_transferId*/,
    bytes memory _data,
    uint256 /*_amount*/,
    address /*_asset*/
  ) internal virtual returns (bytes memory) {
    return _data;
  }

  function _forwardFunctionCall(
    bytes memory _prepared,
    bytes32 _transferId,
    bytes memory _data,
    uint256 _amount,
    address _asset
  ) internal virtual returns (bool) {}
}
