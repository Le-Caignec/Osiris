import React from 'react';
import { useWallet } from '../providers/WalletProvider';

const BalanceCard: React.FC = () => {
  const { isConnected, balances, chainId } = useWallet();

  if (!isConnected) {
    return (
      <div className='bg-gray-800 rounded-xl p-6'>
        <h3 className='text-lg font-semibold text-white mb-4'>Balances</h3>
        <p className='text-gray-400'>Connect your wallet to view balances</p>
      </div>
    );
  }

  const formatBalance = (balance: string, decimals: number = 4) => {
    const num = parseFloat(balance);
    return num.toFixed(decimals);
  };

  const getNetworkName = () => {
    if (chainId === 1) return 'Ethereum';
    if (chainId === 11155111) return 'Sepolia';
    return 'Unknown';
  };

  return (
    <div className='bg-gray-800 rounded-xl p-6 space-y-4'>
      <div className='flex items-center justify-between'>
        <h3 className='text-lg font-semibold text-white'>Balances</h3>
        <span className='text-sm text-gray-400'>{getNetworkName()}</span>
      </div>

      <div className='space-y-3'>
        {/* Vault Total USDC */}
        <div className='flex justify-between items-center'>
          <span className='text-gray-300'>Vault Total USDC</span>
          <span className='text-white font-semibold'>
            ${formatBalance(balances.vaultUsdc, 2)}
          </span>
        </div>

        {/* User USDC Balance */}
        <div className='flex justify-between items-center'>
          <span className='text-gray-300'>Your USDC Balance</span>
          <span className='text-white font-semibold'>
            ${formatBalance(balances.userUsdc, 2)}
          </span>
        </div>

        {/* User ETH Balance */}
        <div className='flex justify-between items-center'>
          <span className='text-gray-300'>Your ETH Balance</span>
          <span className='text-white font-semibold'>
            {formatBalance(balances.eth, 4)} ETH
          </span>
        </div>

        {/* Native Available for Withdraw */}
        <div className='flex justify-between items-center'>
          <span className='text-gray-300'>Native ETH Available</span>
          <span className='text-white font-semibold'>
            {formatBalance(balances.userNative, 4)} ETH
          </span>
        </div>
      </div>
    </div>
  );
};

export default BalanceCard;
