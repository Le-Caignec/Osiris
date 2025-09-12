// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {CronReactive} from "../src/CronReactive.sol";

contract CronActionPause is Script {
    function run() external {
        vm.startBroadcast();
        address cronReactiveAddress = vm.envAddress("CRON_REACTIVE_ADDRESS");

        // Deploy the Callback contract on Arbitrum Sepolia
        CronReactive cronReactive = CronReactive(payable(cronReactiveAddress));
        cronReactive.pause();
        console.log("Paused CronReactive at address:", cronReactiveAddress);

        vm.stopBroadcast();
    }
}

contract CronActionUnpause is Script {
    function run() external {
        vm.startBroadcast();
        address cronReactiveAddress = vm.envAddress("CRON_REACTIVE_ADDRESS");

        // Deploy the Callback contract on Arbitrum Sepolia
        CronReactive cronReactive = CronReactive(payable(cronReactiveAddress));
        cronReactive.resume();
        console.log("Unpaused CronReactive at address:", cronReactiveAddress);

        vm.stopBroadcast();
    }
}
