//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface InstaTargetAuthInterface {
    struct CastData {
        string[] _targetNames;
        bytes[] _datas;
        address _origin;
    }

    function verify(
        address auth,
        bytes memory signature,
        CastData memory castData
    ) external view returns (bool);

    function authCast(
        address dsaAddress,
        address auth,
        bytes memory signature,
        CastData memory castData
    ) external payable;
}
