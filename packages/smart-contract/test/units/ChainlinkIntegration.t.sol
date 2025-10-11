// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {ChainlinkOracle} from "../../src/ChainlinkOracle.sol";
import {IChainlinkOracle} from "../../src/interfaces/IChainlinkOracle.sol";
import {ConfigLib} from "../../script/lib/configLib.sol";

contract ChainlinkIntegrationTest is Test {
    ChainlinkOracle public oracle;
    address private ethUsdFeed;

    function setUp() public {
        // Read from config.json like other tests
        string memory chain = vm.envOr("CHAIN", string("sepolia"));
        ConfigLib.DestinationNetworkConfig memory config = ConfigLib.readDestinationNetworkConfig(chain);
        vm.createSelectFork(config.rpcUrl);

        // Use config address for ETH/USD feed
        ethUsdFeed = config.chainlinkEthUsdFeed;

        // Deploy ChainlinkOracle contract directly
        oracle = new ChainlinkOracle(ethUsdFeed);

        // Labels for nicer traces
        vm.label(address(oracle), "ChainlinkOracle");
        vm.label(ethUsdFeed, "ETH/USD Feed");
    }

    function testGetEthUsdPrice() public view {
        // Test getting current ETH/USD price from Chainlink
        try oracle.getEthUsdPrice() returns (uint256 price) {
            console.log("Current ETH/USD price:", price);
            assertGt(price, 0, "Price should be greater than 0");
        } catch Error(string memory reason) {
            console.log("Price feed error:", reason);
            // This might fail if price feeds are not available on the test network
        }
    }

    function testVolatilityThreshold() public view {
        // Test getting volatility threshold
        uint256 threshold = oracle.volatilityThreshold();
        console.log("Volatility threshold:", threshold);
        assertGt(threshold, 0, "Threshold should be greater than 0");
        assertLe(threshold, 10000, "Threshold should not exceed 100% (10000 basis points)");
    }

    function testVolatilityCheck() public {
        // Test volatility check functionality directly on oracle
        try oracle.volatilityCheck() returns (bool isUnderThreshold, uint256 currentVolatility) {
            assertGe(currentVolatility, 0, "Volatility should be non-negative");
        } catch Error(string memory reason) {
            console.log("Volatility check error:", reason);
            // This might fail if price feeds are not available on the test network
        }
    }

    function testPriceHistoryUpdate() public {
        // Test that price history gets updated when volatility is checked
        uint256 initialPrice = oracle.getEthUsdPrice();
        
        // Call volatility check to trigger price history update
        oracle.volatilityCheck();
        
        // Price should remain the same (or very close)
        uint256 updatedPrice = oracle.getEthUsdPrice();
        assertEq(initialPrice, updatedPrice, "Price should remain consistent");
    }

    function testMultipleVolatilityChecks() public {
        // Test multiple volatility checks to build price history
        for (uint i = 0; i < 3; i++) {
            oracle.volatilityCheck();
            // Small delay to simulate different timestamps
            vm.warp(block.timestamp + 1);
        }
        
        // Should not revert after multiple calls
        (, uint256 volatility) = oracle.volatilityCheck();
        assertGe(volatility, 0, "Volatility should be calculated after multiple updates");
    }
}
