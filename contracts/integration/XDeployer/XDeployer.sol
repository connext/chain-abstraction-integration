// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";

contract XDeployer is IXReceiver {
  using Address for address;

  // The Connext contract on this domain
  IConnext public immutable connext;

  constructor(IConnext _connext) {
    connext = _connext;
  }

  /// ERRORS
  error XDeployer__onlyConnext(address sender);

  /// EVENTS
  event xdeployer(bytes32 _transferId, bool _success, bytes _data);

  /// MODIFIERS
  /** @notice A modifier to ensure that only the Connext contract on this domain can be the caller.
   * If this is not enforced, then funds on this contract may potentially be claimed by any EOA.
   */
  modifier onlyConnext() {
    if (msg.sender != address(connext)) {
      revert XDeployer__onlyConnext(msg.sender);
    }
    _;
  }

  /// @notice Receives funds from Connext and forwards them to a contract,
  /// And the contract deployed using the salt and bytecode passed via user on Origin.
  /// @dev _originSender and _origin are not used in this implementation because this is meant for an "unauthenticated" call.
  /// This means any router can call this function and no guarantees are made on the data passed in. This should only be used when there are
  /// funds passed into the contract that need to be forwarded to another contract. This guarantees economically that there is no
  /// reason to call this function maliciously, because the router would be spending their own funds.
  /// @param _transferId - The transfer ID of the transfer that triggered this call.
  /// @param _amount - The amount of funds received in this transfer.
  /// @param _callData - The data passed in from the router that triggered this call.
  /// @return The result of the external call, if any.
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address,
    address,
    uint32,
    bytes memory _callData
  ) external onlyConnext returns (bytes memory) {
    // Unpack the _callData
    // _callData is expected to be abi encoded as (bytes32 salt, bytes byteCode, bytes encodedFunctionData)
    // The salt is used to deploy the contract using create2
    // The byteCode is the bytecode of the contract to be deployed
    // The encodedFunctionData is the data to be called on the deployed contract
    (bytes32 salt, bytes memory byteCode, bytes memory encodedFunctionData) = abi.decode(
      _callData,
      (bytes32, bytes, bytes)
    );

    /// TODO: Add signature verification here to ensure that the call is coming from the origin user,
    /// TODO: this way we don't have to wait for slow path and can utilize the fast path for deployment of contracts.
    // Deploy the contract using create2
    address deployedAddress = Create2.deploy(_amount, salt, byteCode);

    // Call the function on the deployed contract
    (bool _success, bytes memory resultData) = deployedAddress.call(encodedFunctionData);
    /// OPTIONAL: Create callback xcall to send the address to origin for acknowledgement.

    emit xdeployer(_transferId, _success, resultData);
    return resultData;
  }
}
