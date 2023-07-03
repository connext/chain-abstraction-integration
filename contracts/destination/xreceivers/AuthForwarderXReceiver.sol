// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title AuthForwarderXReceiver
 * @author Connext
 * @notice Abstract contract to allow for forwarding a call with authentication. Handles security and error handling.
 * @dev This is meant to be used in authenticated flows, so the data passed in is guaranteed to be correct with the
 * caveat that xReceive will fail until the AMB's validation window has elapsed. This is meant to be used when there
 * are funds passed into the contract that need to be forwarded to another contract.
 *
 * This contract inherits OpenZeppelin's Ownable module which allows ownership to be changed with `transferOwnership`.
 * For more details, see the implementation: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
abstract contract AuthForwarderXReceiver is IXReceiver, Ownable {
  /// The Connext contract on this domain
  IConnext public immutable connext;

  /// Allowed origin domains
  uint32[] public originDomains;

  /// Registry of origin senders from allowed origin domains
  /// @dev This contract will fail if the registry is not up to date with supported chains
  mapping(uint32 => address) public originRegistry;

  /// EVENTS
  event ForwardedFunctionCallFailed(bytes32 _transferId);
  event ForwardedFunctionCallFailed(bytes32 _transferId, string _errorMessage);
  event ForwardedFunctionCallFailed(bytes32 _transferId, uint _errorCode);
  event ForwardedFunctionCallFailed(bytes32 _transferId, bytes _lowLevelData);
  event OriginAdded(uint32 _originDomain, address _originSender);
  event OriginRemoved(uint32 _originDomain);
  event Prepared(bytes32 _transferId, bytes _data, uint256 _amount, address _asset);

  /// ERRORS
  error ForwarderXReceiver__onlyOrigin(uint32 originDomain, address originSender, address sender);
  error ForwarderXReceiver__prepareAndForward_notThis(address sender);
  error ForwarderXReceiver__constructor_mismatchingOriginArrayLengths(address sender);
  error ForwarderXReceiver__removeOrigin_invalidOrigin(uint32 originDomain);
  error ForwarderXReceiver__addOrigin_alreadySet(uint32 originDomain);
  error ForwarderXReceiver__addOrigin_zeroSender();

  /// MODIFIERS
  /** @notice A modifier for authenticated calls.
   * This is an important security consideration. If the target contract
   * function should be authenticated, it must check three things:
   *    1) The originating call comes from a registered origin domain.
   *    2) The originating call comes from the expected origin contract of the origin domain.
   *    3) The call to this contract comes from Connext.
   */
  modifier onlyOrigin(address _originSender, uint32 _origin) {
    address originSender = originRegistry[_origin];
    if (originSender == address(0) || originSender != _originSender || msg.sender != address(connext)) {
      revert ForwarderXReceiver__onlyOrigin(_origin, _originSender, msg.sender);
    }
    _;
  }

  /**
   * @dev The elements in the _origin* array params must be passed in the same relative positions.
   * @param _connext - The address of the Connext contract on this domain
   * @param _originDomains - Array of origin domains to be registered in the OriginRegistry
   * @param _originSenders - Array of senders on origin domains that are expected to call xcall
   */
  constructor(address _connext, uint32[] memory _originDomains, address[] memory _originSenders) {
    uint256 len = _originDomains.length;
    if (len != _originSenders.length) {
      revert ForwarderXReceiver__constructor_mismatchingOriginArrayLengths(msg.sender);
    }

    connext = IConnext(_connext);

    for (uint256 i; i < len; ) {
      _addOrigin(_originDomains[i], _originSenders[i]);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Add an origin domain to the originRegistry.
   * @param _originDomain - Origin domain to be registered in the OriginRegistry
   * @param _originSender - Sender on origin domain that is expected to call this contract
   */
  function addOrigin(uint32 _originDomain, address _originSender) external onlyOwner {
    _addOrigin(_originDomain, _originSender);
  }

  function _addOrigin(uint32 _originDomain, address _originSender) internal {
    if (_originSender == address(0)) revert ForwarderXReceiver__addOrigin_zeroSender();
    if (originRegistry[_originDomain] != address(0)) revert ForwarderXReceiver__addOrigin_alreadySet(_originDomain);

    originDomains.push(_originDomain);
    originRegistry[_originDomain] = _originSender;
    emit OriginAdded(_originDomain, _originSender);
  }

  /**
   * @dev Remove an origin domain from the originRegistry.
   * @param _originDomain - Origin domain to be removed from the OriginRegistry
   */
  function removeOrigin(uint32 _originDomain) external onlyOwner {
    uint256 len = originDomains.length;
    // Assign an out-of-bounds index by default
    uint256 indexToRemove = len;
    for (uint256 i; i < len; ) {
      if (originDomains[i] == _originDomain) {
        indexToRemove = i;
        break;
      }
      unchecked {
        ++i;
      }
    }

    if (indexToRemove == len) {
      revert ForwarderXReceiver__removeOrigin_invalidOrigin(_originDomain);
    }

    // Constant operation to remove origin since we don't need to preserve order
    originDomains[indexToRemove] = originDomains[len - 1];
    originDomains.pop();

    delete originRegistry[_originDomain];
    emit OriginRemoved(_originDomain);
  }

  /**
   * @notice Receives funds from Connext and forwards them to a contract, using a two step process which is defined by the developer.
   * @dev _originSender and _origin are passed into the onlyOrigin modifier to turn this into an "authenticated" call. This function
   * will fail until the AMB's validation window has elapsed, at which point _orginSender changes from the zero address to the correct
   * sender address from the origin domain. Note that transfers through this authenticated path cannot be boosted by routers.
   * @param _transferId - The transfer ID of the transfer that triggered this call
   * @param _amount - The amount of funds received in this transfer
   * @param _asset - The asset of the funds received in this transfer
   * @param _callData - The data to be prepared and forwarded
   */
  function xReceive(
    bytes32 _transferId,
    uint256 _amount, // Final amount received via Connext (after AMM swaps, if applicable)
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
    emit Prepared(_transferId, _data, _amount, _asset);

    // Forward the function call
    return _forwardFunctionCall(_prepared, _transferId, _amount, _asset);
  }

  /// INTERNAL VIRTUAL
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
