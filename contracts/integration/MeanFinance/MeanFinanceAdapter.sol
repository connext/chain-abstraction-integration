// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDCAHub, IDCAPermissionManager} from "@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol";

contract MeanFinanceAdapter {
  /// @notice MeanFinance IDCAHub contract for deposit
  /// @dev see https://docs.mean.finance/guides/smart-contract-registry
  // IDCAHub public hub = IDCAHub(0xA5AdC5484f9997fBF7D405b9AA62A7d88883C345);
  IDCAHub public immutable hub;

  constructor(address _hub) {
    hub = IDCAHub(_hub);
  }

  /// @notice Creates a new position
  /// @param _from The address of the "from" token
  /// @param _to The address of the "to" token
  /// @param _amount How many "from" tokens will be swapped in total
  /// @param _amountOfSwaps How many swaps to execute for this position
  /// @param _swapInterval How frequently the position's swaps should be executed
  /// @param _owner The address of the owner of the position being created
  /// @return _positionId The id of the created position
  function deposit(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] memory _permissions
  ) internal returns (uint256 _positionId) {
    // We need to increase the allowance for the hub before calling deposit
    IERC20(_from).approve(address(hub), _amount);
    _positionId = hub.deposit(_from, _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions);
    return _positionId;
  }
}
