// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {UniV4Swap} from "../../src/UniV4Swap.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "./mocks/IWETH.sol";
import {ConfigLib} from "../../script/lib/configLib.sol";

contract UniV4SwapTest is Test {
    // Loaded from config at setUp
    address private wethAddress;
    address private usdcAddress;
    address private universalRouter;
    address private poolManager;
    address private permit2;

    IWETH private weth;
    IERC20 private usdc;

    UniV4Swap private uni;
    address private user = makeAddr("user");

    uint24 constant FEE = 3000; // 0.3%
    int24 constant TICK_SPACING = 60;

    function setUp() public {
        string memory chain = vm.envOr("CHAIN", string("ethereum"));
        ConfigLib.DestinationNetworkConfig memory config = ConfigLib.readDestinationNetworkConfig(chain);
        vm.createSelectFork(config.rpcUrl);

        wethAddress = config.weth;
        usdcAddress = config.usdc;
        universalRouter = config.uniswapUniversalRouter;
        poolManager = config.uniswapPoolManager;
        permit2 = config.uniswapPermit2;

        weth = IWETH(wethAddress);
        usdc = IERC20(usdcAddress);

        uni = new UniV4Swap(universalRouter, permit2);

        vm.deal(user, 10 ether);
        vm.startPrank(user);
        weth.deposit{value: 2 ether}();
        vm.stopPrank();

        console.log("User WETH balance:", weth.balanceOf(user));
        console.log("User USDC balance:", usdc.balanceOf(user));

        vm.label(wethAddress, "WETH");
        vm.label(usdcAddress, "USDC");
        vm.label(universalRouter, "UniversalRouter");
        vm.label(poolManager, "PoolManager");
        vm.label(address(uni), "UniV4Swap");
        vm.label(user, "User");
    }

    // ########################
    // Helpers
    // ########################

    function _poolKeyWethUsdc() internal view returns (PoolKey memory) {
        address token0 = wethAddress < usdcAddress ? wethAddress : usdcAddress;
        address token1 = wethAddress < usdcAddress ? usdcAddress : wethAddress;
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
            currency1: Currency.wrap(usdcAddress),
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
        vm.skip(block.chainid == 11155111, "Skip on Sepolia fork due to low liquidity");
        vm.startPrank(user);

        uint128 amountIn = 0.001 ether; // Reduce amount to minimize price impact
        uint128 minAmountOut = 3000; // Reduce min amount accordingly

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
        vm.skip(block.chainid == 11155111, "Skip on Sepolia fork due to low liquidity");

        deal(usdcAddress, user, 5_000 * 1e6);
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
        deal(usdcAddress, user, 5_000 * 1e6);
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
