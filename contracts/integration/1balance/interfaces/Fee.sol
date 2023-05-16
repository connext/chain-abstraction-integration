// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Fee {
    address token;
    uint256 amount;
    uint256 totalValidRequestedWithdrawAmount;
    bytes32[] merkleProof;
}