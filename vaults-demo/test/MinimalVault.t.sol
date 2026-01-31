// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "../dependencies/forge-std-1.11.0/src/Test.sol";

import { MockERC20 } from "./mocks/MockERC20.sol";
import { MinimalVault } from "../src/MinimalVault.sol";
import { MockStrategy } from "./mocks/MockStrategy.sol";

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

    function test_Routing_DepositToHighestApy_WithdrawFromLowestApy() public {
        uint256 amount = 100e18;

        // GIVEN stratB has higher APY
        stratA.setApy(100);
        stratB.setApy(200);

        // WHEN user deposits (should go to stratB)
        vm.startPrank(user);
        token.approve(address(vault), 2 * amount);
        uint256 shares1 = vault.deposit(amount, user);
        vm.stopPrank();

        // THEN assets are deployed into the highest APY strategy
        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(address(stratA)), 0);
        assertEq(token.balanceOf(address(stratB)), amount);
        assertEq(vault.totalAssets(), amount);

        // GIVEN APYs flip: stratA becomes higher, stratB becomes lower
        stratA.setApy(300);
        stratB.setApy(100);

        // WHEN user deposits again (should go to stratA)
        vm.prank(user);
        uint256 shares2 = vault.deposit(amount, user);

        // THEN each strategy holds the deposit that was routed to it
        assertEq(token.balanceOf(address(stratA)), amount);
        assertEq(token.balanceOf(address(stratB)), amount);
        assertEq(vault.totalAssets(), 2 * amount);

        // WHEN user withdraws an amount that can be satisfied by the lowest APY strategy only
        // (lowest APY is stratB with amount balance)
        vm.prank(user);
        uint256 sharesBurned = vault.withdraw(amount / 2, user, user);

        // THEN the lowest APY strategy is used and the higher APY one is untouched
        assertEq(stratB.withdrawCalls(), 1);
        assertEq(stratA.withdrawCalls(), 0);
        assertEq(token.balanceOf(user), 1_000e18 - (2 * amount) + (amount / 2));

        // WHEN user redeems the remaining shares
        vm.prank(user);
        uint256 assetsOut = vault.redeem(shares1 + shares2 - sharesBurned, user, user);

        // THEN all shares are burned and principal is returned
        // NOTE: ERC-4626 conversions round down; redeem can be off-by-1 wei.
        assertEq(vault.balanceOf(user), 0);
        assertApproxEqAbs(assetsOut + (amount / 2), 2 * amount, 1);
        assertApproxEqAbs(token.balanceOf(user), 1_000e18, 1);
    }
}

