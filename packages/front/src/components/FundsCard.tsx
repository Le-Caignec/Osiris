import React, { useState } from 'react';
import { useWallet } from '../providers/WalletProvider';

const FundsCard: React.FC = () => {
  const { isConnected, balances, withdrawUsdc, claimNative, depositUsdc } =
    useWallet();
  const [usdcWithdrawAmount, setUsdcWithdrawAmount] = useState('');
  const [usdcDepositAmount, setUsdcDepositAmount] = useState('');
  const [ethWithdrawAmount, setEthWithdrawAmount] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleWithdrawUsdc = async () => {
    if (!isConnected || !usdcWithdrawAmount) return;

    setIsLoading(true);
    try {
      const result = await withdrawUsdc(usdcWithdrawAmount);
      if (result.status === 'success') {
        setUsdcWithdrawAmount('');
      }
    } catch (error) {
      console.error('Error withdrawing USDC:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleDepositUsdc = async () => {
    if (!isConnected || !usdcDepositAmount) return;

    setIsLoading(true);
    try {
      const result = await depositUsdc(usdcDepositAmount);
      if (result.status === 'success') {
        setUsdcDepositAmount('');
      }
    } catch (error) {
      console.error('Error depositing USDC:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleClaimEth = async () => {
    if (!isConnected || !ethWithdrawAmount) return;

    setIsLoading(true);
    try {
      const result = await claimNative(ethWithdrawAmount);
      if (result.status === 'success') {
        setEthWithdrawAmount('');
      }
    } catch (error) {
      console.error('Error claiming ETH:', error);
    } finally {
      setIsLoading(false);
    }
  };

  if (!isConnected) {
    return (
      <div className='bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-6 border border-gray-700 shadow-xl'>
        <div className='flex items-center space-x-3 mb-6'>
          <div className='w-10 h-10 bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl flex items-center justify-center'>
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
          <h3 className='text-xl font-bold text-white'>Fund Management</h3>
        </div>
        <p className='text-gray-400'>Connect your wallet to manage funds</p>
      </div>
    );
  }

  return (
    <div className='bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-4 sm:p-6 border border-gray-700 shadow-xl hover:shadow-2xl transition-all duration-300'>
      <div className='flex items-center space-x-3 mb-3 sm:mb-4'>
        <div className='w-8 h-8 sm:w-10 sm:h-10 bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl flex items-center justify-center flex-shrink-0'>
          <svg
            className='w-4 h-4 sm:w-5 sm:h-5 text-white'
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
        <h3 className='text-lg sm:text-xl font-bold text-white'>
          Fund Management
        </h3>
      </div>

      <div className='grid grid-cols-1 lg:grid-cols-3 gap-3 sm:gap-4'>
        {/* USDC Deposit */}
        <div className='bg-gray-700/50 rounded-xl p-3 sm:p-4 hover:bg-gray-700/70 transition-colors duration-200'>
          <div className='flex items-center space-x-3 mb-3 sm:mb-4'>
            <div className='w-6 h-6 sm:w-8 sm:h-8 bg-green-600 rounded-lg flex items-center justify-center flex-shrink-0'>
              <svg
                className='w-3 h-3 sm:w-4 sm:h-4 text-white'
                fill='none'
                stroke='currentColor'
                viewBox='0 0 24 24'
              >
                <path
                  strokeLinecap='round'
                  strokeLinejoin='round'
                  strokeWidth={2}
                  d='M12 6v6m0 0v6m0-6h6m-6 0H6'
                />
              </svg>
            </div>
            <span className='text-gray-300 font-medium text-sm sm:text-base'>
              USDC Deposit
            </span>
          </div>

          <div className='flex flex-col gap-2 sm:gap-3'>
            <input
              type='number'
              value={usdcDepositAmount}
              onChange={e => setUsdcDepositAmount(e.target.value)}
              className='w-full bg-gray-600 text-white rounded-xl p-2 sm:p-3 border border-gray-500 focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-500/20 transition-all duration-200 text-sm sm:text-base'
              placeholder='Amount to deposit'
            />
            <button
              onClick={handleDepositUsdc}
              disabled={!usdcDepositAmount || isLoading}
              className='bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed text-white px-3 sm:px-4 py-2 sm:py-3 rounded-xl font-semibold transition-all duration-200 w-full whitespace-nowrap text-sm sm:text-base'
            >
              Deposit
            </button>
          </div>
        </div>

        {/* USDC Withdraw */}
        <div className='bg-gray-700/50 rounded-xl p-3 sm:p-4 hover:bg-gray-700/70 transition-colors duration-200'>
          <div className='flex items-center space-x-3 mb-3 sm:mb-4'>
            <div className='w-6 h-6 sm:w-8 sm:h-8 bg-red-600 rounded-lg flex items-center justify-center flex-shrink-0'>
              <svg
                className='w-3 h-3 sm:w-4 sm:h-4 text-white'
                fill='none'
                stroke='currentColor'
                viewBox='0 0 24 24'
              >
                <path
                  strokeLinecap='round'
                  strokeLinejoin='round'
                  strokeWidth={2}
                  d='M20 12H4m16 0l-4-4m4 4l-4 4'
                />
              </svg>
            </div>
            <span className='text-gray-300 font-medium text-sm sm:text-base'>
              USDC Withdrawal
            </span>
          </div>

          <div className='flex flex-col sm:flex-row sm:justify-between sm:items-center mb-3 gap-1 sm:gap-0'>
            <span className='text-gray-400 text-xs sm:text-sm'>
              Your USDC Available
            </span>
            <span className='text-red-400 font-bold text-sm sm:text-base'>
              ${parseFloat(balances.userUsdc).toFixed(2)}
            </span>
          </div>

          <div className='flex flex-col gap-2 sm:gap-3'>
            <input
              type='number'
              value={usdcWithdrawAmount}
              onChange={e => setUsdcWithdrawAmount(e.target.value)}
              className='w-full bg-gray-600 text-white rounded-xl p-2 sm:p-3 border border-gray-500 focus:border-red-500 focus:outline-none focus:ring-2 focus:ring-red-500/20 transition-all duration-200 text-sm sm:text-base'
              placeholder='Amount to withdraw'
            />
            <button
              onClick={handleWithdrawUsdc}
              disabled={
                !usdcWithdrawAmount ||
                isLoading ||
                parseFloat(usdcWithdrawAmount) > parseFloat(balances.userUsdc)
              }
              className='bg-gradient-to-r from-red-600 to-red-700 hover:from-red-700 hover:to-red-800 disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed text-white px-3 sm:px-4 py-2 sm:py-3 rounded-xl font-semibold transition-all duration-200 w-full whitespace-nowrap text-sm sm:text-base'
            >
              Withdraw
            </button>
          </div>
        </div>

        {/* ETH Claim */}
        <div className='bg-gray-700/50 rounded-xl p-3 sm:p-4 hover:bg-gray-700/70 transition-colors duration-200'>
          <div className='flex items-center space-x-3 mb-3 sm:mb-4'>
            <div className='w-6 h-6 sm:w-8 sm:h-8 bg-yellow-600 rounded-lg flex items-center justify-center flex-shrink-0'>
              <svg
                className='w-3 h-3 sm:w-4 sm:h-4 text-white'
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
            </div>
            <span className='text-gray-300 font-medium text-sm sm:text-base'>
              ETH Claim
            </span>
          </div>

          <div className='flex flex-col sm:flex-row sm:justify-between sm:items-center mb-3 gap-1 sm:gap-0'>
            <span className='text-gray-400 text-xs sm:text-sm'>
              Available ETH
            </span>
            <span className='text-yellow-400 font-bold text-sm sm:text-base'>
              {parseFloat(balances.userNative).toFixed(4)} ETH
            </span>
          </div>

          <div className='flex flex-col gap-2 sm:gap-3'>
            <input
              type='number'
              value={ethWithdrawAmount}
              onChange={e => setEthWithdrawAmount(e.target.value)}
              className='w-full bg-gray-600 text-white rounded-xl p-2 sm:p-3 border border-gray-500 focus:border-yellow-500 focus:outline-none focus:ring-2 focus:ring-yellow-500/20 transition-all duration-200 text-sm sm:text-base'
              placeholder='Amount to claim'
            />
            <button
              onClick={handleClaimEth}
              disabled={
                !ethWithdrawAmount ||
                isLoading ||
                parseFloat(ethWithdrawAmount) > parseFloat(balances.userNative)
              }
              className='bg-gradient-to-r from-yellow-600 to-yellow-700 hover:from-yellow-700 hover:to-yellow-800 disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed text-white px-3 sm:px-4 py-2 sm:py-3 rounded-xl font-semibold transition-all duration-200 w-full whitespace-nowrap text-sm sm:text-base'
            >
              Claim
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FundsCard;
