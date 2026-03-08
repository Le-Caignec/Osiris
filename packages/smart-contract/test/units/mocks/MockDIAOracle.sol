// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IDIAOracle} from "../../../src/interfaces/IDIAOracle.sol";

/// @title MockDIAOracle
/// @notice Configurable DIA oracle stub for unit tests.
contract MockDIAOracle is IDIAOracle {
    uint128 public mockPrice;
    uint128 public mockTimestamp;

    constructor(uint128 _price) {
        mockPrice = _price;
        mockTimestamp = uint128(block.timestamp);
    }

    function setPrice(uint128 _price) external {
        mockPrice = _price;
        mockTimestamp = uint128(block.timestamp);
    }

    function getValue(string memory) external view override returns (uint128 price, uint128 timestamp) {
        return (mockPrice, mockTimestamp);
    }
}
