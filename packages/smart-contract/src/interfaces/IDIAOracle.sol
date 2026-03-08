// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/// @title IDIAOracle
/// @notice Interface for DIA Oracle V2 price feeds
/// @dev getValue returns price with 8 decimals and a Unix timestamp of last update
///      Heartbeat: 24h | Deviation trigger: 1%
interface IDIAOracle {
    /// @notice Get the latest value for a given asset pair
    /// @param key The asset pair string (e.g. "REACT/USD")
    /// @return price The latest price (8 decimals, same scale as Chainlink)
    /// @return timestamp Unix timestamp of the last price update
    function getValue(string memory key) external view returns (uint128 price, uint128 timestamp);
}
