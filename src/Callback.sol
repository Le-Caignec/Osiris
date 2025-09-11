// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import '@reactive-contract/abstract-base/AbstractCallback.sol';

contract Callback is AbstractCallback {
    event CallbackReceived(
        address indexed origin,
        address indexed sender,
        address indexed reactive_sender
    );

    constructor(address _callback_sender) AbstractCallback(_callback_sender) payable {}

    function callback(address sender)
        external
        authorizedSenderOnly
        rvmIdOnly(sender)
    {
        emit CallbackReceived(
            tx.origin,
            msg.sender,
            sender
        );
    }
}
