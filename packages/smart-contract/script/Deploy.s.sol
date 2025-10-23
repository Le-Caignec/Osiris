// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {CronReactive} from "../src/CronReactive.sol";
import {Osiris} from "../src/Osiris.sol";
import {ConfigLib} from "./lib/configLib.sol";

contract DeployOsiris is Script {
    function run() external {
        string memory chain = vm.envString("CHAIN");
        ConfigLib.DestinationNetworkConfig memory config = ConfigLib.readDestinationNetworkConfig(chain);

        address universalRouter = config.uniswapUniversalRouter;
        address permit2 = config.uniswapPermit2;
        address usdc = config.usdc;
        address callbackSender = config.callbackProxyContract;
        address ethUsdFeed = config.chainlinkEthUsdFeed;

        vm.startBroadcast();
        // Deploy the Osiris contract with Chainlink integration
        Osiris osirisContract = new Osiris(universalRouter, permit2, usdc, callbackSender, ethUsdFeed);
        console.log("Osiris Contract Address:", address(osirisContract));
        vm.stopBroadcast();
    }
}
