// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {CronReactive} from "../src/CronReactive.sol";
import {ConfigLib} from "./lib/configLib.sol";

contract CronActionPause is Script {
    function run() external {
        ConfigLib.ReactiveNetworkConfig memory reactiveNetworkConfig = ConfigLib.readReactiveNetworkConfig();
        address cronReactiveAddress = reactiveNetworkConfig.reactiveContract;

        vm.startBroadcast();
        // Deploy the Callback contract on Arbitrum Sepolia
        CronReactive cronReactive = CronReactive(payable(cronReactiveAddress));
        cronReactive.pause();
        console.log("Paused CronReactive at address:", cronReactiveAddress);
        vm.stopBroadcast();
    }
}

contract CronActionUnpause is Script {
    function run() external {
        ConfigLib.ReactiveNetworkConfig memory reactiveNetworkConfig = ConfigLib.readReactiveNetworkConfig();
        address cronReactiveAddress = reactiveNetworkConfig.reactiveContract;

        vm.startBroadcast();
        // Deploy the Callback contract on Arbitrum Sepolia
        CronReactive cronReactive = CronReactive(payable(cronReactiveAddress));
        cronReactive.resume();
        console.log("Unpaused CronReactive at address:", cronReactiveAddress);
        vm.stopBroadcast();
    }
}
