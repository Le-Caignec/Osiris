// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {IDcaVault} from "../interfaces/IDcaVault.sol";

library DcaPlanLib {
    function dcaPeriod(IDcaVault.Frequency f) internal pure returns (uint64) {
        if (f == IDcaVault.Frequency.Daily) return 1 days;
        if (f == IDcaVault.Frequency.Weekly) return 7 days;
        return 30 days;
    }

    function nextExecutionAfter(uint256 fromTs, IDcaVault.Frequency f) internal pure returns (uint64) {
        // casting to 'uint64' is safe because block timestamps and periods fit within 2^64
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint64(fromTs + dcaPeriod(f));
    }

    // Updates the plan's nextExecutionTimestamp in-place and returns the new value
    function catchUpNextExecution(IDcaVault.DcaPlan storage plan, uint256 nowTs) internal returns (uint64) {
        uint64 p = dcaPeriod(plan.freq);
        // casting to 'uint64' is safe because block timestamps fit within 2^64
        // forge-lint: disable-next-line(unsafe-typecast)
        uint64 next = plan.nextExecutionTimestamp == 0 ? uint64(nowTs) + p : plan.nextExecutionTimestamp;
        if (next > nowTs) {
            plan.nextExecutionTimestamp = next;
            return next;
        }
        uint256 delta = nowTs - next;
        uint256 missed = (delta / p) + 1;
        // casting to 'uint64' is safe because 'missed' fits within 2^64 for practical horizons
        // forge-lint: disable-next-line(unsafe-typecast)
        uint64 newNext = next + uint64(missed) * p;
        plan.nextExecutionTimestamp = newNext;
        return newNext;
    }

    function ensureUserListed(mapping(address => bool) storage isUserListed, address[] storage users, address u)
        internal
    {
        if (!isUserListed[u]) {
            isUserListed[u] = true;
            users.push(u);
        }
    }
}
