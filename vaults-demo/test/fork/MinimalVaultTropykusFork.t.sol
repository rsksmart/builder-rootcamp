// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std-1.11.0/src/Test.sol";
import { console2 } from "forge-std-1.11.0/src/console2.sol";
import { IERC20 } from "@openzeppelin-contracts-5.5.0/token/ERC20/IERC20.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts-5.5.0/proxy/ERC1967/ERC1967Proxy.sol";

import { MinimalVault } from "../../src/MinimalVault.sol";
import { TropykusStrategy } from "../../src/strategies/TropykusStrategy.sol";
import { ITropykusCToken } from "../../src/strategies/interfaces/ITropykusCToken.sol";

/* solhint-disable func-name-mixedcase, ordering, gas-custom-errors, private-vars-leading-underscore */
contract MinimalVaultTropykusForkTest is Test {
    IERC20 private _usdrif;
    ITropykusCToken private _cToken;

    MinimalVault private _vault;
    TropykusStrategy private _strategy;
    address private _user;
    uint256 private _amount;

    function setUp() public {
        string memory rpcUrl = vm.envOr("RPC_URL", string(""));
        uint256 forkBlockNumber = vm.envOr("FORK_BLOCK_NUMBER", uint256(0));

        address usdrifAddress = vm.envOr("USDRIF_ADDRESS", address(0));
        address cTokenAddress = vm.envOr("TROPYKUS_TOKEN", address(0));

        if (bytes(rpcUrl).length == 0 || usdrifAddress == address(0) || cTokenAddress == address(0)) {
            vm.skip(true, "missing fork env vars (RPC_URL, USDRIF_ADDRESS, TROPYKUS_TOKEN)");
            return;
        }

        if (forkBlockNumber == 0) {
            vm.createSelectFork(rpcUrl);
        } else {
            vm.createSelectFork(rpcUrl, forkBlockNumber);
        }

        // Extra safety: if fork didn't actually load, avoid false-negative failures.
        if (usdrifAddress.code.length == 0 || cTokenAddress.code.length == 0) {
            vm.skip(true, "fork not active or addresses have no code");
            return;
        }

        _usdrif = IERC20(usdrifAddress);
        _cToken = ITropykusCToken(cTokenAddress);

        MinimalVault impl = new MinimalVault();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), abi.encodeCall(MinimalVault.initialize, (_usdrif, "Fork Demo Vault", "vFORK", address(this)))
        );
        _vault = MinimalVault(address(proxy));
        _strategy = new TropykusStrategy(_usdrif, address(_vault), _cToken);
        _vault.addStrategy(_strategy);

        _user = makeAddr("user");
        _amount = 500e18;

        // Add extra liquidity so withdrawals are more likely to succeed in the fork state.
        _addLiquidityToTropykus(2_000e18);
    }

    function test_Fork_Deposit_Wait_Accrue_LogApy_Redeem() public {
        deal(address(_usdrif), _user, _amount);

        vm.startPrank(_user);
        _usdrif.approve(address(_vault), _amount);
        uint256 shares = _vault.deposit(_amount, _user);
        _vault.rebalance(); // push idle assets into the strategy

        console2.log("*** Tropykus ***");
        console2.log("shares", shares);
        console2.log("amount", _amount);
        console2.log("estimated Apy (1_000_000_000 (1e9) = 100%)", _strategy.estimateApy());

        // Advance time/blocks and force interest accrual.
        vm.roll(block.number + (365 days / 30)); // ~30s blocks
        vm.warp(block.timestamp + 365 days);
        _cToken.accrueInterest();

        uint256 assetsOut = _vault.redeem(shares, _user, _user);
        vm.stopPrank();

        console2.log("assetsOut", assetsOut);

        // NOTE: ERC-4626 conversions round down; redeem can be off-by-1 wei.
        assertGe(assetsOut + 1, _amount);
        assertEq(_vault.balanceOf(_user), 0);
    }

    function _addLiquidityToTropykus(uint256 amount) internal {
        address liquidityProvider = makeAddr("tropykus_liquidity_provider");
        deal(address(_usdrif), liquidityProvider, amount);

        vm.prank(liquidityProvider);
        _usdrif.approve(address(_cToken), amount);

        vm.prank(liquidityProvider);
        _cToken.mint(amount);
    }
}

