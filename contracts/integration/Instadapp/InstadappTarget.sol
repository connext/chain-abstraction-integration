//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {InstadappAdapter} from "./InstadappAdapter.sol";

/// @title InstadappTarget
/// @author Connext
/// @notice You can use this contract for cross-chain casting via dsa address
/// @dev This contract is used to receive funds from Connext
/// and forward them to Instadapp DSA via authCast function, In case of failure,
/// funds are forwarded to fallback address defined by the user under callData.
/// @custom:experimental This is an experimental contract.
contract InstadappTarget is IXReceiver, InstadappAdapter {
  /// Storage
  /// @dev This is the address of the Connext contract.
  IConnext public connext;

  /// Events
  /// @dev This event is emitted when the authCast function is called.
  event AuthCast(bytes32 transferId, address dsaAddress, address auth, bool success, bytes returnedData);

  /// Modifiers
  /// @dev This modifier is used to ensure that only the Connext contract can call the function.
  modifier onlyConnext() {
    require(msg.sender == address(connext), "Caller must be Connext");
    _;
  }

  /// Constructor
  /// @param _connext The address of the Connext contract.
  constructor(address _connext) {
    connext = IConnext(_connext);
  }

  /// Public functions
  /// @dev This function is used to receive funds from Connext and forward them to DSA.
  /// Then it forwards the call to authCast function.
  /// @param _amount The amount of funds that will be received.
  /// @param _asset The address of the asset that will be received.
  /// @param _transferId The id of the transfer.
  /// @param _callData The data that will be sent to the targets.
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address,
    uint32,
    bytes memory _callData
  ) external onlyConnext returns (bytes memory) {
    // Decode signed calldata
    (address dsaAddress, address auth, bytes memory signature, CastData memory _castData) = abi.decode(
      _callData,
      (address, address, bytes, CastData)
    );

    // verify the dsaAddress
    require(dsaAddress != address(0), "!invalidFallback");

    // transfer funds to this dsaAddress
    IERC20(_asset).transfer(dsaAddress, _amount);

    // forward call to AuthCast
    (bool success, bytes memory returnedData) = address(this).call(
      abi.encodeWithSignature("authCast(address,address,bytes,CastData)", dsaAddress, auth, signature, _castData)
    );

    emit AuthCast(_transferId, dsaAddress, auth, success, returnedData);

    return returnedData;
  }
}
