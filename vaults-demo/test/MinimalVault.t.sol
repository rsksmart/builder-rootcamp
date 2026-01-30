// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "../dependencies/forge-std-1.11.0/src/Test.sol";

import { MockERC20 } from "./mocks/MockERC20.sol";
import { MinimalVault } from "../src/MinimalVault.sol";

contract MinimalVaultTest is Test {
    MockERC20 token;
    MinimalVault vault;

    address user = makeAddr("user");

    function setUp() public {
        // GIVEN an idle ERC-4626 vault with a mock asset + a funded user
        token = new MockERC20("Mock USDRIF", "mUSDRIF");
        vault = new MinimalVault(token, "Demo Vault", "vDEMO");
        token.mint(user, 1_000e18);
    }

    function test_Deposit_Redeem_IdleVault() public {
        // GIVEN a user deposits assets
        uint256 depositAmount = 100e18;
        vm.startPrank(user);
        token.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user);
        vm.stopPrank();

        // THEN shares are minted 1:1 and assets stay in the vault
        assertEq(shares, depositAmount);
        assertEq(vault.totalAssets(), depositAmount);
        assertEq(token.balanceOf(address(vault)), depositAmount);

        // GIVEN a user redeems all shares
        vm.prank(user);
        uint256 assetsOut = vault.redeem(shares, user, user);

        // THEN all shares are burned and principal is returned
        assertEq(vault.balanceOf(user), 0);
        assertEq(assetsOut, depositAmount);
        assertEq(token.balanceOf(user), 1_000e18);
    }
}

