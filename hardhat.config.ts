import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "@nomiclabs/hardhat-ethers";
import { config as envConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import { BigNumber } from "ethers";

envConfig();

const chainIds = {
  ganache: 1337,
  hardhat: 31337,
  mainnet: 1,
  avalanche: 43114,
  polygon: 137,
  arbitrum: 42161,
  optimism: 10,
  fantom: 250,
};

const alchemyApiKey = process.env.ALCHEMY_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const MNEMONIC =
  process.env.MNEMONIC ??
  "test test test test test test test test test test test junk";

const networkGasPriceConfig: Record<string, number> = {
  mainnet: 100,
  polygon: 50,
  avalanche: 40,
  arbitrum: 1,
  optimism: 0.001,
  fantom: 210,
};

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
    return alchemyApiKey
      ? `https://polygon-mainnet.g.alchemy.com/v2/${alchemyApiKey}`
      : "https://rpc.ankr.com/polygon";
  else if (networkType === "arbitrum")
    return alchemyApiKey
      ? `https://arb-mainnet.g.alchemy.com/v2/${alchemyApiKey}`
      : "https://arb1.arbitrum.io/rpc";
  else if (networkType === "optimism")
    return alchemyApiKey
      ? `https://opt-mainnet.g.alchemy.com/v2/${alchemyApiKey}`
      : "https://mainnet.optimism.io";
  else if (networkType === "fantom") return `https://rpc.ftm.tools/`;
  else
    return alchemyApiKey
      ? `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKey}`
      : "https://cloudflare-eth.com";
}

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
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
      polygon: process.env.POLYGONSCAN_API_KEY!,
      optimisticEthereum: process.env.OPTIMISM_ETHERSCAN_API_KEY!,
      arbitrumOne: process.env.ARBISCAN_API_KEY!,
    },
  },
};

export default config;
