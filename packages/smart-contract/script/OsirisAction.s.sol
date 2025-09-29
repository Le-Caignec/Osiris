// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Osiris} from "../src/Osiris.sol";
import {ConfigLib} from "./lib/configLib.sol";

contract TriggerOsirisCallback is Script {
    function run() external {
        string memory chain = vm.envString("CHAIN");
        ConfigLib.DestinationNetworkConfig memory config = ConfigLib.readDestinationNetworkConfig(chain);
        address osirisContractAddress = config.callbackContract;
        address callbackSender = config.callbackProxyContract;

        vm.startBroadcast();
        // Deploy the Callback contract on Arbitrum Sepolia
        Osiris osiris = Osiris(payable(osirisContractAddress));
        osiris.callback(callbackSender);
        console.log("Paused CronReactive at address:", osirisContractAddress);
        vm.stopBroadcast();
    }
}
