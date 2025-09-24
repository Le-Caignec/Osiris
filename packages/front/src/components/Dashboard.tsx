import React from 'react';
import { useWallet } from '../providers/WalletProvider';
import BalanceCard from './BalanceCard';
import DcaPlanCard from './DcaPlanCard';
import FundsCard from './FundsCard';

const Dashboard: React.FC = () => {
  const { isConnected } = useWallet();

  if (!isConnected) {
    return (
      <div className='min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center'>
        <div className='text-center space-y-6 max-w-md mx-auto px-4'>
          <div className='w-20 h-20 bg-gradient-to-br from-primary-500 to-primary-700 rounded-full flex items-center justify-center mx-auto mb-4'>
            <svg
              className='w-10 h-10 text-white'
              fill='none'
              stroke='currentColor'
              viewBox='0 0 24 24'
            >
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                strokeWidth={2}
                d='M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z'
              />
            </svg>
          </div>
          <h1 className='text-4xl font-bold text-white'>Welcome to OSIRIS</h1>
          <p className='text-gray-300 text-lg leading-relaxed'>
            Connect your wallet to start managing your DCA investments
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className='min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900'>
      <div className='container mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6 lg:py-8'>
        {/* Header Section */}
        <div className='mb-6 sm:mb-8 lg:mb-12'>
          <div className='flex flex-col sm:flex-row sm:items-center space-y-3 sm:space-y-0 sm:space-x-4 mb-4'>
            <div className='w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-primary-500 to-primary-700 rounded-xl flex items-center justify-center flex-shrink-0'>
              <svg
                className='w-5 h-5 sm:w-6 sm:h-6 text-white'
                fill='none'
                stroke='currentColor'
                viewBox='0 0 24 24'
              >
                <path
                  strokeLinecap='round'
                  strokeLinejoin='round'
                  strokeWidth={2}
                  d='M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z'
                />
              </svg>
            </div>
            <div className='min-w-0'>
              <h1 className='text-2xl sm:text-3xl lg:text-4xl font-bold text-white truncate'>
                Dashboard
              </h1>
              <p className='text-gray-300 text-sm sm:text-base lg:text-lg'>
                Manage your DCA investments
              </p>
            </div>
          </div>
        </div>

        {/* Main Content Grid */}
        <div className='grid grid-cols-1 xl:grid-cols-12 gap-4 sm:gap-6 lg:gap-8 min-h-[400px] sm:min-h-[500px] lg:min-h-[600px]'>
          {/* Left Column - Balances */}
          <div className='xl:col-span-4 space-y-4 sm:space-y-6 order-2 xl:order-1'>
            <BalanceCard />
            <FundsCard />
          </div>

          {/* Right Column - DCA Plan */}
          <div className='xl:col-span-8 order-1 xl:order-2'>
            <DcaPlanCard />
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
