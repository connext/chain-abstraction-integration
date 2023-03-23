//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface InstaTargetAuthInterface {
    struct CastData {
        string[] _targetNames;
        bytes[] _datas;
        address _origin;
    }

    function verify(
        bytes memory signature,
        address sender,
        CastData memory castData
    ) external view returns (bool);

    function authCast(
        bytes memory signature,
        address sender,
        CastData memory castData
    ) external payable;
}
