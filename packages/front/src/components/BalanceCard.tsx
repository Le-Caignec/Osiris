import React from 'react';
import { useWallet } from '../providers/WalletProvider';

const BalanceCard: React.FC = () => {
  const { isConnected, balances, chainId } = useWallet();

  if (!isConnected) {
    return (
      <div className='bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-6 border border-gray-700 shadow-xl'>
        <div className='flex items-center space-x-3 mb-6'>
          <div className='w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center'>
            <svg
              className='w-5 h-5 text-white'
              fill='none'
              stroke='currentColor'
              viewBox='0 0 24 24'
            >
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                strokeWidth={2}
                d='M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1'
              />
            </svg>
          </div>
          <h3 className='text-xl font-bold text-white'>Balances</h3>
        </div>
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

  const getNetworkColor = () => {
    if (chainId === 1) return 'from-blue-500 to-blue-600';
    if (chainId === 11155111) return 'from-purple-500 to-purple-600';
    return 'from-gray-500 to-gray-600';
  };

  const balanceItems = [
    {
      icon: (
        <svg
          className='w-5 h-5 text-green-400'
          fill='none'
          stroke='currentColor'
          viewBox='0 0 24 24'
        >
          <path
            strokeLinecap='round'
            strokeLinejoin='round'
            strokeWidth={2}
            d='M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4'
          />
        </svg>
      ),
      label: 'Vault Total USDC',
      value: `$${formatBalance(balances.vaultUsdc, 2)}`,
      color: 'text-green-400',
    },
    {
      icon: (
        <svg
          className='w-5 h-5 text-blue-400'
          fill='none'
          stroke='currentColor'
          viewBox='0 0 24 24'
        >
          <path
            strokeLinecap='round'
            strokeLinejoin='round'
            strokeWidth={2}
            d='M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z'
          />
        </svg>
      ),
      label: 'Your USDC Balance',
      value: `$${formatBalance(balances.userUsdc, 2)}`,
      color: 'text-blue-400',
    },
    {
      icon: (
        <svg
          className='w-5 h-5 text-yellow-400'
          fill='none'
          stroke='currentColor'
          viewBox='0 0 24 24'
        >
          <path
            strokeLinecap='round'
            strokeLinejoin='round'
            strokeWidth={2}
            d='M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1'
          />
        </svg>
      ),
      label: 'Your ETH Balance',
      value: `${formatBalance(balances.eth, 4)} ETH`,
      color: 'text-yellow-400',
    },
    {
      icon: (
        <svg
          className='w-5 h-5 text-purple-400'
          fill='none'
          stroke='currentColor'
          viewBox='0 0 24 24'
        >
          <path
            strokeLinecap='round'
            strokeLinejoin='round'
            strokeWidth={2}
            d='M13 10V3L4 14h7v7l9-11h-7z'
          />
        </svg>
      ),
      label: 'Native ETH Available',
      value: `${formatBalance(balances.userNative, 4)} ETH`,
      color: 'text-purple-400',
    },
  ];

  return (
    <div className='bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-6 border border-gray-700 shadow-xl hover:shadow-2xl transition-all duration-300 min-h-[400px] flex flex-col'>
      <div className='flex items-center justify-between mb-6'>
        <div className='flex items-center space-x-3'>
          <div className='w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center'>
            <svg
              className='w-5 h-5 text-white'
              fill='none'
              stroke='currentColor'
              viewBox='0 0 24 24'
            >
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                strokeWidth={2}
                d='M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1'
              />
            </svg>
          </div>
          <h3 className='text-xl font-bold text-white'>Balances</h3>
        </div>
        <div
          className={`px-3 py-1 rounded-full bg-gradient-to-r ${getNetworkColor()} text-white text-sm font-medium`}
        >
          {getNetworkName()}
        </div>
      </div>

      <div className='space-y-4 flex-1'>
        {balanceItems.map((item, index) => (
          <div
            key={index}
            className='flex items-center justify-between p-3 bg-gray-700/50 rounded-xl hover:bg-gray-700/70 transition-colors duration-200'
          >
            <div className='flex items-center space-x-3'>
              <div className='w-8 h-8 bg-gray-600 rounded-lg flex items-center justify-center'>
                {item.icon}
              </div>
              <span className='text-gray-300 font-medium'>{item.label}</span>
            </div>
            <span className={`font-bold ${item.color}`}>{item.value}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default BalanceCard;
