// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {IGreeter} from "../../example/XSwapAndGreet/XSwapAndGreetTarget.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Greeter is IGreeter {
  string public greeting;

  function greetWithTokens(address _token, uint256 _amount, string calldata _greeting) external override {
    IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    greeting = _greeting;
  }
}
