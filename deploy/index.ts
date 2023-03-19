export const DEFAULT_ARGS: Record<number, any> = {
  // default to mimic optimism
  31337: {
    CONNEXT: "0x8f7492DE823025b4CfaAB1D34c58963F2af5DEDA",
    WETH: "0x4200000000000000000000000000000000000006", // Weth on Optimism
    USDC: "0x7F5c764cBc14f9669B88837ca1490cCa17c31607", // USDC on Optimism
    DOMAIN: "6648936", // Ethereum domain ID
  },
  // Optimism
  10: {
    CONNEXT: "0x8f7492DE823025b4CfaAB1D34c58963F2af5DEDA",
    WETH: "0x4200000000000000000000000000000000000006", // Weth on Optimism
    USDC: "0x7F5c764cBc14f9669B88837ca1490cCa17c31607", // USDC on Optimism
    DOMAIN: "6648936", // Ethereum domain ID
  },
  // Arbitrum
  42161: {
    CONNEXT: "0xEE9deC2712cCE65174B561151701Bf54b99C24C8", // Connext on Arbitrum
    WETH: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1", // Weth on Arbitrum
    USDC: "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8", // USDC on Arbitrum (donation asset)
    DOMAIN: "6648936", // Ethereum domain ID
  },
  // Polygon
  137: {
    CONNEXT: "0x11984dc4465481512eb5b777E44061C158CF2259", // Connext
    WETH: "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", // Weth
    USDC: "0x2791bca1f2de4661ed88a30c99a7a9449aa84174", // USDC
    DOMAIN: "1886350457", // Ethereum domain ID
  },
};
