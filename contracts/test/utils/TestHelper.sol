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

  function getRpc(uint256 chainId) internal view returns (string memory) {
    if (chainId == 1) {
      return "https://eth.llamarpc.com";
    } else if (chainId == 42161) {
      return "https://arb1.arbitrum.io/rpc";
    }

    return vm.envString("RPC_URL");
  }
}
