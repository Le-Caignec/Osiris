// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Osiris} from "../../../src/Osiris.sol";

/// @title OsirisMock
/// @notice Extends Osiris with test-only backdoors for authorization bypass.
contract OsirisMock is Osiris {
    constructor(
        address _router,
        address _permit2,
        address _usdc,
        address _callbackSender,
        address _ethUsdFeed,
        address _wReact,
        address _diaOracle
    ) payable Osiris(_router, _permit2, _usdc, _callbackSender, _ethUsdFeed, _wReact, _diaOracle) {}

    /// @notice Testing function to add authorized sender for test purposes
    function addAuthorizedSenderForTesting(address sender) external {
        addAuthorizedSender(sender);
    }

    /// @notice Testing function to set RVM ID for test purposes
    function setRvmIdForTesting(address rvmId) external {
        rvm_id = rvmId;
    }
}
