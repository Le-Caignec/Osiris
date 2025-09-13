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
        uni = new UniV4Swap(UNIVERSAL_ROUTER, POOL_MANAGER, PERMIT2);

        // Alimente l'utilisateur en ETH et wrap en WETH
        vm.deal(user, 10 ether);
        vm.startPrank(user);
        weth.deposit{value: 2 ether}();
        vm.stopPrank();

        console.log("User WETH balance:", weth.balanceOf(user));
        console.log("User USDC balance:", usdc.balanceOf(user));

        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(UNIVERSAL_ROUTER, "Universal Router");
        vm.label(POOL_MANAGER, "Pool Manager");
        vm.label(address(uni), "UniV4Swap");
        vm.label(user, "User");
    }

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

    function testSwapWETHForUSDC() public {
        vm.startPrank(user);

        // 0.1 WETH in (commentaire corrigé)
        uint128 amountIn = 0.1 ether;
        // Min out plausible pour 0.1 WETH (à ajuster selon le block forké)
        uint128 minAmountOut = 150 * 1e6; // 150 USDC

        PoolKey memory poolKey = _poolKeyWethUsdc();

        // Avec USDC < WETH -> currency0=USDC, currency1=WETH.
        // On veut WETH -> USDC => oneForZero => zeroForOne = false
        bool zeroForOne = false;

        // Balances avant
        uint256 wethBefore = weth.balanceOf(user);
        uint256 usdcBefore = usdc.balanceOf(user);

        console.log("=== Before Swap WETH->USDC ===");
        console.log("WETH:", wethBefore);
        console.log("USDC:", usdcBefore);

        // En option A: le contrat paie => transfère l'input vers le contrat
        // (approve non nécessaire mais inoffensif)
        weth.approve(address(uni), amountIn);
        weth.transfer(address(uni), amountIn);

        // Exécute le swap (le contrat doit forward l'output au msg.sender pour que les assertions passent)
        uint256 amountOut = uni.swapExactInputSingle(poolKey, zeroForOne, amountIn, minAmountOut);

        // Balances après
        uint256 wethAfter = weth.balanceOf(user);
        uint256 usdcAfter = usdc.balanceOf(user);

        console.log("=== After Swap WETH->USDC ===");
        console.log("WETH:", wethAfter);
        console.log("USDC:", usdcAfter);
        console.log("Amount out:", amountOut);

        // Assertions
        assertGt(amountOut, minAmountOut, "Output must be >= min");
        // Le user a envoyé amountIn au contrat avant le swap => son WETH diminue de amountIn
        assertEq(wethAfter, wethBefore - amountIn, "User WETH must decrease by amountIn");
        // Si le contrat forward l'output, le user reçoit l'USDC
        assertGt(usdcAfter, usdcBefore, "User USDC must increase");

        vm.stopPrank();
    }

    // function testSwapUSDCForWETH() public {
    //     // Approvisionne l'utilisateur en USDC depuis un whale
    //     address usdcWhale = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503; // exemple
    //     vm.startPrank(usdcWhale);
    //     usdc.transfer(user, 5_000 * 1e6);
    //     vm.stopPrank();

    //     vm.startPrank(user);

    //     uint128 amountIn = 2_000 * 1e6; // 2000 USDC
    //     uint128 minAmountOut = 0.3 ether; // min 0.3 WETH (à ajuster si besoin)

    //     PoolKey memory poolKey = _poolKeyWethUsdc();

    //     // currency0=USDC, currency1=WETH ; on veut USDC -> WETH
    //     // => zeroForOne = true
    //     bool zeroForOne = true;

    //     uint256 usdcBefore = usdc.balanceOf(user);
    //     uint256 wethBefore = weth.balanceOf(user);

    //     console.log("=== Before Swap USDC->WETH ===");
    //     console.log("USDC:", usdcBefore);
    //     console.log("WETH:", wethBefore);

    //     // Option A: le contrat paie => transfère l'input vers le contrat
    //     usdc.approve(address(uni), amountIn);
    //     usdc.transfer(address(uni), amountIn);

    //     uint256 amountOut = uni.swapExactInputSingle(poolKey, zeroForOne, amountIn, minAmountOut);

    //     uint256 usdcAfter = usdc.balanceOf(user);
    //     uint256 wethAfter = weth.balanceOf(user);

    //     console.log("=== After Swap USDC->WETH ===");
    //     console.log("USDC:", usdcAfter);
    //     console.log("WETH:", wethAfter);
    //     console.log("Amount out:", amountOut);

    //     assertGt(amountOut, minAmountOut, "Output must be >= min");
    //     assertEq(usdcAfter, usdcBefore - amountIn, "User USDC must decrease by amountIn");
    //     assertGt(wethAfter, wethBefore, "User WETH must increase");

    //     vm.stopPrank();
    // }
}
