// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {CronReactive} from "../src/CronReactive.sol";
import {ConfigLib} from "./lib/configLib.sol";

contract CronActionPause is Script {
    function run() external {
        // Read reactive network from environment variable, default to "lasna"
        string memory reactiveNetwork = vm.envOr("REACTIVE_NETWORK", string("lasna"));
        ConfigLib.ReactiveNetworkConfig memory reactiveNetworkConfig = ConfigLib.readReactiveNetworkConfig(reactiveNetwork);
        address cronReactiveAddress = reactiveNetworkConfig.reactiveContract;

        vm.startBroadcast();
        CronReactive cronReactive = CronReactive(payable(cronReactiveAddress));
        cronReactive.pause();
        console.log("Paused CronReactive at address:", cronReactiveAddress);
        vm.stopBroadcast();
    }
}

contract CronActionUnpause is Script {
    function run() external {
        // Read reactive network from environment variable, default to "lasna"
        string memory reactiveNetwork = vm.envOr("REACTIVE_NETWORK", string("lasna"));
        ConfigLib.ReactiveNetworkConfig memory reactiveNetworkConfig = ConfigLib.readReactiveNetworkConfig(reactiveNetwork);
        address cronReactiveAddress = reactiveNetworkConfig.reactiveContract;

        vm.startBroadcast();
        CronReactive cronReactive = CronReactive(payable(cronReactiveAddress));
        cronReactive.resume();
        console.log("Unpaused CronReactive at address:", cronReactiveAddress);
        vm.stopBroadcast();
    }
}
