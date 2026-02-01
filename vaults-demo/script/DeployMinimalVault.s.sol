// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console2 } from "../dependencies/forge-std-1.11.0/src/Script.sol";

import { IERC20 } from "../dependencies/@openzeppelin-contracts-5.5.0/token/ERC20/IERC20.sol";
import { ERC1967Proxy } from "../dependencies/@openzeppelin-contracts-5.5.0/proxy/ERC1967/ERC1967Proxy.sol";

import { MinimalVault } from "../src/MinimalVault.sol";

contract DeployMinimalVault is Script {
    function run() external returns (MinimalVault vault) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        IERC20 asset = IERC20(vm.envAddress("ASSET"));
        string memory name = vm.envString("NAME");
        string memory symbol = vm.envString("SYMBOL");
        address owner = vm.envAddress("OWNER");

        vm.startBroadcast(privateKey);
        MinimalVault impl = new MinimalVault();
        ERC1967Proxy proxy =
            new ERC1967Proxy(address(impl), abi.encodeCall(MinimalVault.initialize, (asset, name, symbol, owner)));
        vm.stopBroadcast();

        vault = MinimalVault(address(proxy));

        console2.log("MinimalVault implementation", address(impl));
        console2.log("MinimalVault proxy (vault)", address(vault));
        console2.log("asset", address(asset));
        console2.log("owner", owner);
    }
}

