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
        uint256 nextExecutionTimestamp; // 0 means inactive
    }

    // Events
    event DepositedUSDC(address indexed user, uint256 amount);
    event WithdrawnUSDC(address indexed user, uint256 amount);
    event ClaimedNative(address indexed user, uint256 amount);
    event PlanUpdated(address indexed user, Frequency freq, uint256 amountPerPeriod, uint256 nextExecutionTimestamp);
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
    function setPlan(Frequency freq, uint256 amountPerPeriod) external;
    function pausePlan() external;
    function resumePlan() external;

    // CronReactive tick
    function callback() external;
}
