// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Osiris} from "../../../src/Osiris.sol";

/// @title OsirisMock
/// @notice Mock contract for testing purposes that extends Osiris with test-only functions
contract OsirisMock is Osiris {
    constructor(address _router, address _permit2, address _usdc, address _callbackSender)
        payable
        Osiris(_router, _permit2, _usdc, _callbackSender)
    {}

    /// @notice Testing function to add authorized sender for test purposes
    function addAuthorizedSenderForTesting(address sender) external {
        addAuthorizedSender(sender);
    }

    /// @notice Testing function to set RVM ID for test purposes
    function setRvmIdForTesting(address rvmId) external {
        // This allows the test to set the RVM ID that will be checked by rvmIdOnly modifier
        rvm_id = rvmId;
    }
}
