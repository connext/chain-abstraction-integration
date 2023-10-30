// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILockbox {
  function deposit(uint256 amount) external;

  function depositNative() external payable;

  function IS_NATIVE() external view returns (bool);

  function ERC20() external view returns (address);

  function XERC20() external view returns (address);
}

contract ConnextXERC20Adapter {
  address public immutable connext;

  constructor(address _connext) {
    connext = _connext;
  }

  function xcall(
    uint32 _destination,
    address _to,
    address _asset, // lockbox address
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32) {
    address asset = ILockbox(_asset).ERC20();
    address xerc20 = ILockbox(_asset).XERC20();

    if (ILockbox(_asset).IS_NATIVE()) {
      ILockbox(_asset).depositNative();
    } else {
      IERC20(asset).transferFrom(msg.sender, address(this), _amount);
      ILockbox(_asset).deposit(_amount);
    }
    IERC20(xerc20).approve(connext, _amount);

    return IConnext(connext).xcall(_destination, _to, xerc20, _delegate, _amount, _slippage, _callData);
  }
}
