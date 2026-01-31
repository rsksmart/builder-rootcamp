// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC20 } from "../dependencies/@openzeppelin-contracts-5.5.0/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../dependencies/@openzeppelin-contracts-5.5.0/token/ERC20/utils/SafeERC20.sol";
import { ERC20 } from "../dependencies/@openzeppelin-contracts-5.5.0/token/ERC20/ERC20.sol";
import { ERC4626 } from "../dependencies/@openzeppelin-contracts-5.5.0/token/ERC20/extensions/ERC4626.sol";
import { Ownable } from "../dependencies/@openzeppelin-contracts-5.5.0/access/Ownable.sol";

import { IStrategy } from "./interfaces/IStrategy.sol";

/**
 * @title MinimalVault
 * @notice Minimal ERC-4626 vault with multiple strategies + simple APY routing.
 * @dev Teaching version: no upgrades, no complex buffers.
 */
contract MinimalVault is ERC4626, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_STRATEGIES = 5;

    IStrategy[] public strategies;

    error InvalidStrategy(address strategy);
    error StrategyAssetMismatch(address strategyAsset, address vaultAsset);
    error StrategyVaultMismatch(address strategyVault, address expectedVault);
    error StrategyHasAssets(address strategy, uint256 balance);
    error InsufficientLiquidity();
    error StrategyAlreadyAdded(address strategy);
    error MaxStrategiesReached(uint256 maxStrategies);

    constructor(IERC20 asset_, string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        ERC4626(asset_)
        Ownable(msg.sender)
    { }

    function addStrategy(IStrategy strategy_) external onlyOwner {
        if (strategies.length >= MAX_STRATEGIES) revert MaxStrategiesReached(MAX_STRATEGIES);
        if (address(strategy_) == address(0)) revert InvalidStrategy(address(strategy_));
        if (address(strategy_.asset()) != address(asset())) {
            revert StrategyAssetMismatch(address(strategy_.asset()), address(asset()));
        }
        if (strategy_.vault() != address(this)) {
            revert StrategyVaultMismatch(strategy_.vault(), address(this));
        }

        // Prevent duplicates (cheap O(n), fine for demo).
        for (uint256 i = 0; i < strategies.length; ++i) {
            if (address(strategies[i]) == address(strategy_)) {
                revert StrategyAlreadyAdded(address(strategy_));
            }
        }

        strategies.push(strategy_);
        IERC20(asset()).forceApprove(address(strategy_), type(uint256).max);
    }

    function removeStrategy(IStrategy strategy_) external onlyOwner {
        if (address(strategy_) == address(0)) revert InvalidStrategy(address(strategy_));

        uint256 index = type(uint256).max;
        for (uint256 i = 0; i < strategies.length; ++i) {
            if (address(strategies[i]) == address(strategy_)) {
                index = i;
                break;
            }
        }
        if (index == type(uint256).max) return;

        uint256 bal = strategy_.balanceOf();
        if (bal != 0) revert StrategyHasAssets(address(strategy_), bal);

        // Remove allowance and forget strategy.
        IERC20(asset()).forceApprove(address(strategy_), 0);

        // swap-remove
        strategies[index] = strategies[strategies.length - 1];
        strategies.pop();
    }

    function totalAssets() public view override returns (uint256) {
        uint256 idle = IERC20(asset()).balanceOf(address(this));
        for (uint256 i = 0; i < strategies.length; ++i) {
            idle += strategies[i].balanceOf();
        }
        return idle;
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);

        if (assets == 0) return;
        if (strategies.length == 0) return;

        // Immediately deploy new deposits into the highest APY strategy.
        IStrategy s = _highestApyStrategy();
        s.deposit(assets);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        // Ensure the vault has enough idle assets; otherwise pull from strategies.
        uint256 idle = IERC20(asset()).balanceOf(address(this));
        if (idle < assets) {
            if (strategies.length == 0) revert InsufficientLiquidity();

            uint256 needed = assets - idle;
            uint256 pulled = _withdrawFromLowestApyFirst(needed);
            if (pulled < needed) revert InsufficientLiquidity();
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function _highestApyStrategy() internal view returns (IStrategy best) {
        best = strategies[0];
        uint256 bestApy = best.estimateApy();

        for (uint256 i = 1; i < strategies.length; ++i) {
            IStrategy s = strategies[i];
            uint256 apy = s.estimateApy();
            if (apy > bestApy) {
                best = s;
                bestApy = apy;
            }
        }
    }

    function _withdrawFromLowestApyFirst(uint256 needed) internal returns (uint256 pulled) {
        // Naive selection loop: repeatedly withdraw from current lowest APY strategy.
        // Fine for demo sizes (2 strategies), avoids sorting/storage writes.
        uint256 remaining = needed;

        while (remaining > 0) {
            (IStrategy s, uint256 bal) = _lowestApyStrategyWithBalance();
            if (address(s) == address(0) || bal == 0) break;

            uint256 toPull = bal < remaining ? bal : remaining;
            uint256 got = s.withdraw(toPull);
            pulled += got;
            if (got >= remaining) break;
            remaining -= got;
        }
    }

    function _lowestApyStrategyWithBalance() internal view returns (IStrategy worst, uint256 bal) {
        uint256 worstApy = type(uint256).max;
        for (uint256 i = 0; i < strategies.length; ++i) {
            IStrategy s = strategies[i];
            uint256 b = s.balanceOf();
            if (b == 0) continue;
            uint256 apy = s.estimateApy();
            if (apy < worstApy) {
                worst = s;
                worstApy = apy;
                bal = b;
            }
        }
    }
}

