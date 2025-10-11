// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {
    AggregatorV3Interface
} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IChainlinkOracle} from "./interfaces/IChainlinkOracle.sol";

/**
 * @title ChainlinkOracle
 * @notice Contract to fetch ETH/USD prices using Chainlink data feeds
 * @dev Uses ETH/USD feed to get current ETH price
 */
contract ChainlinkOracle is IChainlinkOracle {
    AggregatorV3Interface internal ethUsdFeed;

    // Store last 10 price points for volatility calculation
    PriceData[10] internal priceHistory;
    uint8 internal priceHistoryIndex;
    uint8 internal priceHistoryCount;

    // Volatility threshold (in basis points, e.g., 500 = 5%)
    uint256 public volatilityThreshold = 500; // 5% default

    /**
     * @notice Constructor sets up Chainlink price feed
     * @param _ethUsdFeed ETH/USD Chainlink feed address
     */
    constructor(address _ethUsdFeed) {
        ethUsdFeed = AggregatorV3Interface(_ethUsdFeed);
    }

    /**
     * @notice Get the latest ETH/USD price
     * @return price The current ETH/USD price (scaled by 1e8)
     */
    function getEthUsdPrice() external view returns (uint256 price) {
        int256 ethUsdPrice = getLatestPrice(ethUsdFeed);

        if (ethUsdPrice <= 0) revert InvalidPrice();

        // Return ETH/USD price directly (scaled by 1e8)
        price = uint256(ethUsdPrice);
    }

    /**
     * @notice Update price history and calculate current volatility
     * @return currentPrice The current ETH/USD price
     * @return volatility The current volatility in basis points
     */
    function updatePriceAndGetVolatility() internal returns (uint256 currentPrice, uint256 volatility) {
        currentPrice = this.getEthUsdPrice();

        // Update price history
        priceHistory[priceHistoryIndex] = PriceData({timestamp: block.timestamp, price: currentPrice});

        priceHistoryIndex = (priceHistoryIndex + 1) % 10;
        if (priceHistoryCount < 10) {
            priceHistoryCount++;
        }

        // Calculate volatility
        volatility = calculateVolatility();

        emit PriceUpdated(currentPrice, block.timestamp);
    }

    /**
     * @notice Calculate volatility based on price history
     * @return volatility The volatility in basis points
     */
    function calculateVolatility() internal view returns (uint256 volatility) {
        if (priceHistoryCount < 2) return 0;

        uint256 sum = 0;
        uint256 count = 0;

        // Calculate average price
        for (uint8 i = 0; i < priceHistoryCount; i++) {
            sum += priceHistory[i].price;
            count++;
        }
        uint256 averagePrice = sum / count;

        // Calculate variance
        uint256 variance = 0;
        for (uint8 i = 0; i < priceHistoryCount; i++) {
            uint256 diff = SignedMath.abs(int256(priceHistory[i].price) - int256(averagePrice));
            variance += (diff * diff) / count;
        }

        // Calculate standard deviation and convert to basis points
        uint256 stdDev = Math.sqrt(variance);
        volatility = (stdDev * 10000) / averagePrice; // Convert to basis points
    }

    /**
     * @notice Check if current volatility is under threshold
     * @return isUnderThreshold True if volatility is under threshold
     * @return currentVolatility Current volatility in basis points
     */
    function volatilityCheck() external returns (bool isUnderThreshold, uint256 currentVolatility) {
        (, currentVolatility) = updatePriceAndGetVolatility();
        isUnderThreshold = currentVolatility <= volatilityThreshold;
    }

    /**
     * @notice Get latest price from a Chainlink feed
     * @param feed The Chainlink price feed
     * @return price The latest price
     */
    function getLatestPrice(AggregatorV3Interface feed) internal view returns (int256 price) {
        (, int256 answer,, uint256 updatedAt,) = feed.latestRoundData();

        if (answer <= 0) revert InvalidPrice();
        if (updatedAt == 0) revert PriceNotUpdated();
        if (block.timestamp - updatedAt > 3600) revert PriceTooOld(); // 1 hour staleness check

        return answer;
    }
}
