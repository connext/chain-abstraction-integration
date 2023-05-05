// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

contract TestHelper is Test {
  /// Testnet Domain IDs
  uint32 public GOERLI_DOMAIN_ID = 1735353714;
  uint32 public OPTIMISM_GOERLI_DOMAIN_ID = 1735356532;
  uint32 public ARBITRUM_GOERLI_DOMAIN_ID = 1734439522;
  uint32 public POLYGON_MUMBAI_DOMAIN_ID = 9991;

  /// Testnet Chain IDs
  uint32 public GOERLI_CHAIN_ID = 5;
  uint32 public OPTIMISM_GOERLI_CHAIN_ID = 420;
  uint32 public ARBITRUM_GOERLI_CHAIN_ID = 421613;
  uint32 public POLYGON_MUMBAI_CHAIN_ID = 80001;

  /// Mainnet Domain IDs
  uint32 public ARBITRUM_DOMAIN_ID = 1634886255;
  uint32 public OPTIMISM_DOMAIN_ID = 1869640809;
  uint32 public BNB_DOMAIN_ID = 6450786;
  uint32 public POLYGON_DOMAIN_ID = 1886350457;

  /// Mainnet Chain IDs
  uint32 public ARBITRUM_CHAIN_ID = 42161;
  uint32 public OPTIMISM_CHAIN_ID = 10;

  // Live Addresses
  address public CONNEXT_ARBITRUM = 0xEE9deC2712cCE65174B561151701Bf54b99C24C8;
  address public CONNEXT_OPTIMISM = 0x8f7492DE823025b4CfaAB1D34c58963F2af5DEDA;
  address public CONNEXT_BNB = 0xCd401c10afa37d641d2F594852DA94C700e4F2CE;
  address public CONNEXT_POLYGON = 0x11984dc4465481512eb5b777E44061C158CF2259;

  // Forks
  uint256 public arbitrumForkId;
  uint256 public optimismForkId;
  uint256 public bnbForkId;
  uint256 public polygonForkId;

  /// Mock Addresses
  address public USER_CHAIN_A = address(bytes20(keccak256("USER_CHAIN_A")));
  address public USER_CHAIN_B = address(bytes20(keccak256("USER_CHAIN_B")));
  address public MOCK_CONNEXT = address(bytes20(keccak256("MOCK_CONNEXT")));
  address public MOCK_MEAN_FINANCE = address(bytes20(keccak256("MOCK_MEAN_FINANCE")));
  address public TokenA_ERC20 = address(bytes20(keccak256("TokenA_ERC20")));
  address public TokenB_ERC20 = address(bytes20(keccak256("TokenB_ERC20")));

  // OneInch Aggregator constants
  uint256 public constant ONE_FOR_ZERO_MASK = 1 << 255;

  function setUp() public virtual {
    vm.label(MOCK_CONNEXT, "Mock Connext");
    vm.label(MOCK_MEAN_FINANCE, "Mock Mean Finance");
    vm.label(TokenA_ERC20, "TokenA_ERC20");
    vm.label(TokenB_ERC20, "TokenB_ERC20");
    vm.label(USER_CHAIN_A, "User Chain A");
    vm.label(USER_CHAIN_B, "User Chain B");
  }

  function setUpArbitrum(uint256 blockNumber) public {
    arbitrumForkId = vm.createSelectFork(getRpc(42161), blockNumber);
    vm.label(CONNEXT_ARBITRUM, "Connext Arbitrum");
  }

  function setUpOptimism(uint256 blockNumber) public {
    optimismForkId = vm.createSelectFork(getRpc(10), blockNumber);
    vm.label(CONNEXT_OPTIMISM, "Connext Optimism");
  }

  function setUpBNB(uint256 blockNumber) public {
    bnbForkId = vm.createSelectFork(getRpc(56), blockNumber);
    vm.label(CONNEXT_BNB, "Connext BNB");
  }

  function setUpPolygon(uint256 blockNumber) public {
    polygonForkId = vm.createSelectFork(getRpc(137), blockNumber);
    vm.label(CONNEXT_POLYGON, "Connext Polygon");
  }

  function getRpc(uint256 chainId) internal view returns (string memory) {
    string memory keyName;
    string memory defaultRpc;

    if (chainId == 1) {
      keyName = "MAINNET_RPC_URL";
      defaultRpc = "https://eth-mainnet.g.alchemy.com/v2/rN1fkDW9_vMmLhRj5dyVXV26k6lXZoGr";
    } else if (chainId == 10) {
      keyName = "OPTIMISM_RPC_URL";
      defaultRpc = "https://opt-mainnet.g.alchemy.com/v2/Kpix_PNmfxTUGWJ3xTpvGieSm3VN_5za";
    } else if (chainId == 42161) {
      keyName = "ARBITRUM_RPC_URL";
      defaultRpc = "https://arb-mainnet.g.alchemy.com/v2/E2B_nYYEybuSsvjrBwKKXGPzAt8NxjE0";
    } else if (chainId == 56) {
      keyName = "BNB_RPC_URL";
      defaultRpc = "https://bsc-dataseed.binance.org";
    } else if (chainId == 137) {
      keyName = "POLYGON_RPC_URL";
      defaultRpc = "https://polygon-mainnet.g.alchemy.com/v2/0xcCQA06LTzwAiRM5B9qHGs6X958x0oF";
    }

    try vm.envString(keyName) {
      return vm.envString(keyName);
    } catch {
      return defaultRpc;
    }
  }
}
