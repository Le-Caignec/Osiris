// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IOsiris {
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
        uint256 maxBudgetPerExecution; // Maximum USD price per ETH that user is willing to pay (0 = no limit)
        bool enableVolatilityFilter; // Whether to enable volatility filtering
    }

    // Events
    event DepositedUSDC(address indexed user, uint256 amount);
    event WithdrawnUSDC(address indexed user, uint256 amount);
    event ClaimedNative(address indexed user, uint256 amount);
    event PlanUpdated(address indexed user, Frequency freq, uint256 amountPerPeriod, uint256 nextExecutionTimestamp);
    event CallbackProcessed(uint256 usersProcessed, uint256 totalInUsdc, uint256 totalOutNative);
    event DcaExecutionSkipped(address indexed user, string reason, uint256 timestamp);
    event DcaExecutionLog(
        address indexed user,
        uint256 amount,
        bool budgetCheck,
        bool volatilityCheck,
        uint256 currentVolatility,
        uint256 timestamp
    );

    // Errors
    error AmountZero();
    error InsufficientUSDC();
    error InvalidSwapRoute();
    error AmountTooLarge();
    error BudgetExceeded();
    error HighVolatility();

    // User actions
    function depositUsdc(uint256 amount) external;
    function withdrawUsdc(uint256 amount) external;
    function claimNative(uint256 amount) external;

    // Plan management
    function setPlanWithBudget(
        Frequency freq,
        uint256 amountPerPeriod,
        uint256 maxBudgetPerExecution,
        bool enableVolatilityFilter
    ) external;
    function pausePlan() external;
    function resumePlan() external;

    // CronReactive tick
    function callback(address sender) external;

    // View getters ajoutés
    function getTotalUsdc() external view returns (uint256);
    function getUserUsdc(address user) external view returns (uint256);
    function getUserNative(address user) external view returns (uint256);
    function getUserPlan(address user) external view returns (DcaPlan memory);
}
