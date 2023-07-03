// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// interface IGreeter {
//   function greetWithTokens(address _token, uint256 _amount, string calldata _greeting);
// }

contract GreeterAdapter {
  string public greeting;

  event GreetingUpdated(string _greeting);

  function greetWithTokens(address _token, uint256 _amount, string memory _greeting) internal {
    require(_amount > 0, "Amount can not be zero");
    IERC20(_token).approve(address(this), type(uint256).max);
    greeting = _greeting;
    emit GreetingUpdated(_greeting);
  }
}