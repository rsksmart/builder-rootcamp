// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ERC20Vault {
    // user => token => balance
    mapping(address => mapping(address => uint256)) public balance;

    function deposit(address token, uint256 amount) external {
        require(amount > 0, "ZERO_AMOUNT");
        balance[msg.sender][token] += amount;
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "TRANSFER_FROM_FAILED");
    }

    function withdraw(address token, uint256 amount) external {
        require(amount <= balance[msg.sender][token], "INSUFFICIENT");
        balance[msg.sender][token] -= amount;
        require(IERC20(token).transfer(msg.sender, amount), "TRANSFER_FAILED");
    }
}
