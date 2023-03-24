import { expect } from "chai";
import { ethers } from "hardhat";
import instaIndexABI from "../helpers/abis/instaindex.json";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Hardcoded addresses on optimism
const instaIndexAddr = "0x6CE3e607C808b4f4C26B7F6aDAeB619e49CAbb25";

const deployDSAv2 = async (owner: any) => {
  const instaIndex = await ethers.getContractAt(instaIndexABI, instaIndexAddr);
  const tx = await instaIndex.build(owner, 2, owner);
  const receipt = await tx.wait();

  const event = receipt.events.find(
    (a: { event: string }) => a.event === "LogAccountCreated"
  );
  return await ethers.getContractAt(instaIndexABI, event.args.account);  
}

const deployInstaTargetAuth = async (dsaAddress: string) => {
  const instaTagetAuthFactory = await ethers.getContractFactory("InstaTargetAuth");
  const contractInstance = await instaTagetAuthFactory.deploy(dsaAddress);
  await contractInstance.deployed();
  return contractInstance
}

const generateSignature = async (signer: SignerWithAddress, domain: any, types: any, castData: any): Promise<string> => {
  const domainSeparator = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(
    ['bytes32','bytes32','bytes32','uint256','address'],
    [ ethers.utils.keccak256(
        ethers.utils.toUtf8Bytes('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
      ),
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes(domain.name)),
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes(domain.version)),
      domain.chainId,
      domain.verifyingContract
    ]))

    const messageHash = ethers.utils.keccak256(
      ethers.utils.solidityPack(
        ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
        ['0x19', '0x01', domainSeparator, ethers.utils.keccak256(ethers.utils.solidityPack(types.CastData, castData))]
      )
    );
    const signedMessage = await signer.signMessage(ethers.utils.arrayify(messageHash));
    return signedMessage;
}

describe.only("InstaTargetAuth", () => {

  let owner: any, otherAccount: any;
  let dsaContract: any;
  let instaTargetAuthContract: any

  before(async () => {
    [owner, otherAccount] = await ethers.getSigners();
    dsaContract = await deployDSAv2(owner);
    instaTargetAuthContract = await deployInstaTargetAuth(dsaContract.address);
  })
  describe("#verify",  () => {
    it("happy: should verify successfully", async () => {
    
      const domain = {
        name: "InstaTargetAuth",
        version: "1",
        chainId: 31337,
        verifyingContract: instaTargetAuthContract.address
      };
      const types = {
        CastData: [
          { name: "_targetNames", type: "string[]" },
          { name: "_datas", type: "bytes[]" },
          { name: "_origin", type: "address" },
        ],
      };

      const sender = await otherAccount.getAddress();
      const castData = {
        _targetNames: ["target1", "target2"],
        _datas: [
          ethers.utils.hexlify([1, 2, 3]),
          ethers.utils.hexlify([4, 5, 6]),
        ],
        _origin: sender,
      };      

      const signature = await generateSignature(otherAccount, domain, types, castData);
      const verified = await instaTargetAuthContract.connect(otherAccount).verify(signature, sender, castData);
      expect(verified).to.be.true;
    });

    it("should return false if signature is invalid", async () => {})
  });

  describe("#authCast", () => {
    it("should revert if verification fails", async () => {})
    it("happy: should work", async () => {})
  })
});
