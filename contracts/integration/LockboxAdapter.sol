// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IXERC20} from "../shared/IXERC20/IXERC20.sol";
import {IXERC20Lockbox} from "../shared/IXERC20/IXERC20Lockbox.sol";
import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";

contract LockboxAdapter is IXReceiver {
  address immutable connext;

  constructor(address _connext) {
    connext = _connext;
  }

  /// @dev Combines Lockbox deposit and xcall using native asset as relayer fee.
  /// @param _destination The destination domain ID.
  /// @param _to The recipient or contract address on destination.
  /// @param _lockbox The address of the Lockbox, given this contract is only used for xERC20s.
  /// @param _delegate The address of the Lockbox, given this contract is only used for xERC20s.
  /// @param _amount The amount of asset to bridge.
  /// @param _slippage The maximum slippage a user is willing to take, in BPS.
  /// @param _callData The data that will be sent to the target contract.
  function xcall(
    uint32 _destination,
    address _to,
    address _lockbox,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32) {
    require(_amount > 0, "Amount must be greater than 0");

    address xerc20 = IXERC20Lockbox(_lockbox).XERC20();
    bool isNative = IXERC20Lockbox(_lockbox).IS_NATIVE();

    // Relayer fee is paid in xERC20, so it will also be exchanged in the Lockbox
    uint256 totalAmount = msg.value;

    uint256 _relayerFee;
    if (isNative) {
      require(msg.value >= _amount, "Value sent must be at least equal to the amount specified");

      // Assume the rest of msg.value is the relayer fee
      _relayerFee = msg.value - _amount;
      IXERC20Lockbox(_lockbox).depositNative{value: totalAmount}();
    } else {
      // The entirety of msg.value is the relayer fee
      _relayerFee = msg.value;
      IERC20(xerc20).transferFrom(msg.sender, address(this), _amount);
      IERC20(xerc20).approve(_lockbox, _amount);
      IXERC20Lockbox(_lockbox).deposit(_amount);
    }

    IERC20(xerc20).approve(connext, _amount);
    return
      IConnext(connext).xcall{value: _relayerFee}(_destination, _to, xerc20, _delegate, _amount, _slippage, _callData);
  }

  /// @dev Receives xERC20s from Connext and calls the Lockbox.
  /// @param _transferId The ID of the transfer.
  /// @param _amount The amount of funds that will be received.
  /// @param _asset The address of the asset that will be received.
  /// @param _callData The data to decode.
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external returns (bytes memory) {
    // Unpack the _callData to get the recipient's address
    address _recipient = abi.decode(_callData, (address));

    // TODO: how to get lockbox here without registry?
    // IERC20(_asset).approve(_lockbox, _amount);

    // if (_xerc20.allowance(address(this), address(lockbox)) < _amount) {
    //   _xerc20.approve(address(lockbox), _amount);
    // }
    // lockbox.withdraw(_amount);
  }
}
