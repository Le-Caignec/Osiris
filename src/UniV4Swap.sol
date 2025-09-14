// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {UniversalRouter} from "@uniswap/universal-router/contracts/UniversalRouter.sol";
import {Commands} from "@uniswap/universal-router/contracts/libraries/Commands.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IV4Router} from "@uniswap/v4-periphery/src/interfaces/IV4Router.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IPermit2} from "@uniswap/permit2/src/interfaces/IPermit2.sol";

contract UniV4Swap {
    using StateLibrary for IPoolManager;
    using CurrencyLibrary for Currency;

    UniversalRouter public immutable router;
    IPoolManager public immutable poolManager;
    IPermit2 public immutable permit2;

    constructor(address _router, address _poolManager, address _permit2) {
        router = UniversalRouter(payable(_router));
        poolManager = IPoolManager(_poolManager);
        permit2 = IPermit2(_permit2);
    }

    function swapExactInputSingle(PoolKey calldata key, bool zeroForOne, uint128 amountIn, uint128 minAmountOut)
        external
        returns (uint256 amountOut)
    {
        // pick input/output based on direction
        Currency inCurrency = zeroForOne ? key.currency0 : key.currency1;
        Currency outCurrency = zeroForOne ? key.currency1 : key.currency0;

        // If input is ERC20, ensure Permit2 can pull funds from THIS contract to the PoolManager
        if (!inCurrency.isAddressZero()) {
            address tokenIn = Currency.unwrap(inCurrency);
            // 1) ERC20 → Permit2 allowance (one-time max is fine for testing)
            IERC20(tokenIn).approve(address(permit2), type(uint256).max);
            // 2) Permit2 → PoolManager allowance (owner = this contract)
            permit2.approve(tokenIn, address(router), type(uint160).max, uint48(block.timestamp + 365 days));
        }
        // Encode the Universal Router command
        bytes memory commands = abi.encodePacked(uint8(Commands.V4_SWAP));
        bytes[] memory inputs = new bytes[](1);

        // Encode V4Router actions
        bytes memory actions =
            abi.encodePacked(uint8(Actions.SWAP_EXACT_IN_SINGLE), uint8(Actions.SETTLE_ALL), uint8(Actions.TAKE_ALL));

        // Prepare parameters for each action
        bytes[] memory params = new bytes[](3);
        params[0] = abi.encode(
            IV4Router.ExactInputSingleParams({
                poolKey: key,
                zeroForOne: zeroForOne,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                hookData: bytes("")
            })
        );
        params[1] = abi.encode(inCurrency, amountIn);
        params[2] = abi.encode(outCurrency, minAmountOut);

        // Combine actions and params into inputs
        inputs[0] = abi.encode(actions, params);

        // Execute the swap
        uint256 deadline = block.timestamp + 20;
        router.execute(commands, inputs, deadline);

        // Measure output on this contract (direction-aware)
        amountOut = outCurrency.balanceOf(address(this));
        require(amountOut >= minAmountOut, "Insufficient output amount");

        // Forward output to caller (both ERC20 and native supported)
        if (outCurrency.isAddressZero()) {
            (bool ok,) = msg.sender.call{value: amountOut}("");
            require(ok, "Native transfer failed");
        } else {
            IERC20(Currency.unwrap(outCurrency)).transfer(msg.sender, amountOut);
        }
        return amountOut;
    }
}
