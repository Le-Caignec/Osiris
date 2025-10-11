import React, { useState } from 'react';
import { useWallet } from '../providers/WalletProvider';
import { format } from 'date-fns';

const DcaPlanCard: React.FC = () => {
  const { isConnected, dcaPlan, setPlanWithBudget, pausePlan, resumePlan } =
    useWallet();
  const [isEditing, setIsEditing] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [editFrequency, setEditFrequency] = useState(dcaPlan?.frequency || 1);
  const [editAmount, setEditAmount] = useState(
    dcaPlan?.amountPerPeriod || '50'
  );
  const [editMaxBudget, setEditMaxBudget] = useState(
    dcaPlan?.maxBudgetPerExecution || '0'
  );
  const [editVolatilityFilter, setEditVolatilityFilter] = useState(
    dcaPlan?.enableVolatilityFilter || false
  );

  const handleCreatePlan = async () => {
    if (!isConnected) return;

    setIsLoading(true);
    try {
      const result = await setPlanWithBudget(
        editFrequency,
        editAmount,
        editMaxBudget,
        editVolatilityFilter
      );
      if (result.status === 'success') {
        setIsCreating(false);
      }
    } catch (error) {
      console.error('Error creating plan:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSavePlan = async () => {
    if (!isConnected) return;

    setIsLoading(true);
    try {
      const result = await setPlanWithBudget(
        editFrequency,
        editAmount,
        editMaxBudget,
        editVolatilityFilter
      );
      if (result.status === 'success') {
        setIsEditing(false);
      }
    } catch (error) {
      console.error('Error updating plan:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handlePauseResume = async () => {
    if (!isConnected || !dcaPlan) return;

    setIsLoading(true);
    try {
      if (dcaPlan.isActive) {
        await pausePlan();
      } else {
        await resumePlan();
      }
    } catch (error) {
      console.error('Error pausing/resuming plan:', error);
    } finally {
      setIsLoading(false);
    }
  };

  if (!isConnected) {
    return (
      <div className='bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-8 border border-gray-700 shadow-xl'>
        <div className='flex items-center space-x-3 mb-6'>
          <div className='w-12 h-12 bg-gradient-to-br from-primary-500 to-primary-700 rounded-xl flex items-center justify-center'>
            <svg
              className='w-6 h-6 text-white'
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
          <h3 className='text-2xl font-bold text-white'>DCA Plan</h3>
        </div>
        <p className='text-gray-400 text-lg'>
          Connect your wallet to view your DCA plan
        </p>
      </div>
    );
  }

  if (!dcaPlan) {
    return (
      <div className='bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-6 border border-gray-700 shadow-xl flex flex-col h-full min-h-[600px]'>
        <div className='flex items-center space-x-3 mb-6'>
          <div className='w-10 h-10 bg-gradient-to-br from-primary-500 to-primary-700 rounded-xl flex items-center justify-center'>
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
                d='M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z'
              />
            </svg>
          </div>
          <h3 className='text-xl font-bold text-white'>DCA Plan</h3>
        </div>

        {isCreating ? (
          <div className='space-y-4 flex flex-col flex-1'>
            <div className='text-center mb-4'>
              <div className='w-12 h-12 bg-primary-600/20 rounded-full flex items-center justify-center mx-auto mb-3'>
                <svg
                  className='w-6 h-6 text-primary-400'
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
              <h4 className='text-xl font-semibold text-white mb-2'>
                Create DCA Plan
              </h4>
              <p className='text-gray-400 text-sm'>
                Set up your automated investment strategy
              </p>
            </div>

            <div className='grid grid-cols-2 gap-3'>
              <div>
                <label className='block text-sm font-medium text-gray-300 mb-2'>
                  Frequency
                </label>
                <select
                  value={editFrequency}
                  onChange={e => setEditFrequency(Number(e.target.value))}
                  className='w-full bg-gray-700 text-white rounded-lg p-3 border border-gray-600 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 transition-all duration-200 text-sm'
                >
                  <option value={0}>Daily</option>
                  <option value={1}>Weekly</option>
                  <option value={2}>Monthly</option>
                </select>
              </div>

              <div>
                <label className='block text-sm font-medium text-gray-300 mb-2'>
                  Amount (USDC)
                </label>
                <input
                  type='number'
                  value={editAmount}
                  onChange={e => setEditAmount(e.target.value)}
                  className='w-full bg-gray-700 text-white rounded-lg p-3 border border-gray-600 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 transition-all duration-200 text-sm'
                  placeholder='50'
                />
              </div>
            </div>

            {/* Budget Protection */}
            <div>
              <label className='block text-sm font-medium text-gray-300 mb-2'>
                Max ETH Price (USD)
              </label>
              <input
                type='number'
                value={editMaxBudget}
                onChange={e => setEditMaxBudget(e.target.value)}
                className='w-full bg-gray-700 text-white rounded-lg p-3 border border-gray-600 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 transition-all duration-200 text-sm'
                placeholder='3000 (0 = no limit)'
              />
              <p className='text-xs text-gray-400 mt-1'>
                Maximum USD price per ETH. Leave 0 for no limit.
              </p>
            </div>

            {/* Volatility Filter */}
            <div>
              <div className='flex items-center space-x-3 p-3 bg-gray-700/50 rounded-lg border border-gray-600'>
                <input
                  type='checkbox'
                  id='volatilityFilter'
                  checked={editVolatilityFilter}
                  onChange={e => setEditVolatilityFilter(e.target.checked)}
                  className='w-4 h-4 text-primary-600 bg-gray-700 border-gray-600 rounded focus:ring-primary-500 focus:ring-2'
                />
                <label
                  htmlFor='volatilityFilter'
                  className='text-gray-300 text-sm'
                >
                  Skip execution during high volatility
                </label>
              </div>
              <p className='text-xs text-gray-400 mt-1'>
                Skip DCA if market volatility exceeds 5%.
              </p>
            </div>

            <div className='flex gap-3 mt-auto'>
              <button
                onClick={() => setIsCreating(false)}
                className='flex-1 bg-gray-700 hover:bg-gray-600 text-gray-300 hover:text-white py-3 rounded-lg font-semibold transition-all duration-200 text-sm'
              >
                Cancel
              </button>
              <button
                onClick={handleCreatePlan}
                disabled={isLoading || !editAmount}
                className='flex-1 bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-700 hover:to-primary-800 disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed text-white py-3 rounded-lg font-semibold transition-all duration-200 text-sm'
              >
                {isLoading ? 'Creating...' : 'Create Plan'}
              </button>
            </div>
          </div>
        ) : (
          <div className='text-center flex flex-col justify-center items-center flex-1'>
            <div className='w-16 h-16 bg-gray-700/50 rounded-full flex items-center justify-center mx-auto mb-6'>
              <svg
                className='w-8 h-8 text-gray-400'
                fill='none'
                stroke='currentColor'
                viewBox='0 0 24 24'
              >
                <path
                  strokeLinecap='round'
                  strokeLinejoin='round'
                  strokeWidth={2}
                  d='M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z'
                />
              </svg>
            </div>
            <h4 className='text-xl font-semibold text-white mb-3'>
              No active DCA plan found
            </h4>
            <p className='text-gray-400 text-base mb-8 max-w-md'>
              Create a plan to start automated investing
            </p>
            <button
              onClick={() => setIsCreating(true)}
              className='bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-700 hover:to-primary-800 text-white px-6 py-3 rounded-xl font-semibold text-base transition-all duration-200 transform hover:scale-105'
            >
              Create DCA Plan
            </button>
          </div>
        )}
      </div>
    );
  }

  const formatDate = (timestamp: number) => {
    if (timestamp === 0) return 'Not scheduled';
    return format(new Date(timestamp * 1000), 'MMM dd, yyyy HH:mm');
  };

  const getFrequencyLabel = (freq: number) => {
    switch (freq) {
      case 0:
        return 'Daily';
      case 1:
        return 'Weekly';
      case 2:
        return 'Monthly';
      default:
        return 'Unknown';
    }
  };

  return (
    <div className='bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-6 border border-gray-700 shadow-xl hover:shadow-2xl transition-all duration-300 flex flex-col h-full min-h-[600px]'>
      <div className='flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6 gap-4 sm:gap-0'>
        <div className='flex items-center space-x-3'>
          <div className='w-10 h-10 bg-gradient-to-br from-primary-500 to-primary-700 rounded-xl flex items-center justify-center flex-shrink-0'>
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
                d='M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z'
              />
            </svg>
          </div>
          <h3 className='text-xl font-bold text-white'>DCA Plan</h3>
        </div>
        <div className='flex flex-col sm:flex-row items-start sm:items-center space-y-3 sm:space-y-0 sm:space-x-3'>
          <div
            className={`px-3 sm:px-4 py-2 rounded-full text-xs sm:text-sm font-medium flex items-center space-x-2 ${
              dcaPlan.isActive
                ? 'bg-green-600/20 text-green-400 border border-green-600/30'
                : 'bg-yellow-600/20 text-yellow-400 border border-yellow-600/30'
            }`}
          >
            <div
              className={`w-2 h-2 rounded-full ${
                dcaPlan.isActive ? 'bg-green-400' : 'bg-yellow-400'
              }`}
            ></div>
            <span>{dcaPlan.isActive ? 'Active' : 'Paused'}</span>
          </div>
          <button
            onClick={() => setIsEditing(!isEditing)}
            className='px-3 sm:px-4 py-2 bg-gray-700 hover:bg-gray-600 text-gray-300 hover:text-white rounded-lg text-xs sm:text-sm font-medium transition-colors duration-200 w-full sm:w-auto'
          >
            {isEditing ? 'Cancel' : 'Edit'}
          </button>
        </div>
      </div>

      {isEditing ? (
        <div className='space-y-4 sm:space-y-6'>
          <div className='grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6'>
            <div>
              <label className='block text-xs sm:text-sm font-medium text-gray-300 mb-2 sm:mb-3'>
                Frequency
              </label>
              <select
                value={editFrequency}
                onChange={e => setEditFrequency(Number(e.target.value))}
                className='w-full bg-gray-700 text-white rounded-xl p-3 sm:p-4 border border-gray-600 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 transition-all duration-200 text-sm sm:text-base'
              >
                <option value={0}>Daily</option>
                <option value={1}>Weekly</option>
                <option value={2}>Monthly</option>
              </select>
            </div>

            <div>
              <label className='block text-xs sm:text-sm font-medium text-gray-300 mb-2 sm:mb-3'>
                Amount per period (USDC)
              </label>
              <input
                type='number'
                value={editAmount}
                onChange={e => setEditAmount(e.target.value)}
                className='w-full bg-gray-700 text-white rounded-xl p-3 sm:p-4 border border-gray-600 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 transition-all duration-200 text-sm sm:text-base'
                placeholder='Enter amount'
              />
            </div>
          </div>

          {/* Budget Protection */}
          <div className='space-y-2'>
            <label className='block text-xs sm:text-sm font-medium text-gray-300 mb-2 sm:mb-3'>
              Maximum ETH Price (USD)
            </label>
            <input
              type='number'
              value={editMaxBudget}
              onChange={e => setEditMaxBudget(e.target.value)}
              className='w-full bg-gray-700 text-white rounded-xl p-3 sm:p-4 border border-gray-600 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 transition-all duration-200 text-sm sm:text-base'
              placeholder='3000 (leave 0 for no limit)'
            />
            <p className='text-xs text-gray-400'>
              Maximum USD price per ETH you're willing to pay. Leave 0 for no
              limit.
            </p>
          </div>

          {/* Volatility Filter */}
          <div className='space-y-2'>
            <label className='block text-xs sm:text-sm font-medium text-gray-300 mb-2 sm:mb-3'>
              Volatility Protection
            </label>
            <div className='flex items-center space-x-3'>
              <input
                type='checkbox'
                id='volatilityFilterEdit'
                checked={editVolatilityFilter}
                onChange={e => setEditVolatilityFilter(e.target.checked)}
                className='w-4 h-4 text-primary-600 bg-gray-700 border-gray-600 rounded focus:ring-primary-500 focus:ring-2'
              />
              <label
                htmlFor='volatilityFilterEdit'
                className='text-gray-300 text-sm'
              >
                Skip execution during high volatility periods
              </label>
            </div>
            <p className='text-xs text-gray-400'>
              When enabled, DCA execution will be skipped if market volatility
              exceeds 5%.
            </p>
          </div>

          <div className='flex space-x-2 sm:space-x-3'>
            <button
              onClick={handleSavePlan}
              disabled={isLoading}
              className='flex-1 bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-700 hover:to-primary-800 disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed text-white py-3 sm:py-4 rounded-xl font-semibold transition-all duration-200 transform hover:scale-105 disabled:hover:scale-100 text-sm sm:text-base'
            >
              {isLoading ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </div>
      ) : (
        <div className='space-y-4 sm:space-y-6 flex-1 flex flex-col'>
          <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6'>
            <div className='bg-gray-700/50 rounded-xl p-3 sm:p-4 hover:bg-gray-700/70 transition-colors duration-200'>
              <div className='flex items-center space-x-2 sm:space-x-3 mb-2'>
                <div className='w-6 h-6 sm:w-8 sm:h-8 bg-blue-600 rounded-lg flex items-center justify-center flex-shrink-0'>
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
                      d='M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z'
                    />
                  </svg>
                </div>
                <span className='text-gray-300 font-medium text-sm sm:text-base'>
                  Frequency
                </span>
              </div>
              <span className='text-white font-bold text-base sm:text-lg'>
                {getFrequencyLabel(dcaPlan.frequency)}
              </span>
            </div>

            <div className='bg-gray-700/50 rounded-xl p-3 sm:p-4 hover:bg-gray-700/70 transition-colors duration-200'>
              <div className='flex items-center space-x-2 sm:space-x-3 mb-2'>
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
                      d='M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1'
                    />
                  </svg>
                </div>
                <span className='text-gray-300 font-medium text-sm sm:text-base'>
                  Amount
                </span>
              </div>
              <span className='text-white font-bold text-base sm:text-lg'>
                ${parseFloat(dcaPlan.amountPerPeriod).toFixed(2)} USDC
              </span>
            </div>

            <div className='bg-gray-700/50 rounded-xl p-3 sm:p-4 hover:bg-gray-700/70 transition-colors duration-200'>
              <div className='flex items-center space-x-2 sm:space-x-3 mb-2'>
                <div className='w-6 h-6 sm:w-8 sm:h-8 bg-orange-600 rounded-lg flex items-center justify-center flex-shrink-0'>
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
                      d='M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1'
                    />
                  </svg>
                </div>
                <span className='text-gray-300 font-medium text-sm sm:text-base'>
                  Max ETH Price
                </span>
              </div>
              <span className='text-white font-bold text-base sm:text-lg'>
                {parseFloat(dcaPlan.maxBudgetPerExecution) === 0
                  ? 'No Limit'
                  : `$${parseFloat(dcaPlan.maxBudgetPerExecution).toFixed(0)}`}
              </span>
            </div>

            <div className='bg-gray-700/50 rounded-xl p-3 sm:p-4 hover:bg-gray-700/70 transition-colors duration-200'>
              <div className='flex items-center space-x-2 sm:space-x-3 mb-2'>
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
                      d='M13 10V3L4 14h7v7l9-11h-7z'
                    />
                  </svg>
                </div>
                <span className='text-gray-300 font-medium text-sm sm:text-base'>
                  Volatility Filter
                </span>
              </div>
              <span className='text-white font-bold text-base sm:text-lg'>
                {dcaPlan.enableVolatilityFilter ? 'Enabled' : 'Disabled'}
              </span>
            </div>

            <div className='bg-gray-700/50 rounded-xl p-3 sm:p-4 hover:bg-gray-700/70 transition-colors duration-200 sm:col-span-2 lg:col-span-1'>
              <div className='flex items-center space-x-2 sm:space-x-3 mb-2'>
                <div className='w-6 h-6 sm:w-8 sm:h-8 bg-purple-600 rounded-lg flex items-center justify-center flex-shrink-0'>
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
                      d='M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z'
                    />
                  </svg>
                </div>
                <span className='text-gray-300 font-medium text-sm sm:text-base'>
                  Next Execution
                </span>
              </div>
              <span className='text-white font-bold text-xs sm:text-sm'>
                {formatDate(dcaPlan.nextExecutionTimestamp)}
              </span>
            </div>
          </div>

          <div className='mt-auto'>
            <button
              onClick={handlePauseResume}
              disabled={isLoading}
              className={`w-full py-3 sm:py-4 rounded-xl font-semibold transition-all duration-200 transform hover:scale-105 disabled:hover:scale-100 text-sm sm:text-base ${
                dcaPlan.isActive
                  ? 'bg-gradient-to-r from-yellow-600 to-yellow-700 hover:from-yellow-700 hover:to-yellow-800 text-white'
                  : 'bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 text-white'
              } disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed`}
            >
              {isLoading
                ? 'Processing...'
                : dcaPlan.isActive
                  ? 'Pause Plan'
                  : 'Resume Plan'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default DcaPlanCard;
