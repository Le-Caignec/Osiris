// Contract addresses for different networks
export const CONTRACT_ADDRESSES = {
  // Ethereum Mainnet
  ethereum: {
    osiris: '0x9C4031fC80040b6ad84766405D611B5105D18e48',
    usdc: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
  },
  // Sepolia Testnet
  sepolia: {
    osiris: '0x9C4031fC80040b6ad84766405D611B5105D18e48',
    usdc: '0x1c7d4b196cb0c7b01d743fbc6116a902379c7238',
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
