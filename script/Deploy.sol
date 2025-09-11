// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Callback} from "../src/Callback.sol";
import {CronReactive} from "../src/CronReactive.sol";

contract DeployCallback is Script {
    function run() external {
        vm.startBroadcast();
        address callbackSender = vm.envAddress("CALLBACK_SENDER_ADDRESS");

        // Deploy the Callback contract on Sepolia
        Callback callbackContract = new Callback{value: 0.1 ether}(callbackSender);
        console.log("Callback Contract Address (Sepolia):", address(callbackContract));

        vm.stopBroadcast();
    }
}

contract DeployCronReactive is Script {
    function run() external {
        vm.startBroadcast();
        address service = vm.envAddress("SERVICE");
        uint256 callbackChainId = vm.envUint("SEPOLIA_CHAIN_ID");
        address callbackContract = vm.envAddress("CALLBACK_CONTRACT_ADDRESS");
        uint256 cronTopic = 0x04463f7c1651e6b9774d7f85c85bb94654e3c46ca79b0c16fb16d4183307b687; // ~1 minute

        // Deploy the Callback contract on Arbitrum Sepolia
        CronReactive cronReactive = new CronReactive{value: 0.1 ether}(service,cronTopic,callbackChainId,callbackContract);
        console.log("Cron Reactive Contract Address:", address(cronReactive));

        vm.stopBroadcast();
    }
}
