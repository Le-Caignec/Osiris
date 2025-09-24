// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {IOsiris} from "../interfaces/IOsiris.sol";

library DcaPlanLib {
    function dcaPeriod(IOsiris.Frequency f) internal pure returns (uint64) {
        if (f == IOsiris.Frequency.Daily) return 1 days;
        if (f == IOsiris.Frequency.Weekly) return 7 days;
        return 30 days;
    }

    function nextExecutionAfter(uint256 fromTs, IOsiris.Frequency f) internal pure returns (uint64) {
        return uint64(fromTs + dcaPeriod(f));
    }

    // Updates the plan's nextExecutionTimestamp in-place and returns the new value
    function catchUpNextExecution(IOsiris.DcaPlan storage plan, uint256 nowTs) internal returns (uint256) {
        uint64 p = dcaPeriod(plan.freq);
        uint256 current = plan.nextExecutionTimestamp;
        uint256 newNext;

        if (current > nowTs) {
            // Already in the future => keep
            newNext = current;
        } else {
            // In the past => roll forward just beyond now, preserving alignment
            uint256 delta = nowTs - current;
            uint256 missed = (delta / p) + 1;
            newNext = current + uint64(missed) * p;
        }

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
