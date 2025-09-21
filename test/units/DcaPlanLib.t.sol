// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {IDcaVault} from "../../src/interfaces/IDcaVault.sol";
import {DcaPlanLib} from "../../src/lib/DcaPlanLib.sol";

contract DcaPlanLibTest is Test {
    using DcaPlanLib for IDcaVault.DcaPlan;

    // --- Storage harness for ensureUserListed ---
    mapping(address => bool) private isUserListed;
    address[] private users;

    // --- Helpers ---
    function _mkPlan(IDcaVault.Frequency f, uint64 nextTs) internal pure returns (IDcaVault.DcaPlan memory p) {
        // Only fields used by the lib must be set (freq, nextExecutionTimestamp)
        p.freq = f;
        p.nextExecutionTimestamp = nextTs;
    }

    // Foundry can’t take storage pointers from memory structs, so keep a dedicated storage slot
    IDcaVault.DcaPlan private planS;

    // --- dcaPeriod ---

    function test_dcaPeriod_Daily() public pure {
        uint64 p = DcaPlanLib.dcaPeriod(IDcaVault.Frequency.Daily);
        assertEq(p, 1 days, "Daily period should be 1 day");
    }

    function test_dcaPeriod_Weekly() public pure {
        uint64 p = DcaPlanLib.dcaPeriod(IDcaVault.Frequency.Weekly);
        assertEq(p, 7 days, "Weekly period should be 7 days");
    }

    function test_dcaPeriod_DefaultMonthly() public pure {
        // Any non-Daily/Weekly should map to 30 days per the lib
        uint64 p = DcaPlanLib.dcaPeriod(IDcaVault.Frequency.Monthly);
        assertEq(p, 30 days, "Default period should be 30 days");
    }

    // --- nextExecutionAfter ---

    function test_nextExecutionAfter_AddsPeriodAndCasts() public pure {
        uint256 fromTs = 1_000;
        uint64 expectTs = uint64(fromTs + 1 days);
        uint64 next = DcaPlanLib.nextExecutionAfter(fromTs, IDcaVault.Frequency.Daily);
        assertEq(next, expectTs);
    }

    // --- catchUpNextExecution ---

    function test_catchUp_whenNextUnset_setsNowPlusPeriod() public {
        uint256 nowTs = 1_700_000_000; // arbitrary
        planS.freq = IDcaVault.Frequency.Daily;
        planS.nextExecutionTimestamp = 0;

        uint64 got = planS.catchUpNextExecution(nowTs);

        assertEq(got, uint64(nowTs) + 1 days, "Should set to now+period");
        assertEq(planS.nextExecutionTimestamp, got, "Stored nextExecutionTimestamp must be updated");
    }

    function test_catchUp_whenNextInFuture_keepsUnchanged() public {
        uint256 nowTs = 1_700_000_000;
        uint64 p = DcaPlanLib.dcaPeriod(IDcaVault.Frequency.Daily);

        planS.freq = IDcaVault.Frequency.Daily;
        planS.nextExecutionTimestamp = uint64(nowTs) + (3 * p); // already in the future

        uint64 got = planS.catchUpNextExecution(nowTs);

        assertEq(got, uint64(nowTs) + 3 * p, "Should not modify a future schedule");
        assertEq(planS.nextExecutionTimestamp, got);
    }

    function test_catchUp_whenNextInPast_rollsForwardJustBeyondNow() public {
        uint256 nowTs = 1_700_000_000;
        uint64 p = DcaPlanLib.dcaPeriod(IDcaVault.Frequency.Weekly);

        planS.freq = IDcaVault.Frequency.Weekly;

        // Set a "next" two periods in the past, plus some extra so it's not aligned
        uint64 nextPast = uint64(nowTs) - (2 * p) - 1234;
        planS.nextExecutionTimestamp = nextPast;

        uint64 got = planS.catchUpNextExecution(nowTs);

        // The result must be strictly > now and within one period after 'now'
        assertGt(got, uint64(nowTs), "New next must be after now");
        assertLe(got - uint64(nowTs), p, "New next must be within one period after now");

        // And it should be congruent to "nextPast modulo p"
        uint64 diff = got - nextPast;
        assertEq(diff % p, 0, "New next should land on a period boundary from original next");
    }

    function test_catchUp_exactBoundary_stillAdvancesOnePeriod() public {
        uint256 nowTs = 2_000_000_000;
        uint64 p = DcaPlanLib.dcaPeriod(IDcaVault.Frequency.Daily);

        planS.freq = IDcaVault.Frequency.Daily;
        // If next == now - k*p (i.e., exactly on boundary in the past), the lib adds +1 period
        uint64 nextPast = uint64(nowTs) - (3 * p);
        planS.nextExecutionTimestamp = nextPast;

        uint64 got = planS.catchUpNextExecution(nowTs);
        assertEq(got, nextPast + 4 * p, "Should add (delta/p)+1 periods");
        assertGt(got, uint64(nowTs), "Must strictly surpass now");
        assertLe(got - uint64(nowTs), p, "Should be within one period after now");
    }

    function test_catchUp_largeMiss_manyPeriods() public {
        uint256 nowTs = 2_100_000_000;
        uint64 p = DcaPlanLib.dcaPeriod(IDcaVault.Frequency.Daily);

        planS.freq = IDcaVault.Frequency.Daily;
        // Miss ~365 days
        uint64 nextPast = uint64(nowTs) - (365 * p);
        planS.nextExecutionTimestamp = nextPast;

        uint64 got = planS.catchUpNextExecution(nowTs);

        assertGt(got, uint64(nowTs), "Must end up after now");
        assertLe(got - uint64(nowTs), p, "No more than one period after now");
        // Also check alignment
        assertEq((got - nextPast) % p, 0, "Alignment on periods must be preserved");
    }

    // --- ensureUserListed ---

    function test_ensureUserListed_addsOnce() public {
        address u = address(0xBEEF);

        // First call should add and set mapping
        DcaPlanLib.ensureUserListed(isUserListed, users, u);
        assertTrue(isUserListed[u], "User should be marked listed");
        assertEq(users.length, 1, "User array should grow");
        assertEq(users[0], u, "Correct user added");

        // Second call should be a no-op
        DcaPlanLib.ensureUserListed(isUserListed, users, u);
        assertTrue(isUserListed[u], "Still listed");
        assertEq(users.length, 1, "No duplicate insert");
    }

    function test_ensureUserListed_multipleUsers_orderedAppend() public {
        address a = address(0xA);
        address b = address(0xB);
        address c = address(0xC);

        DcaPlanLib.ensureUserListed(isUserListed, users, a);
        DcaPlanLib.ensureUserListed(isUserListed, users, b);
        DcaPlanLib.ensureUserListed(isUserListed, users, c);

        assertEq(users.length, 3);
        assertEq(users[0], a);
        assertEq(users[1], b);
        assertEq(users[2], c);
    }
}
