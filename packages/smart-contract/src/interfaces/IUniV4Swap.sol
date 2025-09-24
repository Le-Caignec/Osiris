// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

interface IUniV4Swap {
    // Errors
    error InsufficientOutput(uint256 received, uint256 minRequired);
    error NativeTransferFailed();

    /**
     * Swap exactly amountIn along a single v4 pool and forward the output to the caller.
     * @param key Uniswap v4 PoolKey for the pool to trade on.
     * @param zeroForOne true for currency0->currency1, false for currency1->currency0.
     * @param amountIn exact input amount.
     * @param minAmountOut minimum acceptable output (slippage protection).
     * @return amountOut exact amount received (and forwarded to caller).
     */
    function swapExactInputSingle(PoolKey calldata key, bool zeroForOne, uint128 amountIn, uint128 minAmountOut)
        external
        payable
        returns (uint256 amountOut);
}
