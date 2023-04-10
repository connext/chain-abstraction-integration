import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "@nomiclabs/hardhat-ethers";
import "@nomicfoundation/hardhat-foundry";
import { HardhatUserConfig } from "hardhat/config";

const alchemyApiKey = process.env.ALCHEMY_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const MNEMONIC = process.env.MNEMONIC ?? "test test test test test test test test test test test junk";

function createConfig(network: string) {
  return {
    url: getNetworkUrl(network)!,
    accounts: !!PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : { mnemonic: MNEMONIC },
    // gasPrice: BigNumber.from(networkGasPriceConfig[network])
    //   .mul(1e9).toString(), // Update the mapping above
  };
}

function getNetworkUrl(networkType: string) {
  if (networkType === "polygon")
    return alchemyApiKey ? `https://polygon-mainnet.g.alchemy.com/v2/${alchemyApiKey}` : "https://rpc.ankr.com/polygon";
  else if (networkType === "arbitrum")
    return alchemyApiKey ? `https://arb-mainnet.g.alchemy.com/v2/${alchemyApiKey}` : "https://arb1.arbitrum.io/rpc";
  else if (networkType === "optimism")
    return alchemyApiKey ? `https://opt-mainnet.g.alchemy.com/v2/${alchemyApiKey}` : "https://mainnet.optimism.io";
  else if (networkType === "fantom") return `https://rpc.ftm.tools/`;
  else return alchemyApiKey ? `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKey}` : "https://cloudflare-eth.com";
}

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      viaIR: true,
    },
  },
  defaultNetwork: "hardhat",
  namedAccounts: {
    deployer: { default: 0 },
    alice: { default: 1 },
    bob: { default: 2 },
    rando: { default: 3 },
  },
  networks: {
    hardhat: {
      chainId: 31337,
      forking: {
        url: "https://mainnet.optimism.io",
        blockNumber: 73304256, // mined 09/02/2023
      },
    },
    mainnet: createConfig("mainnet"),
    polygon: createConfig("polygon"),
    arbitrum: createConfig("arbitrum"),
    optimism: createConfig("optimism"),
  },
  etherscan: {
    apiKey: {
      // mainnets
      polygon: String(process.env.POLYGONSCAN_API_KEY),
      optimism: String(process.env.OPTIMISM_API_KEY),
      arbitrum: String(process.env.ARBISCAN_API_KEY),
    },
  },
};

export default config;
