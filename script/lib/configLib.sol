// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";

library ConfigLib {
    using stdJson for string;

    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    struct UniswapV4Addresses {
        address weth;
        address usdc;
        address universalRouter;
        address poolManager;
        address permit2;
    }

    function readUniswapV4Addresses(string memory chain) internal view returns (UniswapV4Addresses memory a) {
        string memory path = "config/config.json";
        string memory json = vm.readFile(path);
        string memory prefix = string.concat(".chains.", chain);
        a.weth = json.readAddress(string.concat(prefix, ".weth"));
        a.usdc = json.readAddress(string.concat(prefix, ".usdc"));
        a.universalRouter = json.readAddress(string.concat(prefix, ".uniswapUniversalRouter"));
        a.poolManager = json.readAddress(string.concat(prefix, ".uniswapPoolManager"));
        a.permit2 = json.readAddress(string.concat(prefix, ".uniswapPermit2"));
    }
}
