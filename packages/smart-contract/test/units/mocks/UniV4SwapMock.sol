// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title UniV4SwapMock
/// @notice Minimal swap router stub for unit tests. Outputs a configurable amount of either
///         native ETH (mockTokenOut == address(0)) or an ERC-20 token.
contract UniV4SwapMock {
    uint256 public mockOut; // slot 0: returned as uint256 by the fallback assembly
    address public mockTokenOut; // slot 1: address(0) = ETH mode, non-zero = ERC-20 mode

    function setMockOut(uint256 v) external {
        mockOut = v;
    }

    function setMockTokenOut(address token) external {
        mockTokenOut = token;
    }

    receive() external payable {}

    /// @dev Mimics a swap by transferring mockOut of either ETH or an ERC-20 to the caller,
    ///      then returns mockOut as a uint256.
    fallback() external payable {
        uint256 out = mockOut;
        if (out > 0) {
            address tokenOut = mockTokenOut;
            if (tokenOut == address(0)) {
                // ETH mode
                if (address(this).balance >= out) {
                    (bool ok,) = msg.sender.call{value: out}("");
                    require(ok, "UniV4SwapMock: ETH transfer failed");
                }
            } else {
                // ERC-20 mode
                IERC20(tokenOut).transfer(msg.sender, out);
            }
        }
        // Return mockOut as abi-encoded uint256
        assembly {
            mstore(0x00, sload(0))
            return(0x00, 0x20)
        }
    }
}
