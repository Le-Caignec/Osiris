// Contract addresses for different networks
export const CONTRACT_ADDRESSES = {
  // Ethereum Mainnet
  ethereum: {
    osiris: '',
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
  {
    type: 'event',
    name: 'DepositedUSDC',
    inputs: [
      { name: 'user', type: 'address', indexed: true },
      { name: 'amount', type: 'uint256', indexed: false },
    ],
    anonymous: false,
  },
  {
    type: 'event',
    name: 'WithdrawnUSDC',
    inputs: [
      { name: 'user', type: 'address', indexed: true },
      { name: 'amount', type: 'uint256', indexed: false },
    ],
    anonymous: false,
  },
  {
    type: 'event',
    name: 'ClaimedNative',
    inputs: [
      { name: 'user', type: 'address', indexed: true },
      { name: 'amount', type: 'uint256', indexed: false },
    ],
    anonymous: false,
  },
  {
    type: 'event',
    name: 'PlanUpdated',
    inputs: [
      { name: 'user', type: 'address', indexed: true },
      { name: 'freq', type: 'uint8', indexed: false },
      { name: 'amountPerPeriod', type: 'uint256', indexed: false },
      { name: 'nextExecutionTimestamp', type: 'uint256', indexed: false },
    ],
    anonymous: false,
  },
  {
    type: 'event',
    name: 'CallbackProcessed',
    inputs: [
      { name: 'usersProcessed', type: 'uint256', indexed: false },
      { name: 'totalInUsdc', type: 'uint256', indexed: false },
      { name: 'totalOutNative', type: 'uint256', indexed: false },
    ],
    anonymous: false,
  },

  // Errors
  {
    type: 'error',
    name: 'AmountZero',
    inputs: [],
  },
  {
    type: 'error',
    name: 'InsufficientUSDC',
    inputs: [],
  },
  {
    type: 'error',
    name: 'InvalidSwapRoute',
    inputs: [],
  },
  {
    type: 'error',
    name: 'AmountTooLarge',
    inputs: [],
  },

  // User actions
  {
    type: 'function',
    name: 'depositUsdc',
    inputs: [{ name: 'amount', type: 'uint256' }],
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'withdrawUsdc',
    inputs: [{ name: 'amount', type: 'uint256' }],
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'claimNative',
    inputs: [{ name: 'amount', type: 'uint256' }],
    outputs: [],
    stateMutability: 'nonpayable',
  },

  // Plan management
  {
    type: 'function',
    name: 'setPlan',
    inputs: [
      { name: 'freq', type: 'uint8' },
      { name: 'amountPerPeriod', type: 'uint256' },
    ],
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'pausePlan',
    inputs: [],
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'resumePlan',
    inputs: [],
    outputs: [],
    stateMutability: 'nonpayable',
  },

  // CronReactive tick
  {
    type: 'function',
    name: 'callback',
    inputs: [],
    outputs: [],
    stateMutability: 'nonpayable',
  },

  // View getters
  {
    type: 'function',
    name: 'getTotalUsdc',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'getUserUsdc',
    inputs: [{ name: 'user', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'getUserNative',
    inputs: [{ name: 'user', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'getUserPlan',
    inputs: [{ name: 'user', type: 'address' }],
    outputs: [
      {
        name: '',
        type: 'tuple',
        components: [
          { name: 'freq', type: 'uint8' },
          { name: 'amountPerPeriod', type: 'uint128' },
          { name: 'nextExecutionTimestamp', type: 'uint256' },
        ],
      },
    ],
    stateMutability: 'view',
  },
] as const;

// USDC ABI (ERC20)
export const USDC_ABI = [
  {
    type: 'function',
    name: 'balanceOf',
    inputs: [{ name: 'owner', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'transfer',
    inputs: [
      { name: 'to', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'transferFrom',
    inputs: [
      { name: 'from', type: 'address' },
      { name: 'to', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'approve',
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'allowance',
    inputs: [
      { name: 'owner', type: 'address' },
      { name: 'spender', type: 'address' },
    ],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'decimals',
    inputs: [],
    outputs: [{ name: '', type: 'uint8' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'symbol',
    inputs: [],
    outputs: [{ name: '', type: 'string' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'name',
    inputs: [],
    outputs: [{ name: '', type: 'string' }],
    stateMutability: 'view',
  },
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
