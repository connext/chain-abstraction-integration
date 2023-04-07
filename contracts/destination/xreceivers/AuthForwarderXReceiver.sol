// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract AuthForwarderXReceiver is IXReceiver, Ownable {
  struct OriginInfo {
    address originConnext;
    address originSender;
  }

  /// The Connext contract on this domain
  IConnext public immutable connext;

  /// Allowed origin domains
  uint32[] public originDomains;

  /// Registry of senders and Connext contracts of allowed origin domains
  mapping(uint32 => OriginInfo) public originRegistry;

  /// EVENTS
  event ForwardedFunctionCallFailed(bytes32 _transferId);
  event ForwardedFunctionCallFailed(bytes32 _transferId, string _errorMessage);
  event ForwardedFunctionCallFailed(bytes32 _transferId, uint _errorCode);
  event ForwardedFunctionCallFailed(bytes32 _transferId, bytes _lowLevelData);

  /// ERRORS
  error ForwarderXReceiver__onlyOrigin(address originSender, uint32 origin, address sender);
  error ForwarderXReceiver__prepareAndForward_notThis(address sender);

  /// MODIFIERS
  /** @notice A modifier for authenticated calls.
   * This is an important security consideration. If the target contract
   * function should be authenticated, it must check three things:
   *    1) The originating call comes from the expected origin domain.
   *    2) The originating call comes from the expected origin contract.
   *    3) The call to this contract comes from Connext.
   */
  modifier onlyOrigin(address _originSender, uint32 _origin) {
    OriginInfo memory info = originRegistry[_origin];
    if (msg.sender != address(connext) || _originSender != info.originSender || msg.sender != info.originConnext) {
      revert ForwarderXReceiver__onlyOrigin(_originSender, _origin, msg.sender);
    }
    _;
  }

  /**
   * @dev The elements in the _origin* array params must be passed in the same relative positions.
   * @param _connext - The address of the Connext contract on this domain
   * @param _originDomains - Array of origin domains to be registered in the OriginRegistry
   * @param _originConnexts - Array of Connext contracts on origin domains
   * @param _originSenders - Array of senders on origin domains that are expected to call this contract
   */
  constructor(
    address _connext,
    uint32[] memory _originDomains,
    address[] memory _originConnexts,
    address[] memory _originSenders
  ) {
    require(
      _originDomains.length == _originConnexts.length && _originDomains.length == _originSenders.length,
      "Lengths of origin params must match"
    );

    connext = IConnext(_connext);

    for (uint32 i = 0; i < _originConnexts.length; i++) {
      originDomains.push(_originDomains[i]);
      originRegistry[_originDomains[i]] = OriginInfo(_originConnexts[i], _originSenders[i]);
    }
  }

  /**
   * @dev Add an origin domain to the originRegistry.
   * @param _originDomain - Origin domain to be registered in the OriginRegistry
   * @param _originConnext - Connext contract on origin domain
   * @param _originSender - Sender on origin domain that is expected to call this contract
   */
  function addOrigin(uint32 _originDomain, address _originConnext, address _originSender) public onlyOwner {
    originDomains.push(_originDomain);
    originRegistry[_originDomain] = OriginInfo(_originConnext, _originSender);
  }

  /**
   * @dev Remove an origin domain from the originRegistry.
   * @param _originDomain - Origin domain to be removed from the OriginRegistry
   */
  function removeOrigin(uint32 _originDomain) public onlyOwner {
    // Assign an out-of-bounds index by default
    uint32 indexToRemove = uint32(originDomains.length);
    for (uint32 i = 0; i < originDomains.length; i++) {
      if (originDomains[i] == _originDomain) {
        indexToRemove = i;
        break;
      }
    }

    require(indexToRemove < originDomains.length, "Origin domain not found");

    // Constant operation to remove origin since we don't need to preserve order
    originDomains[indexToRemove] = originDomains[originDomains.length - 1];
    originDomains.pop();

    delete originRegistry[_originDomain];
  }

  /**
   * @notice Receives funds from Connext and forwards them to a contract, using a two step process which is defined by the developer.
   * @dev _originSender and _origin are passed into the onlyOrigin modifier to turn this into an "authenticated" call. This function
   * will fail until the AMB's validation window has elapsed, at which point _orginSender changes from the zero address to the correct
   * sender address from the origin domain.
   * @param _transferId - The transfer ID of the transfer that triggered this call
   * @param _amount - The amount of funds received in this transfer
   * @param _asset - The asset of the funds received in this transfer
   * @param _callData - The data to be prepared and forwarded
   */
  function xReceive(
    bytes32 _transferId,
    uint256 _amount, // Final Amount receive via Connext(After AMM calculation)
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external onlyOrigin(_originSender, _origin) returns (bytes memory) {
    // Decode calldata
    (address _fallbackAddress, bytes memory _data) = abi.decode(_callData, (address, bytes));

    bool successfulForward;
    try this.prepareAndForward(_transferId, _data, _amount, _asset) returns (bool success) {
      successfulForward = success;
      if (!success) {
        emit ForwardedFunctionCallFailed(_transferId);
      }
      // transfer to fallback address if forwardFunctionCall fails
    } catch Error(string memory _errorMessage) {
      // This is executed in case
      // revert was called with a reason string
      successfulForward = false;
      emit ForwardedFunctionCallFailed(_transferId, _errorMessage);
    } catch Panic(uint _errorCode) {
      // This is executed in case of a panic,
      // i.e. a serious error like division by zero
      // or overflow. The error code can be used
      // to determine the kind of error.
      successfulForward = false;
      emit ForwardedFunctionCallFailed(_transferId, _errorCode);
    } catch (bytes memory _lowLevelData) {
      // This is executed in case revert() was used.
      successfulForward = false;
      emit ForwardedFunctionCallFailed(_transferId, _lowLevelData);
    }
    if (!successfulForward) {
      IERC20(_asset).transfer(_fallbackAddress, _amount);
    }
    // Return the success status of the forwardFunctionCall
    return abi.encode(successfulForward);
  }

  /// INTERNAL
  /**
   * @notice Prepares the data for the function call and forwards it. This can execute
   * any arbitrary function call in a two step process. For example, _prepare can be used to swap funds
   * on a DEX, and _forwardFunctionCall can be used to call a contract with the swapped funds.
   * @dev This function is intended to be called by the xReceive function, and should not be called outside
   * of that context. The function is `public` so that it can be used with try-catch.
   *
   * @param _transferId - The transfer ID of the transfer that triggered this call
   * @param _data - The data to be prepared
   * @param _amount - The amount of funds received in this transfer
   * @param _asset - The asset of the funds received in this transfer
   */
  function prepareAndForward(
    bytes32 _transferId,
    bytes memory _data,
    uint256 _amount,
    address _asset
  ) public returns (bool) {
    if (msg.sender != address(this)) {
      revert ForwarderXReceiver__prepareAndForward_notThis(msg.sender);
    }
    // Prepare for forwarding
    bytes memory _prepared = _prepare(_transferId, _data, _amount, _asset);
    // Forward the function call
    return _forwardFunctionCall(_prepared, _transferId, _amount, _asset);
  }

  /// INTERNAL ABSTRACT
  /**
   * @notice Prepares the data for the function call. This can execute any arbitrary function call in a two step process.
   * For example, _prepare can be used to swap funds on a DEX, or do any other type of preparation, and pass on the
   * prepared data to _forwardFunctionCall.
   * @dev This function needs to be overriden in implementations of this contract. If no preparation is needed, this
   * function can be overriden to return the data as is.
   *
   * @param _transferId - The transfer ID of the transfer that triggered this call
   * @param _data - The data to be prepared
   * @param _amount - The amount of funds received in this transfer
   * @param _asset - The asset of the funds received in this transfer
   */
  function _prepare(
    bytes32 _transferId,
    bytes memory _data,
    uint256 _amount,
    address _asset
  ) internal virtual returns (bytes memory) {
    return abi.encode(_data, _transferId, _amount, _asset);
  }

  /**
   * @notice Forwards the function call. This can execute any arbitrary function call in a two step process.
   * The first step is to prepare the data, and the second step is to forward the function call to a
   * given contract.
   * @dev This function needs to be overriden in implementations of this contract.
   *
   * @param _preparedData - The data to be forwarded, after processing in _prepare
   * @param _transferId - The transfer ID of the transfer that triggered this call
   * @param _amount - The amount of funds received in this transfer
   * @param _asset - The asset of the funds received in this transfer
   */
  function _forwardFunctionCall(
    bytes memory _preparedData,
    bytes32 _transferId,
    uint256 _amount,
    address _asset
  ) internal virtual returns (bool) {}
}
