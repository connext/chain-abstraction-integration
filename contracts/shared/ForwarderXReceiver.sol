// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ForwarderXReceiver {
    // The Connext contract on this domain
    IConnext public immutable connext;

    /// EVENTS
    event ForwardedFunctionCallFailed(bytes32 _transferId);
    event ForwardedFunctionCallFailed(
        bytes32 _transferId,
        string _errorMessage
    );
    event ForwardedFunctionCallFailed(bytes32 _transferId, uint _errorCode);
    event ForwardedFunctionCallFailed(bytes32 _transferId, bytes _lowLevelData);

    /// ERRORS
    error ForwarderXReceiver__prepareAndForward_notThis(address sender);

    /// MODIFIERS
    modifier onlyConnext() {
        require(msg.sender == address(connext), "Caller must be Connext");
        _;
    }

    constructor(address _connext) {
        connext = IConnext(_connext);
    }

    /**
     * @notice Receives funds from Connext and forwards them to a contract, using a two step process which is defined by the developer.
     * @dev _originSender and _origin are not used in this implementation because this is meant for an "unauthenticated" call. This means
     * any router can call this function and no guarantees are made on the data passed in. This should only be used when there are
     * funds passed into the contract that need to be forwarded to another contract. This guarantees economically that there is no
     * reason to call this function maliciously, because the router would be spending their own funds.
     * @param _transferId - The transfer ID of the transfer that triggered this call
     * @param _amount - The amount of funds received in this transfer
     * @param _asset - The asset of the funds received in this transfer
     * @param _callData - The data to be prepared and forwarded
     */
    function xReceive(
        bytes32 _transferId,
        uint256 _amount, // Final Amount receive via Connext(After AMM calculation)
        address _asset,
        address /*_originSender*/,
        uint32 /*_origin*/,
        bytes calldata _callData
    ) external onlyConnext {
        // Decode calldata
        (address _fallbackAddress, bytes memory _data) = abi.decode(
            _callData,
            (address, bytes)
        );

        bool successfulForward;
        try
            this.prepareAndForward(_transferId, _data, _amount, _asset)
        returns (bool success) {
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
        return _data;
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
