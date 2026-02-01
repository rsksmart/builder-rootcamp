// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console2 } from "../dependencies/forge-std-1.11.0/src/Script.sol";

import { MinimalVault } from "../src/MinimalVault.sol";

/// @notice UUPS upgrade script for MinimalVault (ERC1967Proxy).
/// @dev Requires the broadcaster to have UPGRADER_ROLE on the vault.
contract UpgradeMinimalVault is Script {
    // keccak256("eip1967.proxy.implementation") - 1
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function run() external returns (address newImplementation) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address proxy = vm.envAddress("PROXY");

        console2.log("proxy", proxy);

        vm.startBroadcast(privateKey);
        MinimalVault impl = new MinimalVault();
        newImplementation = address(impl);

        // Call UUPS upgrade function THROUGH the proxy.
        MinimalVault(proxy).upgradeToAndCall(newImplementation, "");
        vm.stopBroadcast();

        console2.log("new implementation", newImplementation);
        address implAfter = _readImplementation(proxy);
        console2.log("implementation after upgrade", implAfter);
        require(implAfter == newImplementation, "upgrade failed");
    }

    function _readImplementation(address proxy) internal view returns (address impl) {
        bytes32 slot = vm.load(proxy, _IMPLEMENTATION_SLOT);
        impl = address(uint160(uint256(slot)));
    }
}

