// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title IChainlinkOracle
 * @notice Interface for Chainlink Oracle contract
 * @dev Defines the interface for fetching ETH/USDC prices and volatility calculations
 */
interface IChainlinkOracle {
    // Custom errors
    error InvalidPrice();
    error PriceNotUpdated();
    error PriceTooOld();

    // Events
    event PriceUpdated(uint256 ethUsdcPrice, uint256 timestamp);

    // Structs
    struct PriceData {
        uint256 timestamp;
        uint256 price;
    }

    /**
     * @notice Get the latest ETH/USD price
     * @return price The current ETH/USD price (scaled by 1e8)
     */
    function getEthUsdPrice() external view returns (uint256 price);

    /**
     * @notice Check if current volatility is under threshold
     * @return isUnderThreshold True if volatility is under threshold
     * @return currentVolatility Current volatility in basis points
     */
    function volatilityCheck() external returns (bool isUnderThreshold, uint256 currentVolatility);

    /**
     * @notice Get the current volatility threshold
     * @return threshold The volatility threshold in basis points
     */
    function volatilityThreshold() external view returns (uint256 threshold);
}
