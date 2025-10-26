// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {CronReactive} from "../src/CronReactive.sol";
import {Osiris} from "../src/Osiris.sol";
import {ConfigLib} from "./lib/configLib.sol";

interface ICallbackProxy {
    function depositTo(address payee) external payable;
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
        Osiris osirisContract = new Osiris(universalRouter, permit2, usdc, callbackSender, ethUsdFeed);
        console.log("Osiris Contract Address:", address(osirisContract));

        // Fund the callback proxy if FUND_AMOUNT is set
        uint256 fundAmount = vm.envOr("FUND_AMOUNT", uint256(0));
        if (fundAmount > 0) {
            console.log("Funding callback proxy with", fundAmount, "wei");
            ICallbackProxy(callbackSender).depositTo{value: fundAmount}(address(osirisContract));
            console.log("Successfully funded callback proxy");
        } else {
            console.log("No funding requested (FUND_AMOUNT not set or is 0)");
        }

        vm.stopBroadcast();
    }
}
