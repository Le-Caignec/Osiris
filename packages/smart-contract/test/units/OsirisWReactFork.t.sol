// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OsirisMock} from "./mocks/OsirisMock.sol";
import {IOsiris} from "../../src/interfaces/IOsiris.sol";
import {IDIAOracle} from "../../src/interfaces/IDIAOracle.sol";
import {ConfigLib} from "../../script/lib/configLib.sol";

/// @title OsirisWReactForkTest
/// @notice End-to-end tests for wReact DCA on a Base mainnet fork.
///         Uses the REAL Uniswap V4 router, DIA Oracle, and USDC/wReact pool.
///         Run with: CHAIN=base forge test --match-contract OsirisWReactForkTest -vvv
contract OsirisWReactForkTest is Test {
    OsirisMock private vault;
    IERC20 private usdc;
    IERC20 private wReact;
    IDIAOracle private diaOracle;

    address private alice = vm.addr(0xA11CE);

    // Base mainnet addresses (read from config)
    address private usdcAddress;
    address private wReactAddress;
    address private diaOracleAddress;
    address private callbackSender;

    function setUp() public {
        // Fork Base mainnet
        ConfigLib.DestinationNetworkConfig memory cfg = ConfigLib.readDestinationNetworkConfig("base");
        vm.createSelectFork(cfg.rpcUrl);

        usdcAddress = cfg.usdc;
        wReactAddress = cfg.wReact;
        diaOracleAddress = cfg.diaOracle;
        callbackSender = cfg.callbackProxyContract;

        usdc = IERC20(usdcAddress);
        wReact = IERC20(wReactAddress);
        diaOracle = IDIAOracle(diaOracleAddress);

        // Deploy Osiris with REAL Base mainnet addresses
        vault = new OsirisMock(
            cfg.uniswapUniversalRouter,
            cfg.uniswapPermit2,
            usdcAddress,
            callbackSender,
            cfg.chainlinkEthUsdFeed,
            wReactAddress,
            diaOracleAddress
        );

        // Labels
        vm.label(address(vault), "Osiris");
        vm.label(usdcAddress, "USDC");
        vm.label(wReactAddress, "wReact");
        vm.label(diaOracleAddress, "DIAOracle");
        vm.label(alice, "Alice");

        vm.deal(alice, 10 ether);
    }

    // ============ DIA Oracle Tests ============

    function test_diaOracle_returnsValidReactPrice() public view {
        (uint128 price, uint128 timestamp) = diaOracle.getValue("REACT/USD");

        // Price should be non-zero and reasonable (between $0.001 and $10)
        assertGt(price, 100_000, "REACT price too low"); // > $0.001
        assertLt(price, 1_000_000_000, "REACT price too high"); // < $10
        // Timestamp should be non-zero (oracle has been updated at least once)
        assertGt(uint256(timestamp), 0, "DIA timestamp should be non-zero");
    }

    // ============ setPlanWithBudget wReact on Base ============

    function test_setPlan_wReact_onBaseFork() public {
        vm.prank(alice);
        vault.setPlanWithBudget(IOsiris.Frequency.Daily, 1e6, 0, false, IOsiris.TargetToken.WREACT);

        IOsiris.DcaPlan memory plan = vault.getUserPlan(alice);
        assertEq(uint8(plan.targetToken), uint8(IOsiris.TargetToken.WREACT));
        assertGt(plan.nextExecutionTimestamp, block.timestamp);
    }

    // ============ End-to-end: USDC -> wReact via real Uniswap V4 pool ============

    function test_callback_swaps_usdc_to_wReact_realPool() public {
        uint256 depositAmount = 5e6; // 5 USDC

        // Fund Alice with USDC
        deal(usdcAddress, alice, depositAmount);

        // Alice deposits USDC and sets wReact DCA plan
        vm.startPrank(alice);
        usdc.approve(address(vault), type(uint256).max);
        vault.depositUsdc(depositAmount);
        vault.setPlanWithBudget(IOsiris.Frequency.Daily, depositAmount, 0, false, IOsiris.TargetToken.WREACT);
        vm.stopPrank();

        // Warp past the first execution window
        vm.warp(block.timestamp + 2 days);

        // Authorize test contract for callback
        vault.addAuthorizedSenderForTesting(address(this));
        vault.setRvmIdForTesting(callbackSender);

        // Execute callback (real swap through Uniswap V4)
        vault.callback(callbackSender);

        // Verify Alice received wReact
        uint256 wReactAccrued = vault.getUserWReact(alice);
        assertGt(wReactAccrued, 0, "Alice should have received wReact from the swap");

        // Sanity check: 5 USDC at ~$0.022/wReact should give ~220 wReact (18 decimals)
        // Allow wide range for price fluctuation: between 10 and 10000 wReact
        assertGt(wReactAccrued, 10e18, "wReact amount suspiciously low");
        assertLt(wReactAccrued, 10_000e18, "wReact amount suspiciously high");

        // USDC should be fully consumed
        assertEq(vault.getUserUsdc(alice), 0, "All USDC should be consumed");
    }

    // ============ End-to-end: claim wReact after swap ============

    function test_claimToken_wReact_afterRealSwap() public {
        uint256 depositAmount = 2e6; // 2 USDC

        deal(usdcAddress, alice, depositAmount);

        vm.startPrank(alice);
        usdc.approve(address(vault), type(uint256).max);
        vault.depositUsdc(depositAmount);
        vault.setPlanWithBudget(IOsiris.Frequency.Daily, depositAmount, 0, false, IOsiris.TargetToken.WREACT);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);
        vault.addAuthorizedSenderForTesting(address(this));
        vault.setRvmIdForTesting(callbackSender);
        vault.callback(callbackSender);

        uint256 accrued = vault.getUserWReact(alice);
        assertGt(accrued, 0, "Should have accrued wReact");

        // Alice claims wReact
        uint256 aliceBefore = wReact.balanceOf(alice);
        vm.prank(alice);
        vault.claimToken(wReactAddress, accrued);

        assertEq(wReact.balanceOf(alice), aliceBefore + accrued, "Alice should hold claimed wReact");
        assertEq(vault.getUserWReact(alice), 0, "Vault balance should be 0 after claim");
    }

    // ============ Budget check with real DIA Oracle ============

    function test_callback_wReact_budgetCheck_withRealOracle() public {
        uint256 depositAmount = 1e6; // 1 USDC

        deal(usdcAddress, alice, depositAmount);

        vm.startPrank(alice);
        usdc.approve(address(vault), type(uint256).max);
        vault.depositUsdc(depositAmount);
        // Set maxBudget = $0.001 (100000 in 1e8 scale) -> REACT at ~$0.025 will exceed this budget
        vault.setPlanWithBudget(IOsiris.Frequency.Daily, depositAmount, 100_000, false, IOsiris.TargetToken.WREACT);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);
        vault.addAuthorizedSenderForTesting(address(this));
        vault.setRvmIdForTesting(callbackSender);
        vault.callback(callbackSender);

        // Should be skipped: REACT price (~$0.025) > budget ($0.001)
        assertEq(vault.getUserWReact(alice), 0, "Should not have received wReact (budget exceeded)");
        assertEq(vault.getUserUsdc(alice), depositAmount, "USDC should not be consumed");
    }

    function test_callback_wReact_budgetCheck_passes_withHighBudget() public {
        uint256 depositAmount = 1e6; // 1 USDC

        deal(usdcAddress, alice, depositAmount);

        vm.startPrank(alice);
        usdc.approve(address(vault), type(uint256).max);
        vault.depositUsdc(depositAmount);
        // Set maxBudget = $1.00 (1e8 in 1e8 scale) -> REACT at ~$0.025 is within budget
        vault.setPlanWithBudget(IOsiris.Frequency.Daily, depositAmount, 100_000_000, false, IOsiris.TargetToken.WREACT);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);
        vault.addAuthorizedSenderForTesting(address(this));
        vault.setRvmIdForTesting(callbackSender);
        vault.callback(callbackSender);

        assertGt(vault.getUserWReact(alice), 0, "Should have received wReact (within budget)");
        assertEq(vault.getUserUsdc(alice), 0, "USDC should be consumed");
    }

    // ============ Mixed: ETH + wReact users in same callback ============

    function test_callback_mixed_ethAndWReact_realSwaps() public {
        address bob = vm.addr(0xB0B);
        vm.label(bob, "Bob");
        vm.deal(bob, 10 ether);

        // Alice: 2 USDC -> ETH, Bob: 2 USDC -> wReact
        deal(usdcAddress, alice, 2e6);
        deal(usdcAddress, bob, 2e6);

        vm.startPrank(alice);
        usdc.approve(address(vault), type(uint256).max);
        vault.depositUsdc(2e6);
        vault.setPlanWithBudget(IOsiris.Frequency.Daily, 2e6, 0, false, IOsiris.TargetToken.ETH);
        vm.stopPrank();

        vm.startPrank(bob);
        usdc.approve(address(vault), type(uint256).max);
        vault.depositUsdc(2e6);
        vault.setPlanWithBudget(IOsiris.Frequency.Daily, 2e6, 0, false, IOsiris.TargetToken.WREACT);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);
        vault.addAuthorizedSenderForTesting(address(this));
        vault.setRvmIdForTesting(callbackSender);
        vault.callback(callbackSender);

        // Alice: should have ETH, no wReact
        assertGt(vault.getUserNative(alice), 0, "Alice should have received ETH");
        assertEq(vault.getUserWReact(alice), 0, "Alice should not have wReact");

        // Bob: should have wReact, no ETH
        assertGt(vault.getUserWReact(bob), 0, "Bob should have received wReact");
        assertEq(vault.getUserNative(bob), 0, "Bob should not have ETH");

        // Both USDC consumed
        assertEq(vault.getUserUsdc(alice), 0, "Alice USDC consumed");
        assertEq(vault.getUserUsdc(bob), 0, "Bob USDC consumed");
    }
}
