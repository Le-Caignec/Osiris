// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {ISystemContract} from "@reactive-contract/interfaces/ISystemContract.sol";
import {AbstractPausableReactive} from "@reactive-contract/abstract-base/AbstractPausableReactive.sol";

contract CronReactive is AbstractPausableReactive {
    uint256 public conTopic;
    uint64 private constant GAS_LIMIT = 1000000;
    uint256 public destinationChainId;
    address private callback;
    uint256 public lastCronBlock;

    constructor(address _service, uint256 _cronTopic, uint256 _destinationChainId, address _callback) payable {
        service = ISystemContract(payable(_service));
        conTopic = _cronTopic;
        destinationChainId = _destinationChainId;
        callback = _callback;

        service.subscribe(
            block.chainid, address(service), _cronTopic, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE
        );
    }

    function getPausableSubscriptions() internal view override returns (Subscription[] memory) {
        Subscription[] memory result = new Subscription[](1);
        result[0] =
            Subscription(block.chainid, address(service), conTopic, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE);
        return result;
    }

    function react(LogRecord calldata log) external vmOnly {
        if (log.topic_0 == conTopic) {
            lastCronBlock = block.number;
            bytes memory payload = abi.encodeWithSignature("callback(address)", address(0));
            emit Callback(destinationChainId, callback, GAS_LIMIT, payload);
        }
    }

    // For testing`rnk_call`
    function getLastCronBlock() external view returns (uint256) {
        return lastCronBlock;
    }
}
