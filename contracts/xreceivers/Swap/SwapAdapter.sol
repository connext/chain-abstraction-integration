//SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {ISwapper} from "./interfaces/ISwapper.sol";

contract SwapAdapter is Ownable2Step {
  using Address for address;
  using Address for address payable;

  mapping(address => bool) public allowedSwappers;

  address public immutable uniswapSwapRouter = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  constructor() {
    allowedSwappers[address(this)] = true;
    allowedSwappers[uniswapSwapRouter] = true;
  }

  /// Payable
  receive() external payable virtual {}

  /// ADMIN
  function addSwapper(address _swapper) external onlyOwner {
    allowedSwappers[_swapper] = true;
  }

  function removeSwapper(address _swapper) external onlyOwner {
    allowedSwappers[_swapper] = false;
  }

  /// EXTERNAL
  function exactSwap(
    address _swapper,
    uint256 _amountIn,
    address _fromAsset,
    bytes calldata _swapData // comes directly from API with swap data encoded
  ) public payable returns (uint256 amountOut) {
    require(allowedSwappers[_swapper], "!allowedSwapper");
    if (IERC20(_fromAsset).allowance(address(this), _swapper) < _amountIn) {
      TransferHelper.safeApprove(_fromAsset, _swapper, type(uint256).max);
    }
    amountOut = ISwapper(_swapper).swap(_swapper, _amountIn, _fromAsset, _swapData);
  }

  function directSwapperCall(
    address _swapper,
    bytes calldata swapData,
    uint256 value
  ) public payable returns (uint256) {
    bytes memory ret = _swapper.functionCallWithValue(swapData, value, "!directSwapperCallFailed");
    return abi.decode(ret, (uint256));
  }
}
