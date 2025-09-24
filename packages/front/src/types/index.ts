// Types pour les réponses du contrat
export interface DcaPlanResponse {
  freq: number;
  amountPerPeriod: bigint;
  nextExecutionTimestamp: bigint;
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
  isActive: boolean;
}

// Types pour le contexte wallet
export interface WalletContextType {
  address: string | undefined;
  isConnected: boolean;
  chainId: number | undefined;
  balances: Balances;
  dcaPlan: DcaPlan | null;
  depositUsdc: (amount: string) => Promise<void>;
  withdrawUsdc: (amount: string) => Promise<void>;
  claimNative: (amount: string) => Promise<void>;
  setPlan: (frequency: number, amountPerPeriod: string) => Promise<void>;
  pausePlan: () => Promise<void>;
  resumePlan: () => Promise<void>;
  approveUsdc: (amount: string) => Promise<void>;
  isLoading: boolean;
  error: string | null;
}
