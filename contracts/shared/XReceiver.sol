// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract XReceiver {
    // The Connext contract on this domain
    IConnext public immutable connext;
    address public immutable target;

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
    ) external payable onlyConnext returns (bool) {
        // Decode calldata
        (address fallbackAddress, bytes4 selector, bytes memory data) = abi
            .decode(_callData, (address, bytes4, bytes));

        require(fallbackAddress != address(0), "!invalidFallback");

        bool success;
        try forwardFunctionCall(data, _amount, _asset) returns (bool result) {
            success = result;
        // TODO: emit catch events
        } catch Error(string memory /*reason*/) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            success = false;
        } catch Panic(uint /*errorCode*/) {
            // This is executed in case of a panic,
            // i.e. a serious error like division by zero
            // or overflow. The error code can be used
            // to determine the kind of error.
            success = false;
        } catch (bytes memory /*lowLevelData*/) {
            // This is executed in case revert() was used.
            success = false;
        }

        if (!success) {
            IERC20(_asset).transferFrom(msg.sender, fallbackAddress, _amount);
        }
    }

    /// INTERNAL
    function forwardFunctionCall(
        bytes memory _data,
        uint256 _amount,
        address _asset
    ) internal virtual returns (bool) {}
}
