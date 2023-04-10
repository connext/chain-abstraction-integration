//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {InstadappAdapter} from "./InstadappAdapter.sol";

/// @title InstadappTarget
/// @notice You can use this contract for cross-chain casting via dsa address
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This needs to have audit.
contract InstadappTarget is IXReceiver, InstadappAdapter {
  // The Connext contract on this domain
  IConnext public connext;

  /// EVENTS
  event AuthCast(bytes32 transferId, address dsaAddress, address auth, bool success, bytes returnedData);

  /// MODIFIERS
  modifier onlyConnext() {
    require(msg.sender == address(connext), "Caller must be Connext");
    _;
  }

  constructor(address _connext) {
    connext = IConnext(_connext);
  }

  /**
   * @notice Receives funds from Connext and forwards them to a fallback address defined by the user under callData,
   * And forwards call to authCast function
   * @dev _originSender and _origin are not used in this implementation because this is meant for an "unauthenticated" call. This means
   * any router can call this function and no guarantees are made on the data passed in. This should only be used when there are
   * funds passed into the contract that need to be forwarded to another contract. This guarantees economically that there is no
   * reason to call this function maliciously, because the router would be spending their own funds.
   * @param _transferId - The transfer ID of the transfer that triggered this call
   * @param _callData - The data to be prepared and forwarded
   */
  function xReceive(
    bytes32 _transferId,
    uint256, // must be amount in bridge asset less fees
    address,
    address,
    uint32,
    bytes memory _callData
  ) external onlyConnext returns (bytes memory) {
    // Decode signed calldata
    (address dsaAddress, address auth, bytes memory signature, CastData memory _castData) = abi.decode(
      _callData,
      (address, address, bytes, CastData)
    );

    require(dsaAddress != address(0), "!invalidFallback");

    (bool success, bytes memory returnedData) = address(this).call(
      abi.encodeWithSignature("authCast(address,address,bytes,CastData)", dsaAddress, auth, signature, _castData)
    );

    emit AuthCast(_transferId, dsaAddress, auth, success, returnedData);

    return returnedData;
  }
}
