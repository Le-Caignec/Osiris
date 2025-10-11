import React, { createContext, useContext } from 'react';
import {
  useAccount,
  useBalance,
  useContractRead,
  useContractWrite,
  useChainId,
  usePublicClient,
} from 'wagmi';
import {
  parseEther,
  parseUnits,
  formatEther,
  formatUnits,
} from 'viem';
import { waitForTransactionReceipt } from 'viem/actions';
import {
  CONTRACT_ADDRESSES,
  OSIRIS_ABI,
  USDC_ABI,
  Frequency,
} from '../config/contracts';
import { WalletContextType, DcaPlan, TransactionResult } from '../types';

// Using imported WalletContextType from types file

const WalletContext = createContext<WalletContextType | undefined>(undefined);

export const useWallet = () => {
  const context = useContext(WalletContext);
  if (!context) {
    throw new Error('useWallet must be used within a WalletProvider');
  }
  return context;
};

interface WalletProviderProps {
  children: React.ReactNode;
}

const WalletProvider: React.FC<WalletProviderProps> = ({ children }) => {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const publicClient = usePublicClient();

  // Get contract addresses based on current chain
  const getContractAddresses = () => {
    if (chainId === 1) return CONTRACT_ADDRESSES.ethereum;
    if (chainId === 11155111) return CONTRACT_ADDRESSES.sepolia;
    return CONTRACT_ADDRESSES.sepolia; // Default to Sepolia
  };

  const contractAddresses = getContractAddresses();

  // #########################################
  // Read balances
  // #########################################
  const {
    data: ethBalance,
    isLoading: isEthLoading,
    isFetching: isEthFetching,
  } = useBalance({
    address,
    enabled: isConnected && !!address,
    watch: true,
  });

  const {
    data: usdcBalance,
    isLoading: isUsdcLoading,
    isFetching: isUsdcFetching,
  } = useBalance({
    address,
    token: contractAddresses.usdc as `0x${string}`,
    enabled: isConnected && !!address,
    watch: true,
  });

  const balancesLoading = !!(
    isEthLoading ||
    isEthFetching ||
    isUsdcLoading ||
    isUsdcFetching
  );
  const balancesReady = !balancesLoading && !!ethBalance && !!usdcBalance;

  const { data: vaultUsdcBalance } = useContractRead({
    address: contractAddresses.osiris as `0x${string}`,
    abi: OSIRIS_ABI,
    functionName: 'getTotalUsdc',
    enabled: isConnected,
    watch: true,
  });

  const { data: userUsdcBalance } = useContractRead({
    address: contractAddresses.osiris as `0x${string}`,
    abi: OSIRIS_ABI,
    functionName: 'getUserUsdc',
    args: address ? [address] : undefined,
    enabled: isConnected && !!address,
    watch: true,
  });

  const { data: userNativeBalance } = useContractRead({
    address: contractAddresses.osiris as `0x${string}`,
    abi: OSIRIS_ABI,
    functionName: 'getUserNative',
    args: address ? [address] : undefined,
    enabled: isConnected && !!address,
    watch: true,
  });

  const { data: userPlan } = useContractRead({
    address: contractAddresses.osiris as `0x${string}`,
    abi: OSIRIS_ABI,
    functionName: 'getUserPlan',
    args: address ? [address] : undefined,
    enabled: isConnected && !!address,
    watch: true,
  });

  // #########################################
  // Contract write functions
  // #########################################
  const { writeAsync: depositUsdcWrite } = useContractWrite({
    address: contractAddresses.osiris as `0x${string}`,
    abi: OSIRIS_ABI,
    functionName: 'depositUsdc',
  });

  const { writeAsync: withdrawUsdcWrite } = useContractWrite({
    address: contractAddresses.osiris as `0x${string}`,
    abi: OSIRIS_ABI,
    functionName: 'withdrawUsdc',
  });

  const { writeAsync: claimNativeWrite } = useContractWrite({
    address: contractAddresses.osiris as `0x${string}`,
    abi: OSIRIS_ABI,
    functionName: 'claimNative',
  });

  const { writeAsync: setPlanWithBudgetWrite } = useContractWrite({
    address: contractAddresses.osiris as `0x${string}`,
    abi: OSIRIS_ABI,
    functionName: 'setPlanWithBudget',
  });

  const { writeAsync: pausePlanWrite } = useContractWrite({
    address: contractAddresses.osiris as `0x${string}`,
    abi: OSIRIS_ABI,
    functionName: 'pausePlan',
  });

  const { writeAsync: resumePlanWrite } = useContractWrite({
    address: contractAddresses.osiris as `0x${string}`,
    abi: OSIRIS_ABI,
    functionName: 'resumePlan',
  });

  const { writeAsync: approveUsdcWrite } = useContractWrite({
    address: contractAddresses.usdc as `0x${string}`,
    abi: USDC_ABI,
    functionName: 'approve',
  });

  const depositUsdc = async (amount: string): Promise<TransactionResult> => {
    const amountWei = parseUnits(amount, 6);

    if (!balancesReady) {
      throw new Error('Balances are still loading. Please wait a moment…');
    }

    if (usdcBalance && usdcBalance.value < amountWei) {
      console.error('Insufficient USDC balance', usdcBalance, amountWei);
      throw new Error('Insufficient USDC balance');
    }

    if (!publicClient) throw new Error('No public client available');

    try {
      // 1) Approve USDC spending
      const approveTxHash = await approveUsdcWrite({
        args: [contractAddresses.osiris as `0x${string}`, amountWei],
      });

      // 2) Wait for approval with proper retry configuration
      const approveReceipt = await waitForTransactionReceipt(publicClient, {
        hash: approveTxHash.hash,
        confirmations: 1, // Attend 1 confirmation
        timeout: 240_000, // 4 minutes
        pollingInterval: 1_000, // Vérifie toutes les secondes
      });

      if (approveReceipt.status !== 'success') {
        throw new Error('Approve transaction failed');
      }

      // 3) Deposit USDC - l'approval est maintenant confirmée
      const depositTxHash = await depositUsdcWrite({ args: [amountWei] });

      const depositReceipt = await waitForTransactionReceipt(publicClient, {
        hash: depositTxHash.hash,
        confirmations: 1,
        timeout: 240_000,
        pollingInterval: 1_000,
      });

      if (depositReceipt.status !== 'success') {
        throw new Error('Deposit transaction failed');
      }

      console.log('USDC deposit completed successfully');
      return {
        hash: depositTxHash.hash,
        status: 'success',
      };
    } catch (error) {
      console.error('Error in depositUsdc:', error);

      // Gestion d'erreur plus spécifique
      if (error instanceof Error) {
        if (error.message.includes('User rejected')) {
          throw new Error('Transaction rejected by user');
        }
        if (error.message.includes('TransactionNotFoundError')) {
          throw new Error(
            'Transaction not found. Please check your wallet and try again.'
          );
        }
      }

      return {
        hash: '',
        status: 'error',
        error,
      };
    }
  };

  const withdrawUsdc = async (amount: string): Promise<TransactionResult> => {
    // Convert to USDC amount (6 decimals)
    const amountWei = parseUnits(amount, 6);
    try {
      const result = await withdrawUsdcWrite({ args: [amountWei] });
      return {
        hash: result.hash,
        status: 'success',
      };
    } catch (error) {
      return {
        hash: '',
        status: 'error',
        error,
      };
    }
  };

  const claimNative = async (amount: string): Promise<TransactionResult> => {
    const amountWei = parseEther(amount);
    try {
      const result = await claimNativeWrite({ args: [amountWei] });
      return {
        hash: result.hash,
        status: 'success',
      };
    } catch (error) {
      return {
        hash: '',
        status: 'error',
        error,
      };
    }
  };

  const setPlanWithBudget = async (
    frequency: Frequency,
    amountPerPeriod: string,
    maxBudgetPerExecution: string,
    enableVolatilityFilter: boolean
  ): Promise<TransactionResult> => {
    // Convert to USDC amount (6 decimals)
    const amountWei = parseUnits(amountPerPeriod, 6);
    // Convert budget to wei (18 decimals for ETH price in USD)
    const budgetWei =
      maxBudgetPerExecution === '0'
        ? BigInt(0)
        : parseUnits(maxBudgetPerExecution, 8);

    try {
      const result = await setPlanWithBudgetWrite({
        args: [frequency, amountWei, budgetWei, enableVolatilityFilter],
      });
      return {
        hash: result.hash,
        status: 'success',
      };
    } catch (error) {
      return {
        hash: '',
        status: 'error',
        error,
      };
    }
  };

  const pausePlan = async (): Promise<TransactionResult> => {
    try {
      const result = await pausePlanWrite({ args: [] });
      return {
        hash: result.hash,
        status: 'success',
      };
    } catch (error) {
      return {
        hash: '',
        status: 'error',
        error,
      };
    }
  };

  const resumePlan = async (): Promise<TransactionResult> => {
    try {
      const result = await resumePlanWrite({ args: [] });
      return {
        hash: result.hash,
        status: 'success',
      };
    } catch (error) {
      return {
        hash: '',
        status: 'error',
        error,
      };
    }
  };

  const approveUsdc = async (amount: string): Promise<TransactionResult> => {
    // Convert to USDC amount (6 decimals)
    const amountWei = parseUnits(amount, 6);
    try {
      const result = await approveUsdcWrite({
        args: [contractAddresses.osiris as `0x${string}`, amountWei],
      });
      return {
        hash: result.hash,
        status: 'success',
      };
    } catch (error) {
      return {
        hash: '',
        status: 'error',
        error,
      };
    }
  };

  // #########################################
  // Format
  // #########################################
  const balances = {
    eth: ethBalance && ethBalance.value ? formatEther(ethBalance.value) : '0',
    usdc:
      usdcBalance && usdcBalance.value && usdcBalance.decimals
        ? formatUnits(usdcBalance.value, usdcBalance.decimals)
        : '0',
    vaultUsdc:
      vaultUsdcBalance && vaultUsdcBalance !== undefined
        ? formatUnits(BigInt(vaultUsdcBalance.toString()), 6)
        : '0', // USDC has 6 decimals
    userUsdc:
      userUsdcBalance && userUsdcBalance !== undefined
        ? formatUnits(BigInt(userUsdcBalance.toString()), 6)
        : '0',
    userNative:
      userNativeBalance && userNativeBalance !== undefined
        ? formatEther(BigInt(userNativeBalance.toString()))
        : '0',
  };

  // Debug logging
  console.log('userPlan data:', userPlan);

  const dcaPlan: DcaPlan | null =
    userPlan &&
    userPlan.freq !== undefined &&
    userPlan.amountPerPeriod !== undefined &&
    userPlan.amountPerPeriod > BigInt(0) // Only consider it a plan if amount > 0
      ? {
          frequency: userPlan.freq as Frequency,
          amountPerPeriod: formatUnits(userPlan.amountPerPeriod, 6), // USDC has 6 decimals
          nextExecutionTimestamp: Number(userPlan.nextExecutionTimestamp),
          maxBudgetPerExecution: userPlan.maxBudgetPerExecution
            ? formatUnits(userPlan.maxBudgetPerExecution, 8) // ETH price in USD has 8 decimals
            : '0',
          enableVolatilityFilter: userPlan.enableVolatilityFilter || false,
          isActive: Number(userPlan.nextExecutionTimestamp) > 0,
        }
      : null;

  console.log('parsed dcaPlan:', dcaPlan);

  const value: WalletContextType = {
    address,
    isConnected,
    chainId,
    balances,
    dcaPlan,
    depositUsdc,
    withdrawUsdc,
    claimNative,
    setPlanWithBudget,
    pausePlan,
    resumePlan,
    approveUsdc,
    isLoading: false, // TODO: Implement loading state
    error: null, // TODO: Implement error state
  };

  return (
    <WalletContext.Provider value={value}>{children}</WalletContext.Provider>
  );
};

export default WalletProvider;
