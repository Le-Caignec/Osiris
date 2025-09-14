// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {UniV4Swap} from "../src/UniV4Swap.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "./mock/IWETH.sol";
import {ConfigLib} from "../script/lib/configLib.sol";

contract UniV4SwapTest is Test {
    // Loaded from config at setUp
    address private WETH;
    address private USDC;
    address private UNIVERSAL_ROUTER;
    address private POOL_MANAGER;
    address private PERMIT2;

    IWETH private weth;
    IERC20 private usdc;

    UniV4Swap private uni;
    address private user = makeAddr("user");

    uint24 constant FEE = 3000; // 0.3%
    int24 constant TICK_SPACING = 60;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        string memory chain = "ethereum";
        ConfigLib.UniswapV4Addresses memory config = ConfigLib.readUniswapV4Addresses(chain);

        WETH = config.weth;
        USDC = config.usdc;
        UNIVERSAL_ROUTER = config.universalRouter;
        POOL_MANAGER = config.poolManager;
        PERMIT2 = config.permit2;

        weth = IWETH(WETH);
        usdc = IERC20(USDC);

        uni = new UniV4Swap(UNIVERSAL_ROUTER, PERMIT2);

        vm.deal(user, 10 ether);
        vm.startPrank(user);
        weth.deposit{value: 2 ether}();
        vm.stopPrank();

        console.log("User WETH balance:", weth.balanceOf(user));
        console.log("User USDC balance:", usdc.balanceOf(user));

        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(UNIVERSAL_ROUTER, "UniversalRouter");
        vm.label(POOL_MANAGER, "PoolManager");
        vm.label(address(uni), "UniV4Swap");
        vm.label(user, "User");
    }

    // ########################
    // Helpers
    // ########################

    function _poolKeyWethUsdc() internal view returns (PoolKey memory) {
        address token0 = WETH < USDC ? WETH : USDC;
        address token1 = WETH < USDC ? USDC : WETH;
        return PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(0))
        });
    }

    function _poolKeyNativeUsdc() internal view returns (PoolKey memory) {
        return PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(USDC),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(0))
        });
    }

    // ########################
    // Pool ERC20 & ERC20
    // ########################

    // Swap WETH -> USDC
    function testSwapWETHForUSDC() public {
        vm.startPrank(user);

        uint128 amountIn = 0.1 ether;
        uint128 minAmountOut = 150 * 1e6;

        PoolKey memory poolKey = _poolKeyWethUsdc();
        bool zeroForOne = false; // WETH -> USDC

        uint256 wethBefore = weth.balanceOf(user);
        uint256 usdcBefore = usdc.balanceOf(user);

        console.log("=== Before Swap WETH->USDC ===");
        console.log("WETH:", wethBefore);
        console.log("USDC:", usdcBefore);

        bool sent = weth.transfer(address(uni), amountIn);
        assertTrue(sent, "WETH transfer failed");

        uint256 amountOut = uni.swapExactInputSingle(poolKey, zeroForOne, amountIn, minAmountOut);

        uint256 wethAfter = weth.balanceOf(user);
        uint256 usdcAfter = usdc.balanceOf(user);

        console.log("=== After Swap WETH->USDC ===");
        console.log("WETH:", wethAfter);
        console.log("USDC:", usdcAfter);
        console.log("Amount out:", amountOut);

        assertGt(amountOut, minAmountOut, "Output must be >= min");
        assertEq(wethAfter, wethBefore - amountIn, "User WETH must decrease by amountIn");
        assertGt(usdcAfter, usdcBefore, "User USDC must increase");

        vm.stopPrank();
    }

    // Swap USDC -> WETH
    function testSwapUSDCForWETH() public {
        deal(USDC, user, 5_000 * 1e6);
        vm.startPrank(user);

        uint128 amountIn = 2_000 * 1e6;
        uint128 minAmountOut = 0.3 ether;

        PoolKey memory poolKey = _poolKeyWethUsdc();
        bool zeroForOne = true; // USDC -> WETH

        uint256 usdcBefore = usdc.balanceOf(user);
        uint256 wethBefore = weth.balanceOf(user);

        console.log("=== Before Swap USDC->WETH ===");
        console.log("USDC:", usdcBefore);
        console.log("WETH:", wethBefore);

        bool sent = usdc.transfer(address(uni), amountIn);
        assertTrue(sent, "USDC transfer failed");

        uint256 amountOut = uni.swapExactInputSingle(poolKey, zeroForOne, amountIn, minAmountOut);

        uint256 usdcAfter = usdc.balanceOf(user);
        uint256 wethAfter = weth.balanceOf(user);

        console.log("=== After Swap USDC->WETH ===");
        console.log("USDC:", usdcAfter);
        console.log("WETH:", wethAfter);
        console.log("Amount out:", amountOut);

        assertGt(amountOut, minAmountOut, "Output must be >= min");
        assertEq(usdcAfter, usdcBefore - amountIn, "User USDC must decrease by amountIn");
        assertGt(wethAfter, wethBefore, "User WETH must increase");

        vm.stopPrank();
    }

    // ########################
    // Pool Native & ERC20
    // ########################

    function testSwapNativeForUSDC() public {
        vm.startPrank(user);

        uint128 amountIn = 0.25 ether;
        uint128 minAmountOut = 50 * 1e6;
        PoolKey memory poolKey = _poolKeyNativeUsdc();
        bool zeroForOne = true;

        uint256 nativeBefore = user.balance;
        uint256 usdcBefore = usdc.balanceOf(user);

        console.log("=== Before Swap NATIVE->USDC ===");
        console.log("NATIVE:", nativeBefore);
        console.log("USDC:", usdcBefore);

        uint256 amountOut = uni.swapExactInputSingle{value: amountIn}(poolKey, zeroForOne, amountIn, minAmountOut);

        uint256 nativeAfter = user.balance;
        uint256 usdcAfter = usdc.balanceOf(user);

        console.log("=== After Swap NATIVE->USDC ===");
        console.log("NATIVE:", nativeAfter);
        console.log("USDC:", usdcAfter);
        console.log("Amount out:", amountOut);

        assertGt(amountOut, minAmountOut, "Output must be >= min");
        assertEq(nativeAfter, nativeBefore - amountIn, "User ETH must decrease by amountIn");
        assertGt(usdcAfter, usdcBefore, "User USDC must increase");

        vm.stopPrank();
    }

    // Swap USDC -> Native (ETH)
    function testSwapUSDCForNative() public {
        // Fund user with USDC
        deal(USDC, user, 5_000 * 1e6);
        vm.startPrank(user);

        uint128 amountIn = 2_000 * 1e6; // 2,000 USDC
        uint128 minAmountOut = 0.05 ether; // conservative min ETH out
        PoolKey memory poolKey = _poolKeyNativeUsdc();
        bool zeroForOne = false; // USDC (currency1) -> Native (currency0)

        uint256 usdcBefore = usdc.balanceOf(user);
        uint256 nativeBefore = user.balance;

        console.log("=== Before Swap USDC->NATIVE ===");
        console.log("USDC:", usdcBefore);
        console.log("NATIVE:", nativeBefore);

        // Transfer USDC to the UniV4Swap contract which uses Permit2 to route funds
        bool sent = usdc.transfer(address(uni), amountIn);
        assertTrue(sent, "USDC transfer failed");

        uint256 amountOut = uni.swapExactInputSingle(poolKey, zeroForOne, amountIn, minAmountOut);

        uint256 usdcAfter = usdc.balanceOf(user);
        uint256 nativeAfter = user.balance;

        console.log("=== After Swap USDC->NATIVE ===");
        console.log("USDC:", usdcAfter);
        console.log("NATIVE:", nativeAfter);
        console.log("Amount out:", amountOut);

        assertGt(amountOut, minAmountOut, "Output must be >= min");
        assertEq(usdcAfter, usdcBefore - amountIn, "User USDC must decrease by amountIn");
        assertGt(nativeAfter, nativeBefore, "User ETH must increase");

        vm.stopPrank();
    }
}
