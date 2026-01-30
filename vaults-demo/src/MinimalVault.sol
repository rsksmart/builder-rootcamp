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
 * @notice Minimal ERC-4626 vault that can plug into a single yield strategy.
 * @dev Teaching version: no upgrades, no roles (just owner), no multi-strategy.
 */
contract MinimalVault is ERC4626, Ownable {
    using SafeERC20 for IERC20;

    IStrategy public strategy;

    error InvalidStrategy(address strategy);
    error StrategyAssetMismatch(address strategyAsset, address vaultAsset);
    error StrategyVaultMismatch(address strategyVault, address expectedVault);
    error StrategyHasAssets(address strategy, uint256 balance);
    error InsufficientLiquidity();

    constructor(IERC20 asset_, string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        ERC4626(asset_)
        Ownable(msg.sender)
    { }

    function enableStrategy(IStrategy strategy_) external onlyOwner {
        if (address(strategy_) == address(0)) revert InvalidStrategy(address(strategy_));
        if (address(strategy_.asset()) != address(asset())) {
            revert StrategyAssetMismatch(address(strategy_.asset()), address(asset()));
        }
        if (strategy_.vault() != address(this)) {
            revert StrategyVaultMismatch(strategy_.vault(), address(this));
        }

        strategy = strategy_;
        IERC20(asset()).forceApprove(address(strategy_), type(uint256).max);
    }

    function disableStrategy() external onlyOwner {
        IStrategy s = strategy;
        if (address(s) == address(0)) return;

        uint256 bal = s.balanceOf();
        if (bal != 0) revert StrategyHasAssets(address(s), bal);

        // Remove allowance and forget strategy.
        IERC20(asset()).forceApprove(address(s), 0);
        strategy = IStrategy(address(0));
    }

    function totalAssets() public view override returns (uint256) {
        uint256 idle = IERC20(asset()).balanceOf(address(this));
        IStrategy s = strategy;
        if (address(s) == address(0)) return idle;
        return idle + s.balanceOf();
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);

        // Immediately deploy new deposits into the strategy.
        IStrategy s = strategy;
        if (address(s) != address(0) && assets != 0) {
            s.deposit(assets);
        }
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        // Ensure the vault has enough idle assets; otherwise pull from strategy.
        uint256 idle = IERC20(asset()).balanceOf(address(this));
        if (idle < assets) {
            IStrategy s = strategy;
            if (address(s) == address(0)) revert InsufficientLiquidity();

            uint256 needed = assets - idle;
            uint256 pulled = s.withdraw(needed);
            if (pulled < needed) revert InsufficientLiquidity();
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }
}

