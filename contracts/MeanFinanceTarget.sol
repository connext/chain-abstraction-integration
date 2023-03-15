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
        DepositParams params,
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
        uint256 _amount, // must be amount in bridge asset less fees
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes memory _callData
    ) external onlyConnext returns (bytes memory) {
        // Decode calldata
        DepositParams memory params = abi.decode(_callData, (DepositParams));

        // deposit
        IERC20(params._from).approve(address(hub), _amount);
        uint256 _positionId = hub.deposit(
            params._from,
            params._to,
            _amount,
            params._amountOfSwaps,
            params._swapInterval,
            params._owner,
            params._permissions
        );

        emit XReceiveDeposit(
            _transferId,
            _amount,
            _asset,
            _originSender,
            _origin,
            _callData,
            params,
            _positionId
        );
    }
}
