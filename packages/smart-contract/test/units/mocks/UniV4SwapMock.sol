// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract UniV4SwapMock {
    uint256 public mockOut;

    function setMockOut(uint256 v) external {
        mockOut = v;
    }

    // Accept ETH for tests that simulate payouts
    receive() external payable {}

    // Mimics swap by transferring mockOut ETH to caller and returning the value
    fallback() external payable {
        uint256 out = mockOut;
        // Transfer ETH to the caller (UniV4Swap contract) to simulate swap output
        if (out > 0 && address(this).balance >= out) {
            (bool ok,) = msg.sender.call{value: out}("");
            require(ok, "UniV4SwapMock: ETH transfer failed");
        }
        // Return the mockOut value
        assembly {
            mstore(0x00, sload(0))
            return(0x00, 0x20)
        }
    }
}
