// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Callback} from "../src/Callback.sol";
import {CronReactive} from "../src/CronReactive.sol";
import {UniV4Swap} from "../src/UniV4Swap.sol";
import {ConfigLib} from "./lib/configLib.sol";

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

contract DeploySwap is Script {
    function run() external {
        string memory chain = vm.envString("CHAIN");
        ConfigLib.DestinationNetworkConfig memory config = ConfigLib.readDestinationNetworkConfig(chain);

        address universalRouter = config.uniswapUniversalRouter;
        address permit2 = config.uniswapPermit2;

        vm.startBroadcast();
        // Deploy the UniV4Swap contract on Sepolia
        address uniV4SwapContract = address(new UniV4Swap(universalRouter, permit2));
        console.log("UniV4Swap Contract Address (Sepolia):", uniV4SwapContract);
        vm.stopBroadcast();
    }
}

contract DeployCronReactive is Script {
    function run() external {
        string memory chain = vm.envString("CHAIN");
        ConfigLib.ReactiveNetworkConfig memory reactiveNetworkConfig = ConfigLib.readReactiveNetworkConfig();
        ConfigLib.DestinationNetworkConfig memory callbackConfig = ConfigLib.readDestinationNetworkConfig(chain);

        address service = reactiveNetworkConfig.reactiveSystemContract;
        uint256 cronTopic = reactiveNetworkConfig.cronTopic;
        uint256 destinationChainId = callbackConfig.chainId;
        address callbackContractAddress = callbackConfig.callbackContract;

        vm.startBroadcast();
        // Deploy the Reactive contract on Lasna
        CronReactive cronReactive =
            new CronReactive{value: 0.1 ether}(service, cronTopic, destinationChainId, callbackContractAddress);
        console.log("Cron Reactive Contract Address:", address(cronReactive));
        vm.stopBroadcast();
    }
}
