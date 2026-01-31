// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {ISystemContract} from "@reactive-contract/interfaces/ISystemContract.sol";
import {AbstractPausableReactive} from "@reactive-contract/abstract-base/AbstractPausableReactive.sol";

contract CronReactive is AbstractPausableReactive {
    uint256 public cronTopic;
    uint64 private constant GAS_LIMIT = 1000000;
    
    // Mapping from chain ID to callback address
    mapping(uint256 => address) public destinationCallbacks;
    // Array to track all registered chain IDs
    uint256[] public destinationChainIds;

    event DestinationChainAdded(uint256 indexed chainId, address indexed callback);
    event DestinationChainRemoved(uint256 indexed chainId);

    error InvalidCallbackAddress();

    constructor(
        address _service,
        uint256 _cronTopic,
        uint256[] memory _destinationChainIds,
        address[] memory _callbacks
    ) payable {
        service = ISystemContract(payable(_service));
        cronTopic = _cronTopic;

        require(
            _destinationChainIds.length == _callbacks.length,
            "CronReactive: arrays length mismatch"
        );
        require(_destinationChainIds.length > 0, "CronReactive: at least one destination required");

        if (!vm) {
            service.subscribe(
                block.chainid, address(service), _cronTopic, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE
            );
        }

        // Add all initial destination chains
        for (uint256 i = 0; i < _destinationChainIds.length; i++) {
            require(_callbacks[i] != address(0), "CronReactive: callback cannot be zero address");
            _addDestinationChain(_destinationChainIds[i], _callbacks[i]);
        }
    }

    function getPausableSubscriptions() internal view override returns (Subscription[] memory) {
        Subscription[] memory result = new Subscription[](1);
        result[0] =
            Subscription(block.chainid, address(service), cronTopic, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE);
        return result;
    }

    function react(LogRecord calldata log) external vmOnly {
        if (log.topic_0 == cronTopic) {
            bytes memory payload = abi.encodeWithSignature("callback(address)", address(0));
            
            // Emit callback for each registered destination chain
            for (uint256 i = 0; i < destinationChainIds.length; i++) {
                uint256 chainId = destinationChainIds[i];
                address callback = destinationCallbacks[chainId];
                if (callback != address(0)) {
                    emit Callback(chainId, callback, GAS_LIMIT, payload);
        }
            }
        }
    }

    /**
     * @notice Get all registered destination chain IDs
     * @return Array of chain IDs
     */
    function getDestinationChainIds() external view returns (uint256[] memory) {
        return destinationChainIds;
    }


    /**
     * @notice Internal function to add a destination chain
     * @param _chainId The chain ID of the destination
     * @param _callback The callback contract address on that chain
     */
    function _addDestinationChain(uint256 _chainId, address _callback) internal {
        if (_callback == address(0)) {
            revert InvalidCallbackAddress();
        }
        destinationCallbacks[_chainId] = _callback;
        destinationChainIds.push(_chainId);
        
        emit DestinationChainAdded(_chainId, _callback);
    }
}
