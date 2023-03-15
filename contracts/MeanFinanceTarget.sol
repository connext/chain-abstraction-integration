// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol";

struct DepositParams {
    address _from;
    address _to;
    uint256 _amount;
    uint32 _amountOfSwaps;
    uint32 _swapInterval;
    address _owner;
    IDCAPermissionManager.PermissionSet[] _permissions;
}

contract MeanFinanceTarget {
    // The Connext contract on this domain
    IConnext public immutable connext;
    IDCAHub public immutable hub;

    /// Events
    event XReceiveDeposit(
        bytes32 _transferId,
        uint256 _amount, // must be amount in bridge asset less fees
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes _callData,
        uint256 _positionId
    );

    /// Modifier
    modifier onlyConnext() {
        require(msg.sender == address(connext), "Caller must be Connext");
        _;
    }

    constructor(address _connext, address _hub) {
        connext = IConnext(_connext);
        hub = IDCAHub(_hub);
    }

    function xReceive(
        bytes32 _transferId,
        uint256 _amount, // Final Amount receive via Connext(After AMM calculation)
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes memory _callData
    ) external onlyConnext returns (bytes memory) {
        // Decode calldata
        (
            address from,
            address to,
            uint256 originalAmount,
            uint32 amountOfSwaps,
            uint32 swapInterval,
            address owner,
            IDCAPermissionManager.PermissionSet[] memory permissions
        ) = abi.decode(
                _callData,
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

        // Aggregator Swap (ideally only works if we don't sign on quote)
        // Final Amount after the swap

        // if we do aggregator swap need better way to compare for slippage.

        /// Sanity check for the Slippage _amount vs params._amount(Input at Origin)
        // fallback transfer amount to user address(params.owner)

        // deposit
        IERC20(address(this)).approve(address(hub), _amount);
        uint256 _positionId = hub.deposit(
            from,
            to,
            _amount,
            amountOfSwaps,
            swapInterval,
            owner,
            permissions
        );

        emit XReceiveDeposit(
            _transferId,
            _amount,
            _asset,
            _originSender,
            _origin,
            _callData,
            _positionId
        );
    }
}
