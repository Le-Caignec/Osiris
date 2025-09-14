// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {UniV4Swap} from "../src/UniV4Swap.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "./mock/IWETH.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

address constant UNIVERSAL_ROUTER = 0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af;
address constant POOL_MANAGER = 0x000000000004444c5dc75cB358380D2e3dE08A90;
address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

contract UniV4SwapTest is Test {
    IWETH private weth = IWETH(WETH);
    IERC20 private usdc = IERC20(USDC);

    UniV4Swap private uni;
    address private user = makeAddr("user");

    // Pool parameters (v4)
    uint24 constant FEE = 3000; // 0.3%
    int24 constant TICK_SPACING = 60;

    function setUp() public {
        // Fork mainnet correctement (create + select)
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));

        // Déploie le contrat
        uni = new UniV4Swap(UNIVERSAL_ROUTER, PERMIT2);

        // Alimente l'utilisateur en ETH et wrap en WETH
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

    function _poolKeyWethUsdc() internal pure returns (PoolKey memory) {
        // Respecte l'ordre address croissant: currency0 < currency1
        return PoolKey({
            currency0: Currency.wrap(WETH < USDC ? WETH : USDC),
            currency1: Currency.wrap(WETH < USDC ? USDC : WETH),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(0))
        });
    }

    function _poolKeyNativeUsdc() internal pure returns (PoolKey memory) {
        // Respecte l'ordre address croissant: currency0 < currency1
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
