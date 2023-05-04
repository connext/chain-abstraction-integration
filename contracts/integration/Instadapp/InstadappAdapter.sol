// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import {IDSA} from "./interfaces/IDSA.sol";
import "forge-std/console.sol";

/// @title InstadappAdapter
/// @author Connext
/// @notice This contract is inherited by InstadappTarget, it includes the logic to verify signatures
/// and execute the calls.
/// @dev This contract is not meant to be used directly, it is meant to be inherited by other contracts.
/// @custom:experimental This is an experimental contract.
contract InstadappAdapter is EIP712 {
  /// Structs
  /// @dev This struct is used to encode the data for InstadappTarget.cast function.
  /// @param targetNames The names of the targets that will be called.
  /// @param datas The data that will be sent to the targets.
  /// @param origin The address that will be used as the origin of the call.
  struct CastData {
    string[] targetNames;
    bytes[] datas;
    address origin;
  }

  /// @dev This struct is used to encode the data that is signed by the auth address.
  /// The signature is then verified by the verify function.
  struct Sig {
    CastData castData;
    bytes32 salt;
    uint256 deadline;
  }

  /// Storage
  /// @dev This mapping is used to prevent replay attacks.
  mapping(bytes32 => bool) private sigReplayProtection;

  /// Constants
  /// @dev This is the typehash for the CastData struct.
  bytes32 public constant CASTDATA_TYPEHASH = keccak256("CastData(string[] targetNames,bytes[] datas,address origin)");

  /// @dev This is the typehash for the Sig struct.
  bytes32 public constant SIG_TYPEHASH =
    keccak256(
      "Sig(CastData cast,bytes32 salt,uint256 deadline)CastData(string[] targetNames,bytes[] datas,address origin)"
    );

  /// Constructor
  constructor() EIP712("InstaTargetAuth", "1") {}

  /// Internal functions
  /// @dev This function is used to forward the call to dsa.cast function.
  /// Cast the call is forwarded, the signature is verified and the salt is stored in the sigReplayProtection mapping.
  /// @param dsaAddress The address of the DSA.
  /// @param auth The address of the auth.
  /// @param signature The signature by the auth. This signature is used to verify the SIG data.
  /// @param castData The data that will be sent to the targets.
  /// @param salt The salt that will be used to prevent replay attacks.
  /// @param deadline The deadline that will be used to prevent replay attacks.
  function authCast(
    address dsaAddress,
    address auth,
    bytes memory signature,
    CastData memory castData,
    bytes32 salt,
    uint256 deadline
  ) internal {
    IDSA dsa = IDSA(dsaAddress);
    // check if Auth is valid, and included in the DSA
    require(auth != address(0) && dsa.isAuth(auth), "Invalid Auth");

    // check if signature is not replayed
    require(!sigReplayProtection[salt], "Replay Attack");

    // check if signature is not expired
    require(block.timestamp < deadline, "Signature Expired");

    // check if signature is valid, and not replayed
    require(verify(auth, signature, castData, salt, deadline), "Invalid signature");

    // Signature Replay Protection
    sigReplayProtection[salt] = true;

    // Cast the call
    dsa.cast(castData.targetNames, castData.datas, castData.origin);
  }

  /// @dev This function is used to verify the signature.
  /// @param auth The address of the auth.
  /// @param signature The signature of the auth.
  /// @param castData The data that will be sent to the targets.
  /// @param salt The salt that will be used to prevent replay attacks.
  /// @param deadline The deadline that will be used to prevent replay attacks.
  /// @return boolean that indicates if the signature is valid.
  function verify(
    address auth,
    bytes memory signature,
    CastData memory castData,
    bytes32 salt,
    uint256 deadline
  ) internal view returns (bool) {
    bytes32 digest = getDigest(castData, salt, deadline);
    address signer = ECDSA.recover(digest, signature);
    return signer == auth;
  }

  function getDigest(CastData memory castData, bytes32 salt, uint256 deadline) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(SIG_TYPEHASH, getHash(castData), salt, deadline)));
  }

  /// @dev This function is used to hash the CastData struct.
  /// @param castData The data that will be sent to the targets.
  /// @return bytes32 that is the hash of the CastData struct.
  function getHash(CastData memory castData) internal pure returns (bytes32) {
    return keccak256(abi.encode(CASTDATA_TYPEHASH, castData.targetNames, castData.datas, castData.origin));
  }
}
