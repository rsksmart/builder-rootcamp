// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @dev Minimal Compound-like cToken interface (Tropykus).
interface ITropykusCToken {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);

    function accrueInterest() external returns (uint256);
}

