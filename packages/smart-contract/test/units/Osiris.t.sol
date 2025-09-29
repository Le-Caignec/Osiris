// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OsirisMock} from "./mocks/OsirisMock.sol";
import {IOsiris} from "../../src/interfaces/IOsiris.sol";
import {ConfigLib} from "../../script/lib/configLib.sol";
import {UniV4SwapMock} from "./mocks/UniV4SwapMock.sol";

contract OsirisTest is Test {
    // config-driven addresses
    address private universalRouter;
    address private permit2;
    address private usdcAddress;
    address private callbackSender;

    IERC20 private usdc;
    OsirisMock private vault;
    UniV4SwapMock private routerMock;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    // Events mirrored from Osiris
    event DepositedUSDC(address indexed user, uint256 amount);
    event WithdrawnUSDC(address indexed user, uint256 amount);
    event ClaimedNative(address indexed user, uint256 amount);
    event PlanUpdated( // changed from uint64 to uint256 to match contract
    address indexed user, IOsiris.Frequency freq, uint256 amountPerPeriod, uint256 nextExecutionTimestamp);
    event CallbackProcessed(uint256 eligibleCount, uint256 totalUsdcIn, uint256 nativeOut);

    function setUp() public {
        // Read from config.json like in UniV4Swap tests
        string memory chain = vm.envOr("CHAIN", string("ethereum"));
        ConfigLib.DestinationNetworkConfig memory cfg = ConfigLib.readDestinationNetworkConfig(chain);
        vm.createSelectFork(cfg.rpcUrl);

        // Use a local UniV4SwapMock to make swap outputs deterministic
        routerMock = new UniV4SwapMock();
        universalRouter = address(routerMock);
        permit2 = cfg.uniswapPermit2;
        usdcAddress = cfg.usdc;
        callbackSender = cfg.callbackProxyContract;

        usdc = IERC20(usdcAddress);
        vault = new OsirisMock(universalRouter, permit2, usdcAddress, callbackSender);

        // labels for nicer traces
        vm.label(address(vault), "Osiris");
        vm.label(usdcAddress, "USDC");
        vm.label(callbackSender, "CallbackSender");
        vm.label(universalRouter, "UniV4SwapMock");
        vm.label(permit2, "Permit2");

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    // -----------------------------
    // deposit / withdraw with real USDC
    // -----------------------------
    function test_depositUsdc_recordsVaultBalance_andEmits() public {
        deal(usdcAddress, alice, 100e6);

        vm.startPrank(alice);
        usdc.approve(address(vault), 100e6);
        vm.expectEmit(true, false, false, true);
        emit DepositedUSDC(alice, 100e6);
        vault.depositUsdc(100e6);
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(vault)), 100e6, "vault should hold deposited USDC");
    }

    function test_withdrawUsdc_transfers_andEmits() public {
        // seed vault with user deposit
        deal(usdcAddress, alice, 500e6);
        vm.startPrank(alice);
        usdc.approve(address(vault), 500e6);
        vault.depositUsdc(500e6);

        uint256 beforeVault = usdc.balanceOf(address(vault));
        uint256 beforeUser = usdc.balanceOf(alice);

        vm.expectEmit(true, false, false, true);
        emit WithdrawnUSDC(alice, 120e6);
        vault.withdrawUsdc(120e6);
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(vault)), beforeVault - 120e6);
        assertEq(usdc.balanceOf(alice), beforeUser + 120e6);
    }

    function test_withdrawUsdc_revertsOnZero() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IOsiris.AmountZero.selector));
        vault.withdrawUsdc(0);
    }

    function test_withdrawUsdc_revertsOnInsufficient() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IOsiris.InsufficientUSDC.selector));
        vault.withdrawUsdc(1);
    }

    function test_depositUsdc_revertsOnZero() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IOsiris.AmountZero.selector));
        vault.depositUsdc(0);
    }

    // -----------------------------
    // Plan lifecycle (assert via events)
    // -----------------------------
    function test_setPlan_emitsAndActivates() public {
        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit PlanUpdated(alice, IOsiris.Frequency.Daily, 10e6, 0);
        vault.setPlan(IOsiris.Frequency.Daily, 10e6);
    }

    function test_setPlan_reverts_onZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IOsiris.AmountZero.selector));
        vault.setPlan(IOsiris.Frequency.Daily, 0);
    }

    function test_pause_and_resume_emitUpdates() public {
        vm.prank(alice);
        vault.setPlan(IOsiris.Frequency.Weekly, 5e6);

        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit PlanUpdated(alice, IOsiris.Frequency.Weekly, 5e6, 0);
        vault.pausePlan();

        vm.warp(block.timestamp + 15 days);
        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit PlanUpdated(alice, IOsiris.Frequency.Weekly, 5e6, 0);
        vault.resumePlan();
    }

    // -----------------------------
    // Claim native (expect revert without accrued native)
    // -----------------------------
    function test_claimNative_revertsOnZero() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IOsiris.AmountZero.selector));
        vault.claimNative(0);
    }

    function test_claimNative_revertsOnInsufficient() public {
        vm.prank(alice);
        vm.expectRevert(); // generic require in implementation (insufficient native)
        vault.claimNative(1);
    }

    // -----------------------------
    // Callback distribution tests (using dummy router output)
    // -----------------------------
    function test_callback_distributes_native_proRata_twoEligible_and_updatesUsdc() public {
        // Mock will output exactly 1 ether to distribute
        routerMock.setMockOut(1 ether);
        // Seed vault with native so claims can transfer
        vm.deal(address(vault), 1 ether);

        // Alice: 10 USDC, Bob: 30 USDC per period; both Daily and eligible
        deal(usdcAddress, alice, 20e6);
        deal(usdcAddress, bob, 60e6);

        vm.startPrank(alice);
        IERC20(usdcAddress).approve(address(vault), type(uint256).max);
        vault.depositUsdc(20e6);
        vault.setPlan(IOsiris.Frequency.Daily, 10e6);
        vm.stopPrank();

        vm.startPrank(bob);
        IERC20(usdcAddress).approve(address(vault), type(uint256).max);
        vault.depositUsdc(60e6);
        vault.setPlan(IOsiris.Frequency.Daily, 30e6);
        vm.stopPrank();

        // Make both eligible
        vm.warp(block.timestamp + 2 days);

        // Authorize test address for callback
        vault.addAuthorizedSenderForTesting(address(this));
        vault.setRvmIdForTesting(callbackSender);

        // Trigger
        vault.callback(callbackSender);

        // Expected pro-rata: totalIn = 40e6; alice gets 1e18 * 10/40, bob gets remainder
        uint256 expectedAlice = (1 ether * 10e6) / 40e6;
        uint256 expectedBob = 1 ether - expectedAlice;

        // Users claim their accrued native
        uint256 aliceEthBefore = alice.balance;
        vm.prank(alice);
        vault.claimNative(expectedAlice);
        assertEq(alice.balance, aliceEthBefore + expectedAlice, "Alice should receive expected ETH");

        uint256 bobEthBefore = bob.balance;
        vm.prank(bob);
        vault.claimNative(expectedBob);
        assertEq(bob.balance, bobEthBefore + expectedBob, "Bob should receive expected ETH");

        // Alice and Bob each had exactly their per-period amounts consumed; attempting to withdraw full deposits should fail
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IOsiris.InsufficientUSDC.selector));
        vault.withdrawUsdc(20e6);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IOsiris.InsufficientUSDC.selector));
        vault.withdrawUsdc(60e6);
    }

    function test_callback_skips_ineligible_weekly_user_keepsUsdc_and_daily_getsAllEth() public {
        // Mock will output 2 ether; only Alice daily is eligible, so she gets all
        routerMock.setMockOut(2 ether);
        vm.deal(address(vault), 2 ether);

        // Alice daily plan
        deal(usdcAddress, alice, 10e6);
        vm.startPrank(alice);
        IERC20(usdcAddress).approve(address(vault), type(uint256).max);
        vault.depositUsdc(10e6);
        vault.setPlan(IOsiris.Frequency.Daily, 10e6);
        vm.stopPrank();

        // Bob weekly plan (ineligible at +1 day)
        deal(usdcAddress, bob, 30e6);
        vm.startPrank(bob);
        IERC20(usdcAddress).approve(address(vault), type(uint256).max);
        vault.depositUsdc(30e6);
        vault.setPlan(IOsiris.Frequency.Weekly, 30e6);
        vm.stopPrank();

        // Only Alice becomes eligible
        vm.warp(block.timestamp + 1 days + 1);

        // Authorize test address for callback
        vault.addAuthorizedSenderForTesting(address(this));
        vault.setRvmIdForTesting(callbackSender);

        // Trigger
        vault.callback(callbackSender);

        // Alice should be able to claim full mocked output
        uint256 aliceEthBefore = alice.balance;
        vm.prank(alice);
        vault.claimNative(2 ether);
        assertEq(alice.balance, aliceEthBefore + 2 ether, "Alice should receive full ETH output");

        // Bob should have no native to claim
        vm.prank(bob);
        vm.expectRevert(); // insufficient native
        vault.claimNative(1 wei);

        // Bob should still be able to withdraw his full USDC deposit (not swapped)
        uint256 bobVaultUsdcBefore = IERC20(usdcAddress).balanceOf(address(vault));
        vm.prank(bob);
        vault.withdrawUsdc(30e6);
        assertEq(
            IERC20(usdcAddress).balanceOf(address(vault)),
            bobVaultUsdcBefore - 30e6,
            "Vault USDC reduced by Bob's withdrawal"
        );
    }

    // -----------------------------
    // Getter tests
    // -----------------------------
    function test_getters_default_zero() public view {
        assertEq(vault.getTotalUsdc(), 0, "total should start at 0");
        assertEq(vault.getUserUsdc(alice), 0, "alice usdc should be 0");
        assertEq(vault.getUserNative(alice), 0, "alice native should be 0");
    }

    function test_getUserUsdc_and_getTotalUsdc_afterDeposits() public {
        deal(usdcAddress, alice, 150e6);
        deal(usdcAddress, bob, 250e6);

        vm.startPrank(alice);
        usdc.approve(address(vault), type(uint256).max);
        vault.depositUsdc(150e6);
        vm.stopPrank();

        vm.startPrank(bob);
        usdc.approve(address(vault), type(uint256).max);
        vault.depositUsdc(250e6);
        vm.stopPrank();

        assertEq(vault.getUserUsdc(alice), 150e6, "alice usdc mismatch");
        assertEq(vault.getUserUsdc(bob), 250e6, "bob usdc mismatch");
        assertEq(vault.getTotalUsdc(), 400e6, "total usdc mismatch");
    }

    function test_getUserNative_afterCallbackDistribution() public {
        // setup mock output
        routerMock.setMockOut(5 ether);
        vm.deal(address(vault), 5 ether);

        // Alice 40, Bob 60 -> total 100 units => pro‑rata 40% / 60%
        deal(usdcAddress, alice, 80e6);
        deal(usdcAddress, bob, 120e6);

        vm.startPrank(alice);
        usdc.approve(address(vault), type(uint256).max);
        vault.depositUsdc(80e6);
        vault.setPlan(IOsiris.Frequency.Daily, 40e6);
        vm.stopPrank();

        vm.startPrank(bob);
        usdc.approve(address(vault), type(uint256).max);
        vault.depositUsdc(120e6);
        vault.setPlan(IOsiris.Frequency.Daily, 60e6);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);

        // Authorize test address for callback
        vault.addAuthorizedSenderForTesting(address(this));
        vault.setRvmIdForTesting(address(0));

        vault.callback(address(0));

        uint256 aliceExpected = (5 ether * 40e6) / 100e6;
        uint256 bobExpected = 5 ether - aliceExpected;

        assertEq(vault.getUserNative(alice), aliceExpected, "alice native mismatch");
        assertEq(vault.getUserNative(bob), bobExpected, "bob native mismatch");
        // Total USDC should have decreased by executed amounts (40e6 + 60e6)
        assertEq(vault.getTotalUsdc(), (80e6 + 120e6) - 100e6, "total usdc after callback mismatch");
    }

    // -----------------------------
    // getUserPlan test
    // -----------------------------
    function test_getUserPlan() public {
        // Test default empty plan
        IOsiris.DcaPlan memory emptyPlan = vault.getUserPlan(alice);
        assertEq(uint8(emptyPlan.freq), 0, "default frequency should be Daily (0)");
        assertEq(emptyPlan.amountPerPeriod, 0, "default amount should be 0");
        assertEq(emptyPlan.nextExecutionTimestamp, 0, "default timestamp should be 0");

        // Test after setting a plan
        vm.prank(alice);
        vault.setPlan(IOsiris.Frequency.Weekly, 25e6);

        IOsiris.DcaPlan memory activePlan = vault.getUserPlan(alice);
        assertEq(uint8(activePlan.freq), uint8(IOsiris.Frequency.Weekly), "frequency should be Weekly (1)");
        assertEq(activePlan.amountPerPeriod, 25e6, "amount should be 25e6");
        assertGt(activePlan.nextExecutionTimestamp, block.timestamp, "next execution should be in future");

        // Test after pausing plan
        vm.prank(alice);
        vault.pausePlan();

        IOsiris.DcaPlan memory pausedPlan = vault.getUserPlan(alice);
        assertEq(uint8(pausedPlan.freq), uint8(IOsiris.Frequency.Weekly), "frequency should remain Weekly");
        assertEq(pausedPlan.amountPerPeriod, 25e6, "amount should remain 25e6");
        assertEq(pausedPlan.nextExecutionTimestamp, 0, "timestamp should be 0 (inactive)");

        // Test after resuming plan
        vm.warp(block.timestamp + 5 days);
        vm.prank(alice);
        vault.resumePlan();

        IOsiris.DcaPlan memory resumedPlan = vault.getUserPlan(alice);
        assertEq(uint8(resumedPlan.freq), uint8(IOsiris.Frequency.Weekly), "frequency should remain Weekly");
        assertEq(resumedPlan.amountPerPeriod, 25e6, "amount should remain 25e6");
        assertGt(resumedPlan.nextExecutionTimestamp, block.timestamp, "next execution should be scheduled");
    }

    // -----------------------------
    // setPlan frequency change test
    // -----------------------------
    function test_setPlan_frequencyChangeUpdatesTimestamp() public {
        // Set initial Daily plan
        vm.prank(alice);
        vault.setPlan(IOsiris.Frequency.Daily, 50e6);

        IOsiris.DcaPlan memory dailyPlan = vault.getUserPlan(alice);
        uint256 dailyTimestamp = dailyPlan.nextExecutionTimestamp;
        assertEq(uint8(dailyPlan.freq), uint8(IOsiris.Frequency.Daily), "should be Daily");
        assertGt(dailyTimestamp, block.timestamp, "daily timestamp should be in future");

        // Wait some time
        vm.warp(block.timestamp + 12 hours);

        // Change to Weekly frequency
        vm.prank(alice);
        vault.setPlan(IOsiris.Frequency.Weekly, 50e6);

        IOsiris.DcaPlan memory weeklyPlan = vault.getUserPlan(alice);
        uint256 weeklyTimestamp = weeklyPlan.nextExecutionTimestamp;
        assertEq(uint8(weeklyPlan.freq), uint8(IOsiris.Frequency.Weekly), "should be Weekly");

        // The timestamp should be recalculated based on Weekly frequency (current time + 7 days)
        uint256 expectedWeeklyTimestamp = block.timestamp + 7 days;
        assertApproxEqAbs(weeklyTimestamp, expectedWeeklyTimestamp, 60, "weekly timestamp should be recalculated");
        // The new timestamp should be different from the old one
        assertTrue(weeklyTimestamp != dailyTimestamp, "timestamp should change when frequency changes");

        // Change back to Monthly
        vm.warp(block.timestamp + 1 days);

        vm.prank(alice);
        vault.setPlan(IOsiris.Frequency.Monthly, 50e6);

        IOsiris.DcaPlan memory monthlyPlan = vault.getUserPlan(alice);
        uint256 monthlyTimestamp = monthlyPlan.nextExecutionTimestamp;
        assertEq(uint8(monthlyPlan.freq), uint8(IOsiris.Frequency.Monthly), "should be Monthly");

        // The timestamp should be recalculated based on Monthly frequency (current time + 30 days)
        uint256 expectedMonthlyTimestamp = block.timestamp + 30 days;
        assertApproxEqAbs(monthlyTimestamp, expectedMonthlyTimestamp, 60, "monthly timestamp should be recalculated");
        // The new timestamp should be different from the weekly one
        assertTrue(monthlyTimestamp != weeklyTimestamp, "timestamp should change again when frequency changes");
    }
}
