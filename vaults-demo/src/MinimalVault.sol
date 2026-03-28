// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC20 } from "../dependencies/@openzeppelin-contracts-5.5.0/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../dependencies/@openzeppelin-contracts-5.5.0/token/ERC20/utils/SafeERC20.sol";
import { ERC4626Upgradeable } from
    "../dependencies/@openzeppelin-contracts-upgradeable-5.5.0/token/ERC20/extensions/ERC4626Upgradeable.sol";
import { ERC20Upgradeable } from "../dependencies/@openzeppelin-contracts-upgradeable-5.5.0/token/ERC20/ERC20Upgradeable.sol";
import { AccessControlUpgradeable } from "../dependencies/@openzeppelin-contracts-upgradeable-5.5.0/access/AccessControlUpgradeable.sol";
import { Initializable } from "../dependencies/@openzeppelin-contracts-upgradeable-5.5.0/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "../dependencies/@openzeppelin-contracts-upgradeable-5.5.0/proxy/utils/UUPSUpgradeable.sol";

import { IStrategy } from "./interfaces/IStrategy.sol";

/**
 * @title MinimalVault
 * @notice Minimal ERC-4626 vault with multiple strategies + rebalance.
 * @dev Teaching version: UUPS upgradeable, no complex buffers, 2 roles: admin + upgrader.
 */
contract MinimalVault is Initializable, ERC4626Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public constant MAX_STRATEGIES = 5;

    IStrategy[] public strategies;

    event StrategiesSorted(address indexed highestApyStrategy);
    event Rebalanced(uint256 withdrawnFromStrategies, uint256 depositedToStrategy);

    error InvalidStrategy(address strategy);
    error StrategyAssetMismatch(address strategyAsset, address vaultAsset);
    error StrategyVaultMismatch(address strategyVault, address expectedVault);
    error StrategyHasAssets(address strategy, uint256 balance);
    error InsufficientLiquidity();
    error StrategyAlreadyAdded(address strategy);
    error MaxStrategiesReached(uint256 maxStrategies);

    constructor() {
        _disableInitializers();
    }

    function initialize(IERC20 asset_, string memory name_, string memory symbol_, address admin_) external initializer {
        __ERC20_init(name_, symbol_);
        __ERC4626_init(asset_);
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(UPGRADER_ROLE, admin_);
    }

    function addStrategy(IStrategy strategy_) external onlyRole(DEFAULT_ADMIN_ROLE) {
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

    /// @notice Sort strategies by APY (desc) and (for demo) consolidate funds into the highest APY strategy.
    function rebalance() external {
        uint256 len = strategies.length;
        if (len == 0) return;

        _sortStrategiesByApy();

        // Deploy idle funds sitting in the vault into the highest APY strategy.
        uint256 withdrawnFromStrategies = 0;

        // Deposit all idle funds into the highest APY strategy.
        uint256 idle = IERC20(asset()).balanceOf(address(this));
        uint256 depositedToStrategy = 0;
        if (idle > 0) {
            depositedToStrategy = strategies[0].deposit(idle);
        }

        emit Rebalanced(withdrawnFromStrategies, depositedToStrategy);
    }

    function removeStrategy(IStrategy strategy_) external onlyRole(DEFAULT_ADMIN_ROLE) {
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
        // NOTE: No auto-deploy on user deposit. `rebalance()` handles deployment/allocation.
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
            uint256 pulled = _withdrawFromStrategies(needed);
            if (pulled < needed) revert InsufficientLiquidity();
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function _withdrawFromStrategies(uint256 needed) internal returns (uint256 pulled) {
        // Withdraw from strategies in reverse array order.
        // If `rebalance()` is called regularly, this means lowest APY is attempted first.
        uint256 remaining = needed;
        for (uint256 i = strategies.length; i > 0 && remaining > 0; --i) {
            IStrategy s = strategies[i - 1];
            uint256 bal = s.balanceOf();
            if (bal == 0) continue;
            uint256 toPull = bal < remaining ? bal : remaining;
            uint256 got = s.withdraw(toPull);
            pulled += got;
            if (got >= remaining) break;
            remaining -= got; // defensive (got may be < toPull)
        }
    }

    function _sortStrategiesByApy() internal {
        uint256 len = strategies.length;
        if (len < 2) return;

        bool changed = false;
        // Insertion sort, highest APY first. Efficient for small arrays (<= MAX_STRATEGIES).
        for (uint256 i = 1; i < len; ++i) {
            IStrategy key = strategies[i];
            uint256 keyApy = key.estimateApy();
            uint256 j = i;

            while (j > 0 && strategies[j - 1].estimateApy() < keyApy) {
                strategies[j] = strategies[j - 1];
                changed = true;
                --j;
            }

            if (address(strategies[j]) != address(key)) {
                strategies[j] = key;
                changed = true;
            }
        }

        if (changed) emit StrategiesSorted(address(strategies[0]));
    }

    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) { }
}

