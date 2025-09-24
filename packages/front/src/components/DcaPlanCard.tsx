import React, { useState } from 'react';
import { useWallet } from '../providers/WalletProvider';
import { format } from 'date-fns';

const DcaPlanCard: React.FC = () => {
  const { isConnected, dcaPlan, setPlan, pausePlan, resumePlan, isLoading } =
    useWallet();
  const [isEditing, setIsEditing] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [editFrequency, setEditFrequency] = useState(dcaPlan?.frequency || 1);
  const [editAmount, setEditAmount] = useState(
    dcaPlan?.amountPerPeriod || '50'
  );

  const handleCreatePlan = async () => {
    if (!isConnected) return;

    try {
      await setPlan(editFrequency, editAmount);
      setIsCreating(false);
    } catch (error) {
      console.error('Error creating plan:', error);
    }
  };

  const handleSavePlan = async () => {
    if (!isConnected) return;

    try {
      await setPlan(editFrequency, editAmount);
      setIsEditing(false);
    } catch (error) {
      console.error('Error updating plan:', error);
    }
  };

  const handlePauseResume = async () => {
    if (!isConnected || !dcaPlan) return;

    try {
      if (dcaPlan.isActive) {
        await pausePlan();
      } else {
        await resumePlan();
      }
    } catch (error) {
      console.error('Error pausing/resuming plan:', error);
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

        {isCreating ? (
          <div className='space-y-6 flex flex-col justify-center flex-1'>
            <div className='text-center mb-8'>
              <div className='w-16 h-16 bg-primary-600/20 rounded-full flex items-center justify-center mx-auto mb-4'>
                <svg
                  className='w-8 h-8 text-primary-400'
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
              <h4 className='text-2xl font-semibold text-white mb-3'>
                Create DCA Plan
              </h4>
              <p className='text-gray-400 text-lg'>
                Set up your automated investment strategy
              </p>
            </div>

            <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
              <div>
                <label className='block text-sm font-medium text-gray-300 mb-3'>
                  Frequency
                </label>
                <select
                  value={editFrequency}
                  onChange={e => setEditFrequency(Number(e.target.value))}
                  className='w-full bg-gray-700 text-white rounded-xl p-4 border border-gray-600 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 transition-all duration-200'
                >
                  <option value={0}>Daily</option>
                  <option value={1}>Weekly</option>
                  <option value={2}>Monthly</option>
                </select>
              </div>

              <div>
                <label className='block text-sm font-medium text-gray-300 mb-3'>
                  Amount per period (USDC)
                </label>
                <input
                  type='number'
                  value={editAmount}
                  onChange={e => setEditAmount(e.target.value)}
                  className='w-full bg-gray-700 text-white rounded-xl p-4 border border-gray-600 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 transition-all duration-200'
                  placeholder='Enter amount'
                />
              </div>
            </div>

            <div className='flex space-x-3'>
              <button
                onClick={() => setIsCreating(false)}
                className='flex-1 bg-gray-700 hover:bg-gray-600 text-gray-300 hover:text-white py-4 rounded-xl font-semibold transition-all duration-200'
              >
                Cancel
              </button>
              <button
                onClick={handleCreatePlan}
                disabled={isLoading || !editAmount}
                className='flex-1 bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-700 hover:to-primary-800 disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed text-white py-4 rounded-xl font-semibold transition-all duration-200 transform hover:scale-105 disabled:hover:scale-100'
              >
                {isLoading ? 'Creating...' : 'Create Plan'}
              </button>
            </div>
          </div>
        ) : (
          <div className='text-center py-12 flex flex-col justify-center items-center flex-1'>
            <div className='w-20 h-20 bg-gray-700 rounded-full flex items-center justify-center mx-auto mb-6'>
              <svg
                className='w-10 h-10 text-gray-400'
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
            <h4 className='text-2xl font-semibold text-white mb-3'>
              No active DCA plan found
            </h4>
            <p className='text-gray-400 text-lg mb-8 max-w-md'>
              Create a plan to start automated investing
            </p>
            <button
              onClick={() => setIsCreating(true)}
              className='bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-700 hover:to-primary-800 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-200 transform hover:scale-105'
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
    <div className='bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-8 border border-gray-700 shadow-xl hover:shadow-2xl transition-all duration-300 min-h-[600px] flex flex-col'>
      <div className='flex items-center justify-between mb-8'>
        <div className='flex items-center space-x-3'>
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
        <div className='flex items-center space-x-3'>
          <div
            className={`px-4 py-2 rounded-full text-sm font-medium flex items-center space-x-2 ${
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
            className='px-4 py-2 bg-gray-700 hover:bg-gray-600 text-gray-300 hover:text-white rounded-lg text-sm font-medium transition-colors duration-200'
          >
            {isEditing ? 'Cancel' : 'Edit'}
          </button>
        </div>
      </div>

      {isEditing ? (
        <div className='space-y-6'>
          <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
            <div>
              <label className='block text-sm font-medium text-gray-300 mb-3'>
                Frequency
              </label>
              <select
                value={editFrequency}
                onChange={e => setEditFrequency(Number(e.target.value))}
                className='w-full bg-gray-700 text-white rounded-xl p-4 border border-gray-600 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 transition-all duration-200'
              >
                <option value={0}>Daily</option>
                <option value={1}>Weekly</option>
                <option value={2}>Monthly</option>
              </select>
            </div>

            <div>
              <label className='block text-sm font-medium text-gray-300 mb-3'>
                Amount per period (USDC)
              </label>
              <input
                type='number'
                value={editAmount}
                onChange={e => setEditAmount(e.target.value)}
                className='w-full bg-gray-700 text-white rounded-xl p-4 border border-gray-600 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 transition-all duration-200'
                placeholder='Enter amount'
              />
            </div>
          </div>

          <div className='flex space-x-3'>
            <button
              onClick={handleSavePlan}
              disabled={isLoading}
              className='flex-1 bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-700 hover:to-primary-800 disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed text-white py-4 rounded-xl font-semibold transition-all duration-200 transform hover:scale-105 disabled:hover:scale-100'
            >
              {isLoading ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </div>
      ) : (
        <div className='space-y-6 flex-1 flex flex-col'>
          <div className='grid grid-cols-1 md:grid-cols-3 gap-6'>
            <div className='bg-gray-700/50 rounded-xl p-4 hover:bg-gray-700/70 transition-colors duration-200'>
              <div className='flex items-center space-x-3 mb-2'>
                <div className='w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center'>
                  <svg
                    className='w-4 h-4 text-white'
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
                <span className='text-gray-300 font-medium'>Frequency</span>
              </div>
              <span className='text-white font-bold text-lg'>
                {getFrequencyLabel(dcaPlan.frequency)}
              </span>
            </div>

            <div className='bg-gray-700/50 rounded-xl p-4 hover:bg-gray-700/70 transition-colors duration-200'>
              <div className='flex items-center space-x-3 mb-2'>
                <div className='w-8 h-8 bg-green-600 rounded-lg flex items-center justify-center'>
                  <svg
                    className='w-4 h-4 text-white'
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
                <span className='text-gray-300 font-medium'>Amount</span>
              </div>
              <span className='text-white font-bold text-lg'>
                ${parseFloat(dcaPlan.amountPerPeriod).toFixed(2)} USDC
              </span>
            </div>

            <div className='bg-gray-700/50 rounded-xl p-4 hover:bg-gray-700/70 transition-colors duration-200'>
              <div className='flex items-center space-x-3 mb-2'>
                <div className='w-8 h-8 bg-purple-600 rounded-lg flex items-center justify-center'>
                  <svg
                    className='w-4 h-4 text-white'
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
                <span className='text-gray-300 font-medium'>
                  Next Execution
                </span>
              </div>
              <span className='text-white font-bold text-sm'>
                {formatDate(dcaPlan.nextExecutionTimestamp)}
              </span>
            </div>
          </div>

          <div className='mt-auto'>
            <button
              onClick={handlePauseResume}
              disabled={isLoading}
              className={`w-full py-4 rounded-xl font-semibold transition-all duration-200 transform hover:scale-105 disabled:hover:scale-100 ${
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
