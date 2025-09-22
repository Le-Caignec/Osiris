// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract UniV4SwapMock {
    uint256 public mockOut;

    function setMockOut(uint256 v) external {
        mockOut = v;
    }

    // Accept ETH for tests that simulate payouts
    receive() external payable {}

    // Return abi.encode(mockOut) for any call (mimics swap return)
    fallback() external payable {
        assembly {
            // load mockOut from storage slot 0
            mstore(0x00, sload(0))
            return(0x00, 0x20)
        }
    }
}
