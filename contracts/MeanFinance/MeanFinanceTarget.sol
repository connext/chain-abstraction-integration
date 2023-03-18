// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MeanFinanceAdapter.sol";

contract MeanFinanceTarget is MeanFinanceAdapter {
    // The Connext contract on this domain
    IConnext public immutable connext;

    event Deposit(
        bytes32 _transferId,
        uint256 _amount,
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes _callData,
        uint256 originalAmount
    );
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
    ) external returns (bytes memory) {
        // Decode calldata
        (
            address from,
            address to,
            uint256 originalAmount,
            uint32 amountOfSwaps,
            uint32 swapInterval,
            address owner,
            IDCAPermissionManager.PermissionSet[] memory permissions
        ) = decode(_callData);

        // Aggregator Swap (ideally only works if we don't sign on quote)
        // Final Amount after the swap

        // if we do aggregator swap need better way to compare for slippage.

        /// Sanity check for the Slippage _amount vs params._amount(Input at Origin)
        // fallback transfer amount to user address(params.owner)

        // deposit
        deposit(
            from,
            to,
            originalAmount,
            amountOfSwaps,
            swapInterval,
            owner,
            permissions
        );

        emit Deposit(
            _transferId,
            _amount,
            _asset,
            _originSender,
            _origin,
            _callData,
            originalAmount
        );
    }

    function encode(
        address from,
        address to,
        uint256 originalAmount,
        uint32 amountOfSwaps,
        uint32 swapInterval,
        address owner,
        IDCAPermissionManager.PermissionSet[] memory permissions
    ) external pure returns (bytes memory) {
        return
            abi.encode(
                from,
                to,
                originalAmount,
                amountOfSwaps,
                swapInterval,
                owner,
                permissions
            );
    }

    function decode(
        bytes calldata data
    )
        internal
        pure
        returns (
            address from,
            address to,
            uint256 originalAmount,
            uint32 amountOfSwaps,
            uint32 swapInterval,
            address owner,
            IDCAPermissionManager.PermissionSet[] memory permissions
        )
    {
        (
            from,
            to,
            originalAmount,
            amountOfSwaps,
            swapInterval,
            owner,
            permissions
        ) = abi.decode(
            data,
            (
                address,
                address,
                uint256,
                uint32,
                uint32,
                address,
                IDCAPermissionManager.PermissionSet[]
            )
        );
    }
}
