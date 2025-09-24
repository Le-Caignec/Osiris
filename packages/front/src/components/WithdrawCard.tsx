import React, { useState } from 'react';
import { useWallet } from '../providers/WalletProvider';

const WithdrawCard: React.FC = () => {
  const { isConnected, balances, withdrawUsdc, claimNative, isLoading } =
    useWallet();
  const [usdcWithdrawAmount, setUsdcWithdrawAmount] = useState('');
  const [ethWithdrawAmount, setEthWithdrawAmount] = useState('');

  const handleWithdrawUsdc = async () => {
    if (!isConnected || !usdcWithdrawAmount) return;

    try {
      await withdrawUsdc(usdcWithdrawAmount);
      setUsdcWithdrawAmount('');
    } catch (error) {
      console.error('Error withdrawing USDC:', error);
    }
  };

  const handleClaimEth = async () => {
    if (!isConnected || !ethWithdrawAmount) return;

    try {
      await claimNative(ethWithdrawAmount);
      setEthWithdrawAmount('');
    } catch (error) {
      console.error('Error claiming ETH:', error);
    }
  };

  if (!isConnected) {
    return (
      <div className='bg-gray-800 rounded-xl p-6'>
        <h3 className='text-lg font-semibold text-white mb-4'>
          Withdraw Funds
        </h3>
        <p className='text-gray-400'>Connect your wallet to withdraw funds</p>
      </div>
    );
  }

  return (
    <div className='bg-gray-800 rounded-xl p-6 space-y-6'>
      <h3 className='text-lg font-semibold text-white'>Withdraw Funds</h3>

      {/* USDC Withdraw */}
      <div className='space-y-3'>
        <div className='flex justify-between items-center'>
          <span className='text-gray-300'>Available USDC</span>
          <span className='text-white font-semibold'>
            ${parseFloat(balances.userUsdc).toFixed(2)}
          </span>
        </div>

        <div className='flex space-x-2'>
          <input
            type='number'
            value={usdcWithdrawAmount}
            onChange={e => setUsdcWithdrawAmount(e.target.value)}
            className='flex-1 bg-gray-700 text-white rounded-lg p-3 border border-gray-600 focus:border-primary-500 focus:outline-none'
            placeholder='Amount to withdraw'
          />
          <button
            onClick={handleWithdrawUsdc}
            disabled={
              !usdcWithdrawAmount ||
              isLoading ||
              parseFloat(usdcWithdrawAmount) > parseFloat(balances.userUsdc)
            }
            className='bg-red-600 hover:bg-red-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white px-6 py-3 rounded-lg font-semibold transition-colors'
          >
            Withdraw USDC
          </button>
        </div>
      </div>

      {/* ETH Claim */}
      <div className='space-y-3'>
        <div className='flex justify-between items-center'>
          <span className='text-gray-300'>Available ETH</span>
          <span className='text-white font-semibold'>
            {parseFloat(balances.userNative).toFixed(4)} ETH
          </span>
        </div>

        <div className='flex space-x-2'>
          <input
            type='number'
            value={ethWithdrawAmount}
            onChange={e => setEthWithdrawAmount(e.target.value)}
            className='flex-1 bg-gray-700 text-white rounded-lg p-3 border border-gray-600 focus:border-primary-500 focus:outline-none'
            placeholder='Amount to claim'
          />
          <button
            onClick={handleClaimEth}
            disabled={
              !ethWithdrawAmount ||
              isLoading ||
              parseFloat(ethWithdrawAmount) > parseFloat(balances.userNative)
            }
            className='bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white px-6 py-3 rounded-lg font-semibold transition-colors'
          >
            Claim ETH
          </button>
        </div>
      </div>
    </div>
  );
};

export default WithdrawCard;
