// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {BasicDemoL1Contract} from "../src/BasicDemoL1Contract.sol";
import {BasicDemoL1Callback} from "../src/BasicDemoL1Callback.sol";
import {BasicDemoReactiveContract} from "../src/BasicDemoReactiveContract.sol";

contract DeploySource is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy the Origin contract on Sepolia
        BasicDemoL1Contract originContract = new BasicDemoL1Contract();
        console.log("Origin Contract Address (Sepolia):", address(originContract));

        vm.stopBroadcast();
    }
}

contract DeployDestination is Script {
    function run() external {
        vm.startBroadcast();
        address callbackProxyAddress = vm.envAddress("CALLBACK_PROXY_ADDRESS");
        address service = vm.envAddress("REACTIVE_NETWORK_SYSTEM_CONTRACT_ADDRESS");
        uint256 originChainId = vm.envUint("ORIGIN_CHAIN_ID");
        uint256 destinationChainId = vm.envUint("DESTINATION_CHAIN_ID");
        address originContract = vm.envAddress("ORIGIN_CONTRACT_ADDRESS");

        uint256 eventTopic0 = 0x8cabf31d2b1b11ba52dbb302817a3c9c83e4b2a5194d35121ab1354d69f6a4cb; //TODO : do not hardcode this
        // Deploy the Callback contract on Arbitrum Sepolia
        BasicDemoL1Callback callback = new BasicDemoL1Callback{value: 0.05 ether}(callbackProxyAddress);
        console.log("Callback Contract Address (Arbitrum Sepolia):", address(callback));

        // Deploy the Reactive contract on Arbitrum Sepolia
        BasicDemoReactiveContract reactiveContract = new BasicDemoReactiveContract(
            service, originChainId, destinationChainId, originContract, eventTopic0, address(callback)
        );
        console.log("Reactive Contract Address (Arbitrum Sepolia):", address(reactiveContract));

        vm.stopBroadcast();
    }
}
