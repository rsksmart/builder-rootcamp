// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "../dependencies/forge-std-1.11.0/src/Test.sol";

import { MockERC20 } from "./mocks/MockERC20.sol";
import { MinimalVault } from "../src/MinimalVault.sol";
import { MockStrategy } from "./mocks/MockStrategy.sol";

contract MinimalVaultTest is Test {
    MockERC20 token;
    MinimalVault vault;
    MockStrategy strategy;

    address user = makeAddr("user");

    function setUp() public {
        // GIVEN a minimal ERC-4626 vault with a mock asset + a funded user
        token = new MockERC20("Mock USDRIF", "mUSDRIF");
        vault = new MinimalVault(token, "Demo Vault", "vDEMO");
        token.mint(user, 1_000e18);
        // ALTERNATIVE
        // deal(address(token), user, 1_000e18);
        

        // AND a single (mock) strategy enabled by the owner
        strategy = new MockStrategy(token, address(vault));
        vault.enableStrategy(strategy);
    }

    function test_Deposit_Yield_Redeem_SingleStrategy() public {
        uint256 depositAmount = 100e18;

        // WHEN user deposits
        vm.startPrank(user);
        token.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user);
        vm.stopPrank();

        // THEN assets are deployed into the strategy and totalAssets tracks them
        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(address(strategy)), depositAmount);
        assertEq(vault.totalAssets(), depositAmount);

        // WHEN the strategy accrues yield (simulated by minting to the strategy)
        token.mint(address(strategy), 10e18);

        // THEN the vault's accounting reflects the gain via totalAssets
        assertEq(vault.totalAssets(), 110e18);

        // WHEN user redeems all shares
        vm.prank(user);
        uint256 assetsOut = vault.redeem(shares, user, user);

        // THEN all shares are burned and principal+yield is returned
        // NOTE: ERC-4626 conversions round down; redeem can be off-by-1 wei.
        assertEq(vault.balanceOf(user), 0);
        assertApproxEqAbs(assetsOut, 110e18, 1);
        assertEq(token.balanceOf(user), 1_000e18 - depositAmount + assetsOut);
    }
}

