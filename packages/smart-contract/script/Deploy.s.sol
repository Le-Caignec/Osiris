// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Callback} from "../src/Callback.sol";
import {CronReactive} from "../src/CronReactive.sol";
import {Osiris} from "../src/Osiris.sol";
import {ConfigLib} from "./lib/configLib.sol";

// TODO: To remove
contract DeployCallback is Script {
    function run() external {
        string memory chain = vm.envString("CHAIN");
        ConfigLib.DestinationNetworkConfig memory config = ConfigLib.readDestinationNetworkConfig(chain);
        address callbackSender = config.callbackProxyContract;

        vm.startBroadcast();
        // Deploy the Callback contract on Sepolia
        Callback callbackContract = new Callback{value: 0.000001 ether}(callbackSender);
        console.log("Callback Contract Address (Sepolia):", address(callbackContract));
        vm.stopBroadcast();
    }
}

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
        Osiris osirisContract =
            new Osiris{value: 0.01 ether}(universalRouter, permit2, usdc, callbackSender, ethUsdFeed);
        console.log("Osiris Contract Address:", address(osirisContract));
        vm.stopBroadcast();
    }
}
