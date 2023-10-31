// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IXERC20} from "../shared/IXERC20/IXERC20.sol";
import {IXERC20Lockbox} from "../shared/IXERC20/IXERC20Lockbox.sol";
import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";

interface IXERC20Registry {
  function ERC20ToXERC20(address erc20) external view returns (address xerc20);
}

contract LockboxAdapter is IXReceiver {
  address immutable connext;
  address immutable registry;

  constructor(address _connext, address _registry) {
    connext = _connext;
    registry = _registry;
  }

  /// @dev Combines Lockbox deposit and xcall using native asset as relayer fee.
  /// @param _destination The destination domain ID.
  /// @param _to The recipient or contract address on destination.
  /// @param _asset The address of the asset to be sent.
  /// @param _delegate The address on destination allowed to update slippage.
  /// @param _amount The amount of asset to bridge.
  /// @param _slippage The maximum slippage a user is willing to take, in BPS.
  /// @param _callData The data that will be sent to the target contract.
  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32) {
    require(_amount > 0, "Amount must be greater than 0");

    address xerc20 = IXERC20Registry(registry).ERC20ToXERC20(_asset);
    address lockbox = IXERC20(xerc20).lockbox();
    address erc20 = IXERC20Lockbox(lockbox).ERC20();
    bool isNative = IXERC20Lockbox(lockbox).IS_NATIVE();

    uint256 _relayerFee;
    if (isNative) {
      require(msg.value >= _amount, "Value sent must be at least equal to the amount specified");

      // Exchange (native) ERC20 for xERC20
      IXERC20Lockbox(lockbox).depositNative{value: _amount}();

      // Assume the rest of msg.value is the relayer fee
      _relayerFee = msg.value - _amount;
    } else {
      // Requires user approval
      IERC20(erc20).transferFrom(msg.sender, address(this), _amount);
      IERC20(erc20).approve(lockbox, _amount);

      // Exchange ERC20 for xERC20
      IXERC20Lockbox(lockbox).deposit(_amount);

      // The entirety of msg.value is the relayer fee
      _relayerFee = msg.value;
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
