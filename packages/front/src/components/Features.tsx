import React from 'react';
import { useWallet } from '../providers/WalletProvider';

const Features: React.FC = () => {
  const { isConnected, balances } = useWallet();

  const formatBalance = (balance: string, decimals: number = 4) => {
    const num = parseFloat(balance);
    return num.toFixed(decimals);
  };

  const stats = [
    {
      icon: (
        <svg
          className='w-8 h-8 text-green-400'
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
      title: 'Vault Total USDC',
      value: `$${formatBalance(balances.vaultUsdc, 2)}`,
      description: 'Total USDC in Osiris vault',
      color: 'text-green-400',
    },
    {
      icon: (
        <svg
          className='w-8 h-8 text-yellow-400'
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
      title: 'Available ETH',
      value: `${formatBalance(balances.userNative, 4)} ETH`,
      description: 'ETH available to claim',
      color: 'text-yellow-400',
    },
    {
      icon: (
        <svg
          className='w-8 h-8 text-blue-400'
          fill='none'
          stroke='currentColor'
          viewBox='0 0 24 24'
        >
          <path
            strokeLinecap='round'
            strokeLinejoin='round'
            strokeWidth={2}
            d='M13 7h8m0 0v8m0-8l-8 8-4-4-6 6'
          />
        </svg>
      ),
      title: 'Pool Yield Rate',
      value: '9.00%',
      description: 'Automatic yield benefit on the pool',
      color: 'text-blue-400',
    },
  ];

  if (!isConnected) {
    return null;
  }

  return (
    <section className='py-8'>
      <div className='grid grid-cols-1 md:grid-cols-3 gap-4'>
        {stats.map((stat, index) => (
          <div key={index} className='bg-gray-800 rounded-lg p-4 space-y-2'>
            <div className='flex items-center justify-center w-10 h-10 bg-gray-700 rounded-lg'>
              {stat.icon}
            </div>
            <h3 className='text-base font-bold text-white'>{stat.title}</h3>
            <p className={`text-xl font-bold ${stat.color}`}>{stat.value}</p>
            <p className='text-gray-300 text-xs'>{stat.description}</p>
          </div>
        ))}
      </div>
    </section>
  );
};

export default Features;
