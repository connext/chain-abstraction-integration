// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ProtocolTargetAdapter} from "./ProtocolTargetAdapter.sol";

contract ProtocolTarget is ProtocolTargetAdapter {
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
        address _originSender,
        uint32 _origin,
        bytes calldata _callData
    ) external payable onlyConnext returns (bytes memory) {
        // Decode calldata
        (address fallbackAddress, bytes4 selector, bytes memory data) = abi
            .decode(_callData, (address, bytes4, bytes));

        require(fallbackAddress != address(0), "!invalidFallback");

        if (!forwardFunctionCall(selector, data, _amount, _asset)) {
            IERC20(_asset).transferFrom(msg.sender, fallbackAddress, _amount);
        }
    }

    /// INTERNAL
    function forwardFunctionCall(
        bytes4 _selector,
        bytes memory _data,
        uint256 _amount,
        address _asset
    ) internal virtual returns (bool) {
        (bool success, bytes memory data) = address(this).call(
            abi.encodeWithSelector(
                _selector,
                _amount, // from here: Add params for selected function
                _asset,
                _data
            )
        );

        return success;
    }
}
