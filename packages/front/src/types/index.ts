// Types pour les réponses du contrat
export interface DcaPlanResponse {
  freq: number;
  amountPerPeriod: bigint;
  nextExecutionTimestamp: bigint;
  maxBudgetPerExecution: bigint;
  enableVolatilityFilter: boolean;
}

// Types pour les balances
export interface Balances {
  eth: string;
  usdc: string;
  vaultUsdc: string;
  userUsdc: string;
  userNative: string;
}

// Types pour le plan DCA
export interface DcaPlan {
  frequency: number;
  amountPerPeriod: string;
  nextExecutionTimestamp: number;
  maxBudgetPerExecution: string;
  enableVolatilityFilter: boolean;
  isActive: boolean;
}

// Types pour les résultats de transaction
export interface TransactionResult {
  hash: string;
  status: 'pending' | 'success' | 'error';
  error?: any;
}

// Types pour le contexte wallet
export interface WalletContextType {
  address: string | undefined;
  isConnected: boolean;
  chainId: number | undefined;
  balances: Balances;
  dcaPlan: DcaPlan | null;
  depositUsdc: (amount: string) => Promise<TransactionResult>;
  withdrawUsdc: (amount: string) => Promise<TransactionResult>;
  claimNative: (amount: string) => Promise<TransactionResult>;
  setPlanWithBudget: (
    frequency: number,
    amountPerPeriod: string,
    maxBudgetPerExecution: string,
    enableVolatilityFilter: boolean
  ) => Promise<TransactionResult>;
  pausePlan: () => Promise<TransactionResult>;
  resumePlan: () => Promise<TransactionResult>;
  approveUsdc: (amount: string) => Promise<TransactionResult>;
  getCurrentEthUsdPrice: () => Promise<string>;
  getCurrentVolatility: () => Promise<string>;
  isLoading: boolean;
  error: string | null;
}
