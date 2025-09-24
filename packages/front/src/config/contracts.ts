// Contract addresses for different networks
export const CONTRACT_ADDRESSES = {
  // Ethereum Mainnet
  ethereum: {
    osiris: '0x0000000000000000000000000000000000000000', // TODO: Replace with actual deployed address
    usdc: '0xA0b86a33E6441b8C4C8C0d4B0a1a2a3a4a5a6a7a8', // TODO: Replace with actual USDC address
  },
  // Sepolia Testnet
  sepolia: {
    osiris: '0x0000000000000000000000000000000000000000', // TODO: Replace with actual deployed address
    usdc: '0x94a9D9AC8a22534E3FaCa9F4e7F2E2deF89A357Fb', // Sepolia USDC address
  },
};

// Contract ABI - Osiris contract interface
export const OSIRIS_ABI = [
  // Events
  'event DepositedUSDC(address indexed user, uint256 amount)',
  'event WithdrawnUSDC(address indexed user, uint256 amount)',
  'event ClaimedNative(address indexed user, uint256 amount)',
  'event PlanUpdated(address indexed user, uint8 freq, uint256 amountPerPeriod, uint256 nextExecutionTimestamp)',
  'event CallbackProcessed(uint256 usersProcessed, uint256 totalInUsdc, uint256 totalOutNative)',

  // Errors
  'error AmountZero()',
  'error InsufficientUSDC()',
  'error InvalidSwapRoute()',
  'error AmountTooLarge()',

  // User actions
  'function depositUsdc(uint256 amount) external',
  'function withdrawUsdc(uint256 amount) external',
  'function claimNative(uint256 amount) external',

  // Plan management
  'function setPlan(uint8 freq, uint256 amountPerPeriod) external',
  'function pausePlan() external',
  'function resumePlan() external',

  // CronReactive tick
  'function callback() external',

  // View getters
  'function getTotalUsdc() external view returns (uint256)',
  'function getUserUsdc(address user) external view returns (uint256)',
  'function getUserNative(address user) external view returns (uint256)',
  'function getUserPlan(address user) external view returns (tuple(uint8 freq, uint128 amountPerPeriod, uint256 nextExecutionTimestamp))',
] as const;

// USDC ABI (ERC20)
export const USDC_ABI = [
  'function balanceOf(address owner) view returns (uint256)',
  'function transfer(address to, uint256 amount) returns (bool)',
  'function transferFrom(address from, address to, uint256 amount) returns (bool)',
  'function approve(address spender, uint256 amount) returns (bool)',
  'function allowance(address owner, address spender) view returns (uint256)',
  'function decimals() view returns (uint8)',
  'function symbol() view returns (string)',
  'function name() view returns (string)',
] as const;

// DCA Plan frequency enum
export enum Frequency {
  Daily = 0,
  Weekly = 1,
  Monthly = 2,
}

// Frequency labels
export const FREQUENCY_LABELS = {
  [Frequency.Daily]: 'Daily',
  [Frequency.Weekly]: 'Weekly',
  [Frequency.Monthly]: 'Monthly',
};
