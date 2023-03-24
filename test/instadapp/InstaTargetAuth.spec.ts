import { expect } from "chai";
import { ethers } from "hardhat";
import instaIndexABI from "../helpers/abis/instaindex.json";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";
import { defaultAbiCoder, formatBytes32String, keccak256, solidityKeccak256, toUtf8Bytes, verifyMessage, verifyTypedData } from "ethers/lib/utils";
import { hashTypedMessage } from "@connext/utils";


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

describe.skip("InstaTargetAuth", () => {

  let owner: SignerWithAddress, otherAccount: SignerWithAddress;
  let dsaContract: Contract;
  let instaTargetAuthContract: any

  before(async () => {
    [owner, otherAccount] = await ethers.getSigners();
    dsaContract = await deployDSAv2(owner.address);
    instaTargetAuthContract = await deployInstaTargetAuth(dsaContract.address);
  })
  describe("#verify",  () => {
    it("happy: should verify successfully", async () => {
      const sender = await otherAccount.getAddress();
      const ownerAddress = await owner.getAddress();

      const authContractAddress = instaTargetAuthContract.address.toLowerCase();
      const domain = {
        name: "InstaTargetAuth",
        version: "1",
        chainId: 31337,
        verifyingContract: authContractAddress
      };
      const types = {
        CastData: [
          { name: "_targetNames", type: "string[]" },
          { name: "_datas", type: "bytes[]" },
          { name: "_origin", type: "address" },
        ],
      };

      const castData = {
        "_targetNames": ["target111", "target222"],
        "_datas": [ toUtf8Bytes('0x0102013'), toUtf8Bytes('0x040506')],
        "_origin": sender.toLowerCase(),
      };     

      const signature = await otherAccount._signTypedData(domain, types, castData);
      // Verify the signature
      const recoverAddress = verifyTypedData(domain, types, castData, signature);
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
