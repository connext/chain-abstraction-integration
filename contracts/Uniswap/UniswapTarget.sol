// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {UniswapAdapter} from "./UniswapAdapter.sol";

// import {IWeth} from "./interfaces/IWeth.sol";

contract UniswapTarget is UniswapAdapter {
    // The Connext contract on this domain
    IConnext public immutable connext;

    /// Modifier
    modifier onlyConnext() {
        require(msg.sender == address(connext), "Caller must be Connext");
        _;
    }

    constructor(address _connext) {
        connext = IConnext(_connext);
    }

    function xReceive(
        bytes32 _transferId,
        uint256 _amount, // Final Amount receive via Connext(After AMM calculation)
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes memory _callData
    ) external onlyConnext returns (bytes memory) {
        // Decode calldata
        // Aggregator Swap (ideally only works if we don't sign on quote)
        // Final Amount after the swap
        // if we do aggregator swap need better way to compare for slippage.
        /// Sanity check for the Slippage _amount vs params._amount(Input at Origin)
        // fallback transfer amount to user address(params.owner)
        // deposit
    }
}
