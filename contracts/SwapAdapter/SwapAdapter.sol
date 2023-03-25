//SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";
import {Swapper} from "./Swapper.sol";

/// TODO: Add custom TransferHelper for allowance and approve

contract SwapAdapter is Swapper {
    using Address for address;
    using Address for address payable;

    mapping(address => bool) public allowedSwappers;

    address public immutable UniswapSwapRouter =
        address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    constructor() {
        allowedSwappers[address(this)] = true;
        allowedSwappers[UniswapSwapRouter] = true;
    }

    /// Payable
    receive() external payable virtual {}

    function _exactSwap(
        address swapper,
        bytes4 _selector,
        bytes calldata _swapData
    ) external payable {
        require(allowedSwappers[swapper], "!allowedSwapper");
        /// TODO: check for allowance for swapper address.

        (bool success, bytes memory data) = address(this).call{
            value: msg.value
        }(abi.encodeWithSelector(_selector, swapper, _swapData));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "!exactSwap"
        );
    }

    function _directSwapperCall(
        address _swapper,
        bytes calldata _swapData,
        uint256 value
    ) internal virtual {
        _swapper.functionCallWithValue(_swapData, value);
    }
}
