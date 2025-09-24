import React from 'react';
import { useWallet } from '../providers/WalletProvider';
import BalanceCard from './BalanceCard';
import DcaPlanCard from './DcaPlanCard';
import WithdrawCard from './WithdrawCard';

const Dashboard: React.FC = () => {
  const { isConnected } = useWallet();

  if (!isConnected) {
    return (
      <div className='min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center'>
        <div className='text-center space-y-4'>
          <h1 className='text-4xl font-bold text-white'>Welcome to OSIRIS</h1>
          <p className='text-gray-300 text-lg'>
            Connect your wallet to get started
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className='min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900'>
      <div className='container mx-auto px-4 py-8'>
        <div className='mb-8'>
          <h1 className='text-4xl font-bold text-white mb-2'>Dashboard</h1>
          <p className='text-gray-300'>Manage your DCA investments</p>
        </div>

        <div className='grid grid-cols-1 lg:grid-cols-2 gap-8'>
          <BalanceCard />
          <DcaPlanCard />
        </div>

        <div className='mt-8'>
          <WithdrawCard />
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
