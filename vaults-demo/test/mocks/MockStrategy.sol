// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC20 } from "../../dependencies/@openzeppelin-contracts-5.5.0/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../../dependencies/@openzeppelin-contracts-5.5.0/token/ERC20/utils/SafeERC20.sol";

import { IStrategy } from "../../src/interfaces/IStrategy.sol";

/**
 * @notice Minimal in-memory “strategy” for unit tests.
 * @dev It just holds the underlying; tests can mint extra underlying to this contract to simulate yield.
 */
contract MockStrategy is IStrategy {
    using SafeERC20 for IERC20;

    IERC20 public immutable override asset;
    address public immutable override vault;

    error NotVault(address caller);
    error InvalidVault(address vault);

    constructor(IERC20 asset_, address vault_) {
        if (vault_ == address(0)) revert InvalidVault(vault_);
        asset = asset_;
        vault = vault_;
    }

    function deposit(uint256 assets) external override returns (uint256 deposited) {
        if (msg.sender != vault) revert NotVault(msg.sender);
        asset.safeTransferFrom(vault, address(this), assets);
        return assets;
    }

    function withdraw(uint256 assets) external override returns (uint256 withdrawn) {
        if (msg.sender != vault) revert NotVault(msg.sender);
        asset.safeTransfer(vault, assets);
        return assets;
    }

    function balanceOf() external view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function estimateApy() external pure override returns (uint256) {
        return 0;
    }
}

