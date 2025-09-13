// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {AbstractCallback} from "@reactive-contract/abstract-base/AbstractCallback.sol";

contract Callback is AbstractCallback {
    event CallbackReceived(address indexed origin, address indexed sender, address indexed reactiveSender);

    constructor(address _callbackSender) payable AbstractCallback(_callbackSender) {}

    function callback(address sender) external authorizedSenderOnly rvmIdOnly(sender) {
        emit CallbackReceived(tx.origin, msg.sender, sender);
    }
}
