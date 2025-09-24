import React, { createContext, useContext, useState } from 'react';
import {
  useAccount,
  useBalance,
  useContractRead,
  useContractWrite,
  useChainId,
} from 'wagmi';
import { parseEther, formatEther, formatUnits } from 'viem';
import {
  CONTRACT_ADDRESSES,
  OSIRIS_ABI,
  USDC_ABI,
  Frequency,
} from '../config/contracts';

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
  depositUsdc: (amount: string) => Promise<void>;
  withdrawUsdc: (amount: string) => Promise<void>;
  claimNative: (amount: string) => Promise<void>;
  setPlan: (frequency: Frequency, amountPerPeriod: string) => Promise<void>;
  pausePlan: () => Promise<void>;
  resumePlan: () => Promise<void>;
  approveUsdc: (amount: string) => Promise<void>;
  isLoading: boolean;
  error: string | null;
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
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Get contract addresses based on current chain
  const getContractAddresses = () => {
    if (chainId === 1) return CONTRACT_ADDRESSES.ethereum;
    if (chainId === 11155111) return CONTRACT_ADDRESSES.sepolia;
    return CONTRACT_ADDRESSES.sepolia; // Default to Sepolia
  };

  const contractAddresses = getContractAddresses();

  // Read balances
  const { data: ethBalance } = useBalance({
    address,
    enabled: isConnected,
  });

  const { data: usdcBalance } = useBalance({
    address,
    token: contractAddresses.usdc as `0x${string}`,
    enabled: isConnected,
  });

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

  // Contract write functions
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

  // Helper functions
  const handleTransaction = async (txFn: () => Promise<any>) => {
    try {
      setIsLoading(true);
      setError(null);
      const tx = await txFn();
      await tx.wait();
    } catch (err: any) {
      setError(err.message || 'Transaction failed');
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  const depositUsdc = async (amount: string) => {
    const amountWei = parseEther(amount);
    await handleTransaction(() => depositUsdcWrite({ args: [amountWei] }));
  };

  const withdrawUsdc = async (amount: string) => {
    const amountWei = parseEther(amount);
    await handleTransaction(() => withdrawUsdcWrite({ args: [amountWei] }));
  };

  const claimNative = async (amount: string) => {
    const amountWei = parseEther(amount);
    await handleTransaction(() => claimNativeWrite({ args: [amountWei] }));
  };

  const setPlan = async (frequency: Frequency, amountPerPeriod: string) => {
    const amountWei = parseEther(amountPerPeriod);
    await handleTransaction(() =>
      setPlanWrite({ args: [frequency, amountWei] })
    );
  };

  const pausePlan = async () => {
    await handleTransaction(() => pausePlanWrite());
  };

  const resumePlan = async () => {
    await handleTransaction(() => resumePlanWrite());
  };

  const approveUsdc = async (amount: string) => {
    const amountWei = parseEther(amount);
    await handleTransaction(() =>
      approveUsdcWrite({
        args: [contractAddresses.osiris as `0x${string}`, amountWei],
      })
    );
  };

  // Format balances
  const balances = {
    eth: ethBalance ? formatEther(ethBalance.value) : '0',
    usdc: usdcBalance
      ? formatUnits(usdcBalance.value, usdcBalance.decimals)
      : '0',
    vaultUsdc: vaultUsdcBalance
      ? formatUnits(BigInt(vaultUsdcBalance.toString()), 6)
      : '0', // USDC has 6 decimals
    userUsdc: userUsdcBalance
      ? formatUnits(BigInt(userUsdcBalance.toString()), 6)
      : '0',
    userNative: userNativeBalance
      ? formatEther(BigInt(userNativeBalance.toString()))
      : '0',
  };

  // Format DCA plan data
  const dcaPlan = userPlan
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
    isLoading,
    error,
  };

  return (
    <WalletContext.Provider value={value}>{children}</WalletContext.Provider>
  );
};

export default WalletProvider;
