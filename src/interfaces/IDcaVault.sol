// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IDcaVault {
    // Frequencies
    enum Frequency {
        Daily,
        Weekly,
        Monthly
    }

    // Shared plan type
    struct DcaPlan {
        Frequency freq;
        uint128 amountPerPeriod;
        uint64 nextExecutionTimestamp;
        bool active;
    }

    // Events
    event DepositedUSDC(address indexed user, uint256 amount);
    event WithdrawnUSDC(address indexed user, uint256 amount);
    event ClaimedNative(address indexed user, uint256 amount);
    event PlanUpdated(address indexed user, Frequency freq, uint256 amountPerPeriod, bool active, uint64 nextExec);
    event CallbackProcessed(uint256 usersProcessed, uint256 totalInUsdc, uint256 totalOutNative);

    // Errors
    error NotOwner();
    error NotCallbackSender();
    error AmountZero();
    error InsufficientUSDC();
    error InvalidSwapRoute();
    error AmountTooLarge();

    // User actions
    function depositUsdc(uint256 amount) external;
    function withdrawUsdc(uint256 amount) external;
    function claimNative(uint256 amount) external;

    // Plan management
    function setPlan(Frequency freq, uint256 amountPerPeriod, bool active) external;
    function pausePlan() external;
    function resumePlan() external;

    // CronReactive tick
    function callback(address sender) external;
}
