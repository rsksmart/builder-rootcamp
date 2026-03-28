// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC20 } from "../../dependencies/@openzeppelin-contracts-5.5.0/token/ERC20/IERC20.sol";

/**
 * @notice Minimal vault↔strategy interface.
 */
interface IStrategy {
    function deposit(uint256 assets) external returns (uint256 deposited);    /// @return withdrawn Amount withdrawn.
    function withdraw(uint256 assets) external returns (uint256 withdrawn);


    function asset() external view returns (IERC20);
    function vault() external view returns (address);
    function balanceOf() external view returns (uint256);
    function estimateApy() external view returns (uint256); /// @notice Estimated APY (1e9 = 100%).
}

