// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SimpleStorage
 * @dev Store and retrieve a value
 *
 * Function Signatures:
 *   store(uint256): 0x6057361d
 *   retrieve():     0x6d4ce63c
 */
contract SimpleStorage {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    /**
     * @dev Store a value
     * @param _value The value to store
     */
    function store(uint256 _value) public {
        value = _value;
        emit ValueChanged(_value);
    }

    /**
     * @dev Retrieve the stored value
     * @return The stored value
     */
    function retrieve() public view returns (uint256) {
        return value;
    }
}
