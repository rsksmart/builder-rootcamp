// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "../dependencies/forge-std-1.11.0/src/Test.sol";

import { MockERC20 } from "./mocks/MockERC20.sol";
import { MinimalVault } from "../src/MinimalVault.sol";
import { MockStrategy } from "./mocks/MockStrategy.sol";
import { ERC1967Proxy } from "../dependencies/@openzeppelin-contracts-5.5.0/proxy/ERC1967/ERC1967Proxy.sol";

/* solhint-disable func-name-mixedcase, private-vars-leading-underscore */
contract MinimalVaultTest is Test {
    MockERC20 token;
    MinimalVault vault;
    MockStrategy stratA;
    MockStrategy stratB;

    address user = makeAddr("user");
    address attacker = makeAddr("attacker");

    bytes4 private constant _ACCESS_CONTROL_UNAUTHORIZED_SELECTOR =
        bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)"));

    function setUp() public {
        // GIVEN a minimal ERC-4626 vault with a mock asset + a funded user
        token = new MockERC20("Mock USDRIF", "mUSDRIF");
        MinimalVault impl = new MinimalVault();
        ERC1967Proxy proxy =
            new ERC1967Proxy(address(impl), abi.encodeCall(MinimalVault.initialize, (token, "Demo Vault", "vDEMO", address(this))));
        vault = MinimalVault(address(proxy));
        token.mint(user, 1_000e18);
        // ALTERNATIVE
        // deal(address(token), user, 1_000e18);
        

        // AND two strategies configured (we'll route by APY in the test)
        stratA = new MockStrategy(token, address(vault));
        stratB = new MockStrategy(token, address(vault));
        vault.addStrategy(stratA);
        vault.addStrategy(stratB);
    }

    function test_Roles_AdminAndUpgrader() public {
        // GIVEN a strategy a non-admin will try to add
        MockStrategy stratC = new MockStrategy(token, address(vault));

        // THEN non-admin cannot add strategies
        vm.expectRevert(
            abi.encodeWithSelector(_ACCESS_CONTROL_UNAUTHORIZED_SELECTOR, attacker, bytes32(0)) // DEFAULT_ADMIN_ROLE
        );
        vm.prank(attacker);
        vault.addStrategy(stratC);

        // THEN non-admin cannot remove strategies either
        vm.expectRevert(
            abi.encodeWithSelector(_ACCESS_CONTROL_UNAUTHORIZED_SELECTOR, attacker, bytes32(0)) // DEFAULT_ADMIN_ROLE
        );
        vm.prank(attacker);
        vault.removeStrategy(stratA);

        // THEN non-upgrader cannot upgrade
        MinimalVault newImpl = new MinimalVault();
        vm.expectRevert(
            abi.encodeWithSelector(_ACCESS_CONTROL_UNAUTHORIZED_SELECTOR, attacker, vault.UPGRADER_ROLE())
        );
        vm.prank(attacker);
        vault.upgradeToAndCall(address(newImpl), "");

        // AND upgrader (admin in this demo) can upgrade
        vault.upgradeToAndCall(address(newImpl), "");
    }

    function test_Rebalance_DeploysIdleFundsToHighestApy() public {
        uint256 amount = 100e18;

        // GIVEN stratB has higher APY
        stratA.setApy(100);
        stratB.setApy(200);

        // WHEN user deposits (funds stay idle; no auto-deploy)
        vm.startPrank(user);
        token.approve(address(vault), amount);
        vault.deposit(amount, user);
        vm.stopPrank();

        // THEN assets stay idle in the vault
        assertEq(token.balanceOf(address(vault)), amount);
        assertEq(token.balanceOf(address(stratA)), 0);
        assertEq(token.balanceOf(address(stratB)), 0);

        // WHEN rebalance is called
        vault.rebalance();

        // THEN idle funds are deployed to the highest APY strategy (stratB)
        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(address(stratA)), 0);
        assertEq(token.balanceOf(address(stratB)), amount);
        assertEq(stratB.depositCalls(), 1);
        assertEq(stratA.depositCalls(), 0);
    }
}

