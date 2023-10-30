// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import {IConnext} from "@connext/interfaces/core/IConnext.sol";

import {IXERC20} from "../../shared/IXERC20/IXERC20.sol";
import {IXERC20Lockbox} from "../../shared/IXERC20/IXERC20Lockbox.sol";

contract GrumpycatLockboxAdapter is IXReceiver {
  IXERC20Lockbox public immutable lockbox;
  IERC20 public immutable erc20;
  IXERC20 public immutable xerc20;
  IConnext public immutable connext;

  error XReceiver__onlyConnext(address sender);

  modifier onlyConnext() {
    if (msg.sender != address(connext)) {
      revert XReceiver__onlyConnext(msg.sender);
    }
    _;
  }

  constructor(address _connext, address _lockbox, address _erc20, address _xerc20) {
    connext = IConnext(_connext);
    lockbox = IXERC20Lockbox(_lockbox);
    erc20 = IERC20(_erc20);
    xerc20 = IXERC20(_xerc20);
  }

  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32) {
    erc20.transferFrom(msg.sender, address(this), _amount);
    lockbox.deposit(_amount);
    xerc20.approve(address(connext), _amount);

    return IConnext(connext).xcall(_destination, _to, address(xerc20), _delegate, _amount, _slippage, _callData);
  }

  /// @dev This function receives xERC20s from Connext and calls the Lockbox
  /// @param _amount The amount of funds that will be received.
  /// @param _asset The address of the asset that will be received.
  /// @param _transferId The id of the transfer.
  /// @param _callData The data that will be sent to the targets.
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external onlyConnext returns (bytes memory) {
    // Check for the right xerc20
    require(_asset == address(xerc20), "Wrong asset received");

    // Unpack the _callData to get the recipient's address
    address _recipient = abi.decode(_callData, (address));

    withdraw(_amount, _recipient);
  }

  /// @notice Deposit ERC20s into the Lockbox
  /// @param _amount Amount of ERC20s to use
  /// @param _recipient Recipient of the xERC20s
  function deposit(uint256 _amount, address _recipient) internal {
    require(_amount > 0, "Zero amount");
    IERC20 _xerc20 = IERC20(address(xerc20));

    if (erc20.allowance(address(this), address(lockbox)) < _amount) {
      erc20.approve(address(lockbox), type(uint256).max);
    }
    lockbox.deposit(_amount);

    // Transfer the xERC20s to the recipient
    SafeERC20.safeTransfer(_xerc20, _recipient, _amount);
  }

  /// @notice Withdraw ERC20s from the Lockbox
  /// @param _amount Amount of xERC20s to use
  /// @param _recipient Recipient of the ERC20s
  function withdraw(uint256 _amount, address _recipient) internal {
    require(_amount > 0, "Zero amount");
    IERC20 _xerc20 = IERC20(address(xerc20));

    if (_xerc20.allowance(address(this), address(lockbox)) < _amount) {
      _xerc20.approve(address(lockbox), type(uint256).max);
    }
    lockbox.withdraw(_amount);

    // Transfer the ERC20s to the recipient
    SafeERC20.safeTransfer(erc20, _recipient, _amount);
  }
}
