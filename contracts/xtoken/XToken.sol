// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20PermitUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {ProposedOwnableUpgradeable} from "../shared/ownership/ProposedOwnableUpgradeable.sol";

contract ConnextXERC20 is ERC20PermitUpgradeable, ProposedOwnableUpgradeable {
  // ======== Events =========
  /**
   * Emitted when bridge is whitelisted
   * @param bridge Address of the bridge being added
   */
  event BridgeAdded(address indexed bridge);

  /**
   * Emitted when bridge is dropped from whitelist
   * @param bridge Address of the bridge being added
   */
  event BridgeRemoved(address indexed bridge);

  // ======== Constants =========
  uint256 public immutable TRANSFER_START;

  // ======== Storage =========
  /**
   * @notice The set of whitelisted bridges
   */
  mapping(address => bool) internal _whitelistedBridges;

  // ======== Constructor =========
  constructor(uint256 _start) {
    TRANSFER_START = _start;
  }

  // ======== Initializer =========

  function initialize(address _owner) public initializer {
    __ConnextXERC20_init();
    __ERC20_init("xConnext", "xNEXT");
    __ERC20Permit_init("xConnext");
    __ProposedOwnable_init();

    // Set specified owner
    _setOwner(_owner);
  }

  /**
   * @dev Initializes ConnextXERC20 instance
   */
  function __ConnextXERC20_init() internal onlyInitializing {
    __ConnextXERC20_init_unchained();
  }

  function __ConnextXERC20_init_unchained() internal onlyInitializing {}

  // ======== Errors =========
  error ConnextXERC20__onlyBridge_notBridge();
  error ConnextXERC20__onlyBridgeBeforeStart_notBridge();
  error ConnextXERC20__addBridge_alreadyAdded();
  error ConnextXERC20__removeBridge_alreadyRemoved();

  // ============ Modifiers ==============
  modifier onlyBridge() {
    if (!_whitelistedBridges[msg.sender]) {
      revert ConnextXERC20__onlyBridge_notBridge();
    }
    _;
  }

  modifier onlyBridgeBeforeStart() {
    if (block.timestamp <= TRANSFER_START && !_whitelistedBridges[msg.sender]) {
      revert ConnextXERC20__onlyBridgeBeforeStart_notBridge();
    }
    _;
  }

  // ========= Admin Functions =========
  /**
   * @notice Adds a bridge to the whitelist
   * @param _bridge Address of the bridge to add
   */
  function addBridge(address _bridge) external onlyOwner {
    if (_whitelistedBridges[_bridge]) {
      revert ConnextXERC20__addBridge_alreadyAdded();
    }
    emit BridgeAdded(_bridge);
    _whitelistedBridges[_bridge] = true;
  }

  /**
   * @notice Removes a bridge from the whitelist
   * @param _bridge Address of the bridge to remove
   */
  function removeBridge(address _bridge) external onlyOwner {
    if (!_whitelistedBridges[_bridge]) {
      revert ConnextXERC20__removeBridge_alreadyRemoved();
    }
    emit BridgeRemoved(_bridge);
    _whitelistedBridges[_bridge] = false;
  }

  // ========= Public Functions =========

  /**
   * @notice Mints tokens for a given address
   * @param _to Address to mint to
   * @param _amount Amount to mint
   */
  function mint(address _to, uint256 _amount) public onlyBridge {
    _mint(_to, _amount);
  }

  /**
   * @notice Mints tokens for a given address
   * @param _from Address to burn from
   * @param _amount Amount to mint
   */
  function burn(address _from, uint256 _amount) public onlyBridge {
    _burn(_from, _amount);
  }

  function transfer(address recipient, uint256 amount) public virtual override onlyBridgeBeforeStart returns (bool) {
    return super.transfer(recipient, amount);
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override onlyBridgeBeforeStart returns (bool) {
    return super.transferFrom(from, to, amount);
  }

  // ============ Upgrade Gap ============
  uint256[49] private __GAP; // gap for upgrade safety
}
