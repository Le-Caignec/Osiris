// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {UniversalRouter} from "@uniswap/universal-router/contracts/UniversalRouter.sol";
import {Commands} from "@uniswap/universal-router/contracts/libraries/Commands.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IV4Router} from "@uniswap/v4-periphery/src/interfaces/IV4Router.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IPermit2} from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract UniV4Swap is ReentrancyGuard {
    using StateLibrary for IPoolManager;
    using CurrencyLibrary for Currency;
    using SafeERC20 for IERC20;

    UniversalRouter public immutable UNISWAP_ROUTER;
    IPermit2 public immutable UNISWAP_PERMIT2;

    // ---------- Custom Errors ----------
    error InsufficientOutput(uint256 received, uint256 minRequired);
    error NativeTransferFailed();

    constructor(address _router, address _permit2) {
        UNISWAP_ROUTER = UniversalRouter(payable(_router));
        UNISWAP_PERMIT2 = IPermit2(_permit2);
    }

    function swapExactInputSingle(PoolKey memory key, bool zeroForOne, uint128 amountIn, uint128 minAmountOut)
        public
        payable
        nonReentrant
        returns (uint256 amountOut)
    {
        // pick input/output based on direction
        Currency inCurrency = zeroForOne ? key.currency0 : key.currency1;
        Currency outCurrency = zeroForOne ? key.currency1 : key.currency0;

        // If input is ERC20, ensure Permit2 can pull funds from THIS contract to the PoolManager
        if (!inCurrency.isAddressZero()) {
            address tokenIn = Currency.unwrap(inCurrency);
            // Approve Permit2 (idempotent for tests)
            IERC20(tokenIn).approve(address(UNISWAP_PERMIT2), type(uint256).max);
            // Permit2 -> UniversalRouter allowance
            UNISWAP_PERMIT2.approve(
                tokenIn, address(UNISWAP_ROUTER), type(uint160).max, uint48(block.timestamp + 365 days)
            );
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
        if (inCurrency.isAddressZero()) {
            // When paying with native, the router needs ETH on this call
            // Expect msg.value == amountIn (or at least enough to cover it)
            require(msg.value >= amountIn, "Insufficient msg.value for native input");
            UNISWAP_ROUTER.execute{value: amountIn}(commands, inputs, deadline);
        } else {
            UNISWAP_ROUTER.execute(commands, inputs, deadline);
        }

        // Measure output on this contract (direction-aware)
        amountOut = outCurrency.balanceOf(address(this));
        if (amountOut < minAmountOut) {
            revert InsufficientOutput(amountOut, minAmountOut);
        }

        // Forward output to caller (both ERC20 and native supported)
        if (outCurrency.isAddressZero()) {
            (bool ok,) = msg.sender.call{value: amountOut}("");
            if (!ok) revert NativeTransferFailed();
        } else {
            IERC20(Currency.unwrap(outCurrency)).safeTransfer(msg.sender, amountOut);
        }
        return amountOut;
    }

    /// @notice Receive function to accept native ETH transfers
    receive() external payable virtual {}
}
