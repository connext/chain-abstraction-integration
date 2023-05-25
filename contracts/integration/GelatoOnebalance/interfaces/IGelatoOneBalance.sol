// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Fee} from "./Fee.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGelatoOneBalance {
    /// EVENTS
    event LogDeposit(
        bytes32 indexed root,
        address indexed sponsor,
        address indexed token,
        uint256 amount
    );

    event LogRequestWithdrawal(
        bytes32 indexed root,
        address indexed sponsor,
        address indexed token,
        uint256 withdrawalAmount
    );

    event LogCancelWithdrawalRequest(
        bytes32 indexed root,
        address indexed sponsor,
        address indexed feeToken,
        uint256 cancelledAmount
    );

    event LogSponsorWithdrawal(
        bytes32 indexed root,
        address indexed sponsor,
        address indexed token,
        uint256 amount
    );

    event LogAddManager(address indexed _manager);

    event LogRemoveManager(address indexed _manager);

    event LogAddToken(address indexed _token);

    event LogRemoveToken(address indexed _token);

    event LogSettlement(bytes32 indexed root, address indexed manager);

    event LogCollectFee(
        bytes32 indexed root,
        address indexed feeCollector,
        address indexed token,
        uint256 amount
    );

    /// EXTERNAL FUNCTIONS
    function depositNative(address _sponsor) external payable;

    function depositToken(
        address _sponsor,
        IERC20 _token,
        uint256 _amount
    ) external;

    function depositTokenWithPermit(
        address _sponsor,
        address _token,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function depositDaiWithPermit(
        address _sponsor,
        address _token,
        uint256 _amount,
        uint256 _nonce,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function requestWithdrawal(address _token, uint256 _desiredAmount) external;

    function cancelWithdrawalRequest(
        address _token,
        uint256 _cancelledAmount,
        uint256 _totalValidRequestedWithdrawAmount,
        bytes32[] calldata _merkleProof
    ) external;

    function withdraw(
        address _token,
        uint256 _amount,
        uint256 _totalValidRequestedWithdrawAmount,
        bytes32[] calldata _merkleProof
    ) external;

    function addManager(address _manager) external;

    function removeManager(address _manager) external;

    function addToken(address _token) external;

    function removeToken(address _token) external;

    function settle(bytes32 _root, bytes32 _newRoot) external;

    function settleWithSignature(
        bytes32 _newRoot,
        bytes calldata _managerSignature
    ) external;

    function collectFees(Fee[] calldata _fees) external;

    function collectFeesWithSignature(
        Fee[] calldata _fees,
        bytes calldata _managerSignature
    ) external;

    /// VIEW FUNCTIONS
    function managers() external view returns (address[] memory);

    function tokens() external view returns (address[] memory);
}