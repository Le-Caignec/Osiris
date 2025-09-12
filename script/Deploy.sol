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
        // address service = vm.envAddress("SERVICE_ADDRESS");
        // uint256 destinationChainId = vm.envUint("SEPOLIA_CHAIN_ID");
        // address callbackContractAddress = vm.envAddress("CALLBACK_CONTRACT_ADDRESS");
        address service = 0x0000000000000000000000000000000000fffFfF;
        uint256 destinationChainId = 11155111;
        address callbackContractAddress = 0x3f4F490060B883396CAdda837d84B9A54e17Cdeb;
        uint256 cronTopic = 0x04463f7c1651e6b9774d7f85c85bb94654e3c46ca79b0c16fb16d4183307b687; // ~1 minute

        // Deploy the Reactive contract on Lasna
        CronReactive cronReactive = new CronReactive{value: 0.1 ether}(service,cronTopic,destinationChainId,callbackContractAddress);
        console.log("Cron Reactive Contract Address:", address(cronReactive));

        vm.stopBroadcast();
    }
}
