// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "../dependencies/forge-std-1.11.0/src/Test.sol";

import { MockERC20 } from "./mocks/MockERC20.sol";
import { MinimalVault } from "../src/MinimalVault.sol";
import { MockStrategy } from "./mocks/MockStrategy.sol";

/* solhint-disable func-name-mixedcase, private-vars-leading-underscore */
contract MinimalVaultTest is Test {
    MockERC20 token;
    MinimalVault vault;
    MockStrategy stratA;
    MockStrategy stratB;

    address user = makeAddr("user");

    function setUp() public {
        // GIVEN a minimal ERC-4626 vault with a mock asset + a funded user
        token = new MockERC20("Mock USDRIF", "mUSDRIF");
        vault = new MinimalVault(token, "Demo Vault", "vDEMO");
        token.mint(user, 1_000e18);
        // ALTERNATIVE
        // deal(address(token), user, 1_000e18);
        

        // AND two strategies configured (we'll route by APY in the test)
        stratA = new MockStrategy(token, address(vault));
        stratB = new MockStrategy(token, address(vault));
        vault.addStrategy(stratA);
        vault.addStrategy(stratB);
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

