// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IXERC20} from "../shared/IXERC20/IXERC20.sol";
import {IXERC20Lockbox} from "../shared/IXERC20/IXERC20Lockbox.sol";
import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";

interface IXERC20Registry {
  function getXERC20(address erc20) external view returns (address xerc20);

  function getERC20(address xerc20) external view returns (address erc20);

  function getLockbox(address erc20) external view returns (address xerc20);
}

contract LockboxAdapter is IXReceiver {
  address immutable connext;
  address immutable registry;

  // EVENTS
  event LockBoxWithdrawFailed(bytes _lowLevelData);

  // ERRORS
  error Forwarder__is__not__Adapter(address sender);
  error IXERC20Adapter_WithdrawFailed();
  error NotConnext(address sender);
  error AmountLessThanZero();
  error ValueLessThanAmount(uint256 value, uint256 amount);

  modifier onlyConnext() {
    if (msg.sender != connext) {
      revert NotConnext(msg.sender);
    }
    _;
  }

  constructor(address _connext, address _registry) {
    connext = _connext;
    registry = _registry;
  }

  /// @dev Combines Lockbox deposit and xcall using native asset as relayer fee.
  /// @param _destination The destination domain ID.
  /// @param _to The recipient or contract address on destination.
  /// @param _asset The address of the asset to be sent (ERC20 or native).
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
    if (_amount <= 0) {
      revert AmountLessThanZero();
    }

    address xerc20 = IXERC20Registry(registry).getXERC20(_asset);
    address lockbox = IXERC20Registry(registry).getLockbox(xerc20);
    bool isNative = IXERC20Lockbox(lockbox).IS_NATIVE();

    uint256 _relayerFee;
    if (isNative) {
      if (msg.value < _amount) {
        revert ValueLessThanAmount(msg.value, _amount);
      }

      // Assume the rest of msg.value is the relayer fee
      _relayerFee = msg.value - _amount;
      IXERC20Lockbox(lockbox).depositNative{value: _amount}();
    } else {
      // IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
      SafeERC20.safeTransferFrom(IERC20(_asset), msg.sender, address(this), _amount);
      IERC20(_asset).approve(lockbox, _amount);

      // The entirety of msg.value is the relayer fee
      _relayerFee = msg.value;
      IXERC20Lockbox(lockbox).deposit(_amount);
    }

    IERC20(xerc20).approve(connext, _amount);
    return
      IConnext(connext).xcall{value: _relayerFee}(_destination, _to, xerc20, _delegate, _amount, _slippage, _callData);
  }

  /// @dev Receives xERC20s from Connext and withdraws ERC20 from Lockbox.
  /// @param _amount The amount of funds that will be received.
  /// @param _asset The address of the XERC20 that will be received.
  /// @param _callData The data which should contain the recipient's address.
  function xReceive(
    bytes32 /* _transferId */,
    uint256 _amount,
    address _asset,
    address /* _originSender */,
    uint32 /* _origin */,
    bytes memory _callData
  ) external onlyConnext returns (bytes memory) {
    address recipient = abi.decode(_callData, (address));

    try this.handlexReceive(_amount, _asset, recipient) {} catch (bytes memory _lowLevelData) {
      // This is executed in case revert() was used.
      IERC20(_asset).transfer(recipient, _amount);
      emit LockBoxWithdrawFailed(_lowLevelData);
    }

    return "";
  }

  function handlexReceive(uint256 _amount, address _asset, address _recipient) public {
    if (msg.sender != address(this)) {
      revert Forwarder__is__not__Adapter(msg.sender);
    }
    address lockbox = IXERC20Registry(registry).getLockbox(_asset);
    address erc20 = IXERC20Registry(registry).getERC20(_asset);
    bool isNative = IXERC20Lockbox(lockbox).IS_NATIVE();
    IERC20(_asset).approve(lockbox, _amount);
    IXERC20Lockbox(lockbox).withdraw(_amount);

    if (isNative) {
      (bool _success, ) = payable(_recipient).call{value: _amount}("");
      if (!_success) revert IXERC20Adapter_WithdrawFailed();
    } else {
      SafeERC20.safeTransfer(IERC20(erc20), _recipient, _amount);
    }
  }

  receive() external payable {}
}
