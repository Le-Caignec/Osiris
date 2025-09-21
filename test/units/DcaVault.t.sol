// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DcaVault} from "../../src/DcaVault.sol";
import {IDcaVault} from "../../src/interfaces/IDcaVault.sol";
import {ConfigLib} from "../../script/lib/configLib.sol";

contract DcaVault_Units is Test {
    // config-driven addresses
    address private universalRouter;
    address private permit2;
    address private usdcAddress;
    address private callbackSender;

    IERC20 private usdc;
    DcaVault private vault;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    // Events mirrored from DcaVault
    event DepositedUSDC(address indexed user, uint256 amount);
    event WithdrawnUSDC(address indexed user, uint256 amount);
    event ClaimedNative(address indexed user, uint256 amount);
    event PlanUpdated(
        address indexed user,
        IDcaVault.Frequency freq,
        uint256 amountPerPeriod,
        bool active,
        uint64 nextExecutionTimestamp
    );
    event CallbackProcessed(uint256 eligibleCount, uint256 totalUsdcIn, uint256 nativeOut);

    function setUp() public {
        // Read from config.json like in UniV4Swap tests
        string memory chain = vm.envOr("CHAIN", string("ethereum"));
        ConfigLib.DestinationNetworkConfig memory cfg = ConfigLib.readDestinationNetworkConfig(chain);
        require(cfg.chainId != 0, "config: unknown chain");
        require(bytes(cfg.rpcUrl).length != 0, "config: missing rpc");
        vm.createSelectFork(cfg.rpcUrl);

        universalRouter = cfg.uniswapUniversalRouter;
        permit2 = cfg.uniswapPermit2;
        usdcAddress = cfg.usdc;
        callbackSender = cfg.callbackProxyContract != address(0) ? cfg.callbackProxyContract : address(this);

        usdc = IERC20(usdcAddress);
        vault = new DcaVault(universalRouter, permit2, usdcAddress, callbackSender);

        // labels for nicer traces
        vm.label(address(vault), "DcaVault");
        vm.label(usdcAddress, "USDC");
        vm.label(callbackSender, "CallbackSender");
        vm.label(universalRouter, "UniV4UniversalRouter");
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
        vm.expectRevert(abi.encodeWithSelector(IDcaVault.AmountZero.selector));
        vault.withdrawUsdc(0);
    }

    function test_withdrawUsdc_revertsOnInsufficient() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IDcaVault.InsufficientUSDC.selector));
        vault.withdrawUsdc(1);
    }

    function test_depositUsdc_revertsOnZero() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IDcaVault.AmountZero.selector));
        vault.depositUsdc(0);
    }

    // -----------------------------
    // Plan lifecycle (assert via events)
    // -----------------------------
    function test_setPlan_emitsAndActivates() public {
        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit PlanUpdated(alice, IDcaVault.Frequency.Daily, 10e6, true, 0);
        vault.setPlan(IDcaVault.Frequency.Daily, 10e6, true);
    }

    function test_setPlan_reverts_onZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IDcaVault.AmountZero.selector));
        vault.setPlan(IDcaVault.Frequency.Daily, 0, true);
    }

    function test_pause_and_resume_emitUpdates() public {
        vm.prank(alice);
        vault.setPlan(IDcaVault.Frequency.Weekly, 5e6, true);

        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit PlanUpdated(alice, IDcaVault.Frequency.Weekly, 5e6, false, 0);
        vault.pausePlan();

        vm.warp(block.timestamp + 15 days);
        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit PlanUpdated(alice, IDcaVault.Frequency.Weekly, 5e6, true, 0);
        vault.resumePlan();
    }

    // -----------------------------
    // Claim native (expect revert without accrued native)
    // -----------------------------
    function test_claimNative_revertsOnZero() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IDcaVault.AmountZero.selector));
        vault.claimNative(0);
    }

    function test_claimNative_revertsOnInsufficient() public {
        vm.prank(alice);
        vm.expectRevert(); // generic require in implementation (insufficient native)
        vault.claimNative(1);
    }

    // -----------------------------
    // Callback authorization
    // -----------------------------
    function test_callback_reverts_if_notAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(IDcaVault.NotCallbackSender.selector));
        vault.callback(address(0xBEEF));
    }

    function test_callback_byAuthorized_doesNotRevert_whenNoEligibleUsers() public {
        // No plans/deposits => should be a no-op but callable by authorized sender
        vm.prank(callbackSender);
        vault.callback(makeAddr("SENT"));
    }
}
