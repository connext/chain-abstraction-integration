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

  /// Mainnet Chain IDs
  uint32 public ARBITRUM_CHAIN_ID = 42161;
  uint32 public OPTIMISM_CHAIN_ID = 10;

  // Live Addresses
  address public CONNEXT_ARBITRUM = 0xEE9deC2712cCE65174B561151701Bf54b99C24C8;
  address public CONNEXT_OPTIMISM = 0x8f7492DE823025b4CfaAB1D34c58963F2af5DEDA;

  // Forks
  uint256 public arbitrumForkId;
  string ARBITRUM_DEFAULT_RPC = "https://arb1.arbitrum.io/rpc";
  uint256 public optimismForkId;
  string OPTIMISM_DEFAULT_RPC = "https://mainnet.optimism.io";

  /// Mock Addresses
  address public USER_CHAIN_A = address(bytes20(keccak256("USER_CHAIN_A")));
  address public USER_CHAIN_B = address(bytes20(keccak256("USER_CHAIN_B")));
  address public MOCK_CONNEXT = address(bytes20(keccak256("MOCK_CONNEXT")));
  address public MOCK_MEAN_FINANCE = address(bytes20(keccak256("MOCK_MEAN_FINANCE")));
  address public TokenA_ERC20 = address(bytes20(keccak256("TokenA_ERC20")));
  address public TokenB_ERC20 = address(bytes20(keccak256("TokenB_ERC20")));

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

  function getRpc(uint256 chainId) internal view returns (string memory) {
    string memory keyName;
    string memory defaultRpc;

    if (chainId == 1) {
      keyName = "MAINNET_RPC_URL";
      defaultRpc = "https://eth.llamarpc.com";
    } else if (chainId == 10) {
      keyName = "OPTIMISM_RPC_URL";
      defaultRpc = "https://mainnet.optimism.io";
    } else if (chainId == 42161) {
      keyName = "ARBITRUM_RPC_URL";
      defaultRpc = "https://arb1.arbitrum.io/rpc";
    }

    try vm.envString(keyName) {
      return vm.envString(keyName);
    } catch {
      return defaultRpc;
    }
  }
}
