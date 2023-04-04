// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {UniswapV3ForwarderXReceiver} from "../Uniswap/UniswapV3ForwarderXReceiver.sol";

interface IGreeter {
    function greetWithTokens(
        address _token,
        uint256 _amount,
        string calldata _greeting
    ) external view returns (string memory);
}

contract XSwapAndGreet is UniswapV3ForwarderXReceiver {
    IGreeter public immutable greeter;

    constructor(
        address _greeter,
        address _connext,
        address _uniswapSwapRouter
    ) UniswapV3ForwarderXReceiver(_connext, _uniswapSwapRouter) {
        greeter = IGreeter(_greeter);
    }

    /// INTERNAL
    function _forwardFunctionCall(
        bytes memory _preparedData,
        bytes32 /*_transferId*/,
        uint256 /*_amount*/,
        address /*_asset*/
    ) internal override returns (bool) {
        (uint256 amountOut, address toAsset, bytes memory forwardCallData) = abi
            .decode(_preparedData, (uint256, address, bytes));

        // Decode calldata
        string memory greeting = abi.decode(forwardCallData, (string));

        // Forward the call
        TransferHelper.safeApprove(toAsset, address(greeter), amountOut);
        greeter.greetWithTokens(toAsset, amountOut, greeting);
        return true;
    }
}
