// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC20 } from "../../dependencies/@openzeppelin-contracts-5.5.0/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../../dependencies/@openzeppelin-contracts-5.5.0/token/ERC20/utils/SafeERC20.sol";
import { Math } from "../../dependencies/@openzeppelin-contracts-5.5.0/utils/math/Math.sol";

import { IStrategy } from "../interfaces/IStrategy.sol";
import { ITropykusCToken } from "./interfaces/ITropykusCToken.sol";
import { StrategyConstants } from "./StrategyConstants.sol";

/// @notice Minimal Tropykus (Compound-like) supply/withdraw adapter.
contract TropykusStrategy is IStrategy {
    using SafeERC20 for IERC20;

    IERC20 public immutable override asset;
    address public immutable override vault;

    ITropykusCToken public immutable cToken;

    error NotVault(address caller);
    error InvalidAddress(address addr);
    error MintFailed(uint256 errorCode);
    error RedeemFailed(uint256 errorCode);

    constructor(IERC20 asset_, address vault_, ITropykusCToken cToken_) {
        if (address(asset_) == address(0)) revert InvalidAddress(address(asset_));
        if (vault_ == address(0)) revert InvalidAddress(vault_);
        if (address(cToken_) == address(0)) revert InvalidAddress(address(cToken_));

        asset = asset_;
        vault = vault_;
        cToken = cToken_;
    }

    function deposit(uint256 assets) external override returns (uint256 deposited) {
        if (msg.sender != vault) revert NotVault(msg.sender);
        if (assets == 0) return 0;

        asset.safeTransferFrom(vault, address(this), assets);
        asset.forceApprove(address(cToken), assets);

        // Compound-like mint returns 0 on success.
        uint256 result = cToken.mint(assets);
        if (result != 0) revert MintFailed(result);

        return assets;
    }

    function withdraw(uint256 assets) external override returns (uint256 withdrawn) {
        if (msg.sender != vault) revert NotVault(msg.sender);
        if (assets == 0) return 0;

        uint256 balBefore = asset.balanceOf(address(this));

        // redeemUnderlying returns 0 on success.
        uint256 result = cToken.redeemUnderlying(assets);
        if (result != 0) revert RedeemFailed(result);

        uint256 balAfter = asset.balanceOf(address(this));
        withdrawn = balAfter - balBefore;
        asset.safeTransfer(vault, withdrawn);
    }

    function balanceOf() external view override returns (uint256) {
        uint256 cBal = cToken.balanceOf(address(this));
        if (cBal == 0) return 0;

        // underlying = cTokenBalance * exchangeRate / 1e18
        return Math.mulDiv(cBal, cToken.exchangeRateStored(), 1e18);
    }

    function estimateApy() external view override returns (uint256) {
        // Linear approximation: supplyRatePerBlock * blocksPerYear.
        // Uses ~30s blocks (RSK-like) for this demo.
        uint256 blocksPerYear = (365 days) / 30;
        uint256 supplyRatePerBlock = cToken.supplyRatePerBlock(); // 1e18-scale
        return Math.mulDiv(supplyRatePerBlock, blocksPerYear * StrategyConstants.BASIS_POINTS, 1e18);
    }
}

