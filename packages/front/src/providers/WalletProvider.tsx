import React, { createContext, useContext } from 'react';
import {
  useAccount,
  useBalance,
  useContractRead,
  useContractWrite,
  useChainId,
} from 'wagmi';
import { parseEther, parseUnits, formatEther, formatUnits } from 'viem';
import {
  CONTRACT_ADDRESSES,
  OSIRIS_ABI,
  USDC_ABI,
  Frequency,
} from '../config/contracts';

interface TransactionResult {
  hash: string;
  status: 'pending' | 'success' | 'error';
  error?: any;
}

interface WalletContextType {
  address: string | undefined;
  isConnected: boolean;
  chainId: number | undefined;
  balances: {
    eth: string;
    usdc: string;
    vaultUsdc: string;
    userUsdc: string;
    userNative: string;
  };
  dcaPlan: {
    frequency: Frequency;
    amountPerPeriod: string;
    nextExecutionTimestamp: number;
    isActive: boolean;
  } | null;
  depositUsdc: (amount: string) => Promise<TransactionResult>;
  withdrawUsdc: (amount: string) => Promise<TransactionResult>;
  claimNative: (amount: string) => Promise<TransactionResult>;
  setPlan: (
    frequency: Frequency,
    amountPerPeriod: string
  ) => Promise<TransactionResult>;
  pausePlan: () => Promise<TransactionResult>;
  resumePlan: () => Promise<TransactionResult>;
  approveUsdc: (amount: string) => Promise<TransactionResult>;
}

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

  const { writeAsync: setPlanWrite } = useContractWrite({
    address: contractAddresses.osiris as `0x${string}`,
    abi: OSIRIS_ABI,
    functionName: 'setPlan',
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
    // Convert to USDC amount (6 decimals)
    const amountWei = parseUnits(amount, 6);

    if (!balancesReady) {
      throw new Error('Balances are still loading. Please wait a moment…');
    }

    // Check if user has enough USDC balance
    if (usdcBalance && usdcBalance.value < amountWei) {
      console.error('Insufficient USDC balance', usdcBalance, amountWei);
      throw new Error('Insufficient USDC balance');
    }

    try {
      // First approve USDC spending
      await approveUsdcWrite({
        args: [contractAddresses.osiris as `0x${string}`, amountWei],
      });

      // Then deposit USDC
      const depositResult = await depositUsdcWrite({ args: [amountWei] });

      return {
        hash: depositResult.hash,
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

  const setPlan = async (
    frequency: Frequency,
    amountPerPeriod: string
  ): Promise<TransactionResult> => {
    // Convert to USDC amount (6 decimals)
    const amountWei = parseUnits(amountPerPeriod, 6);
    try {
      const result = await setPlanWrite({ args: [frequency, amountWei] });
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

  const dcaPlan =
    userPlan && (userPlan as any)[1] !== undefined
      ? {
          frequency: (userPlan as any)[0] as Frequency,
          amountPerPeriod: formatUnits((userPlan as any)[1], 6), // USDC has 6 decimals
          nextExecutionTimestamp: Number((userPlan as any)[2]),
          isActive: Number((userPlan as any)[2]) > 0,
        }
      : null;

  const value: WalletContextType = {
    address,
    isConnected,
    chainId,
    balances,
    dcaPlan,
    depositUsdc,
    withdrawUsdc,
    claimNative,
    setPlan,
    pausePlan,
    resumePlan,
    approveUsdc,
  };

  return (
    <WalletContext.Provider value={value}>{children}</WalletContext.Provider>
  );
};

export default WalletProvider;
