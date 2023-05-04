import { ethers, Wallet } from "ethers";
import {
  defaultAbiCoder,
  joinSignature,
  keccak256,
  solidityKeccak256,
  _TypedDataEncoder,
  toUtf8Bytes,
  hexlify,
  hexZeroPad,
} from "ethers/lib/utils";

const CASTDATA_TYPEHASH = keccak256(toUtf8Bytes("CastData(string[] targetNames,bytes[] datas,address origin)"));
const SIG_TYPEHASH = keccak256(
  toUtf8Bytes(
    "Sig(CastData cast,bytes32 salt,uint256 deadline)CastData(string[] targetNames,bytes[] datas,address origin)",
  ),
);

type EIP712Domain = {
  name: string;
  version: string;
  chainId: number;
  verifyingContract: string;
};

type CastData = {
  targetNames: string[];
  datas: Uint8Array[];
  origin: string;
};

export const generateEIP712Signature = (domain: EIP712Domain, structHash: string, signer: Wallet): string => {
  const domainSeparator = _TypedDataEncoder.hashDomain(domain);

  const digest = solidityKeccak256(
    ["string", "bytes32", "bytes32"],
    ["\x19\x01", domainSeparator, keccak256(structHash)],
  );
  const signingKey = signer._signingKey();
  const signature = signingKey.signDigest(digest);
  const joinedSignature = joinSignature(signature);
  return joinedSignature;
};

const generateSignature = async (
  sender: Wallet,
  domain: EIP712Domain,
  castData: CastData,
  salt: string,
  deadline: string,
): Promise<string> => {
  const encodedData = defaultAbiCoder.encode(
    ["bytes32", "string[]", "bytes[]", "address"],
    [CASTDATA_TYPEHASH, castData.targetNames, castData.datas, castData.origin],
  );
  const structHash = defaultAbiCoder.encode(
    ["bytes32", "bytes32", "bytes32", "uint256"],
    [SIG_TYPEHASH, keccak256(encodedData), salt, deadline],
  );

  const signature = generateEIP712Signature(domain, structHash, sender);
  return signature;
};

export const main = async () => {
  const TEST_PRIIVATE_KEY = "913b591c8abc30e7d3d2a4ebd560e1f02197cb701f077c9fcdc2ba8b0a7d9abe"; // address = 0xc1aAED5D41a3c3c33B1978EA55916f9A3EE1B397
  const sender = new ethers.Wallet(TEST_PRIIVATE_KEY);
  const authContractAddress = "0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f";

  const domain = {
    name: "InstaTargetAuth",
    version: "1",
    chainId: 31337,
    verifyingContract: authContractAddress,
  };

  const castData = {
    targetNames: ["target111", "target222", "target333"],
    datas: [toUtf8Bytes("0x111"), toUtf8Bytes("0x222"), toUtf8Bytes("0x333")],
    origin: sender.address.toLowerCase(),
  };

  const salt = hexZeroPad(hexlify(1), 32);
  const signature = await generateSignature(sender, domain, castData, salt, "100");
  console.log({ signature });
};

main();
