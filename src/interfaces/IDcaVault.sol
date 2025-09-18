// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

interface IDcaVault {
    // Frequencies
    enum Frequency {
        Daily,
        Weekly,
        Monthly
    }

    // Events
    event DepositedUSDC(address indexed user, uint256 amount);
    event WithdrawnUSDC(address indexed user, uint256 amount);
    event ClaimedNative(address indexed user, uint256 amount);
    event PlanUpdated(address indexed user, Frequency freq, uint256 amountPerPeriod, bool active, uint64 nextExec);
    event CallbackProcessed(uint256 usersProcessed, uint256 totalInUSDC, uint256 totalOutNative);

    // Errors
    error NotOwner();
    error NotCallbackSender();
    error AmountZero();
    error InsufficientUSDC();
    error InvalidSwapRoute();

    // User actions
    function depositUSDC(uint256 amount) external;
    function withdrawUSDC(uint256 amount) external;
    function claimNative(uint256 amount) external;

    // Plan management
    function setPlan(Frequency freq, uint256 amountPerPeriod, bool active) external;
    function pausePlan() external;
    function resumePlan() external;

    // Admin
    function setBatchSize(uint256 _batchSize) external;

    // CronReactive tick
    function callback(address sender) external;
}
