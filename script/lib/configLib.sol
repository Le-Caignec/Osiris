// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";

library ConfigLib {
    using stdJson for string;

    Vm constant _VM = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    struct ReactiveNetworkConfig {
        address reactiveSystemContract;
        address reactiveContract;
        uint256 cronTopic;
    }

    struct DestinationNetworkConfig {
        uint256 chainId;
        string rpcUrl;
        // Uniswap V4 specific
        address weth;
        address usdc;
        address uniswapUniversalRouter;
        address uniswapPoolManager;
        address uniswapPermit2;
        // Callback specific
        address callbackProxyContract;
        address callbackContract;
    }

    function readDestinationNetworkConfig(string memory chain)
        internal
        view
        returns (DestinationNetworkConfig memory a)
    {
        string memory path = "config/config.json";
        string memory json = _VM.readFile(path);
        string memory prefix = string.concat(".chains.", chain);
        a.chainId = json.readUint(string.concat(prefix, ".chainId"));
        a.rpcUrl = json.readString(string.concat(prefix, ".rpcUrl"));
        a.weth = json.readAddress(string.concat(prefix, ".weth"));
        a.usdc = json.readAddress(string.concat(prefix, ".usdc"));
        a.uniswapUniversalRouter = json.readAddress(string.concat(prefix, ".uniswapUniversalRouter"));
        a.uniswapPoolManager = json.readAddress(string.concat(prefix, ".uniswapPoolManager"));
        a.uniswapPermit2 = json.readAddress(string.concat(prefix, ".uniswapPermit2"));
        a.callbackProxyContract = json.readAddress(string.concat(prefix, ".callbackProxyContract"));
        a.callbackContract = json.readAddress(string.concat(prefix, ".callbackContract"));
    }

    // Reads the reactive addresses for the "lasna" chain
    function readReactiveNetworkConfig() internal view returns (ReactiveNetworkConfig memory a) {
        string memory path = "config/config.json";
        string memory json = _VM.readFile(path);
        string memory prefix = string.concat(".chains.", "lasna");
        a.reactiveSystemContract = json.readAddress(string.concat(prefix, ".reactiveSystemContract"));
        a.reactiveContract = json.readAddress(string.concat(prefix, ".reactiveContract"));
        a.cronTopic = json.readUint(string.concat(prefix, ".cronTopic"));
    }
}
