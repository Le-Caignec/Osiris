import React, { useState } from 'react';
import { useWallet } from '../providers/WalletProvider';
import { format } from 'date-fns';

const DcaPlanCard: React.FC = () => {
  const { isConnected, dcaPlan, setPlan, pausePlan, resumePlan, isLoading } =
    useWallet();
  const [isEditing, setIsEditing] = useState(false);
  const [editFrequency, setEditFrequency] = useState(dcaPlan?.frequency || 1);
  const [editAmount, setEditAmount] = useState(
    dcaPlan?.amountPerPeriod || '50'
  );

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
      <div className='bg-gray-800 rounded-xl p-6'>
        <h3 className='text-lg font-semibold text-white mb-4'>DCA Plan</h3>
        <p className='text-gray-400'>
          Connect your wallet to view your DCA plan
        </p>
      </div>
    );
  }

  if (!dcaPlan) {
    return (
      <div className='bg-gray-800 rounded-xl p-6'>
        <h3 className='text-lg font-semibold text-white mb-4'>DCA Plan</h3>
        <p className='text-gray-400'>No active DCA plan found</p>
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
    <div className='bg-gray-800 rounded-xl p-6 space-y-4'>
      <div className='flex items-center justify-between'>
        <h3 className='text-lg font-semibold text-white'>DCA Plan</h3>
        <div className='flex items-center space-x-2'>
          <span
            className={`px-2 py-1 rounded-full text-xs font-medium ${
              dcaPlan.isActive
                ? 'bg-green-600 text-white'
                : 'bg-gray-600 text-gray-300'
            }`}
          >
            {dcaPlan.isActive ? 'Active' : 'Paused'}
          </span>
          <button
            onClick={() => setIsEditing(!isEditing)}
            className='text-primary-500 hover:text-primary-400 text-sm'
          >
            {isEditing ? 'Cancel' : 'Edit'}
          </button>
        </div>
      </div>

      {isEditing ? (
        <div className='space-y-4'>
          <div>
            <label className='block text-sm text-gray-300 mb-2'>
              Frequency
            </label>
            <select
              value={editFrequency}
              onChange={e => setEditFrequency(Number(e.target.value))}
              className='w-full bg-gray-700 text-white rounded-lg p-3 border border-gray-600 focus:border-primary-500 focus:outline-none'
            >
              <option value={0}>Daily</option>
              <option value={1}>Weekly</option>
              <option value={2}>Monthly</option>
            </select>
          </div>

          <div>
            <label className='block text-sm text-gray-300 mb-2'>
              Amount per period (USDC)
            </label>
            <input
              type='number'
              value={editAmount}
              onChange={e => setEditAmount(e.target.value)}
              className='w-full bg-gray-700 text-white rounded-lg p-3 border border-gray-600 focus:border-primary-500 focus:outline-none'
            />
          </div>

          <div className='flex space-x-2'>
            <button
              onClick={handleSavePlan}
              disabled={isLoading}
              className='flex-1 bg-primary-600 hover:bg-primary-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white py-2 rounded-lg font-semibold transition-colors'
            >
              {isLoading ? 'Saving...' : 'Save'}
            </button>
          </div>
        </div>
      ) : (
        <div className='space-y-3'>
          <div className='flex justify-between items-center'>
            <span className='text-gray-300'>Frequency</span>
            <span className='text-white font-semibold'>
              {getFrequencyLabel(dcaPlan.frequency)}
            </span>
          </div>

          <div className='flex justify-between items-center'>
            <span className='text-gray-300'>Amount per period</span>
            <span className='text-white font-semibold'>
              ${parseFloat(dcaPlan.amountPerPeriod).toFixed(2)} USDC
            </span>
          </div>

          <div className='flex justify-between items-center'>
            <span className='text-gray-300'>Next execution</span>
            <span className='text-white font-semibold'>
              {formatDate(dcaPlan.nextExecutionTimestamp)}
            </span>
          </div>

          <button
            onClick={handlePauseResume}
            disabled={isLoading}
            className={`w-full py-2 rounded-lg font-semibold transition-colors ${
              dcaPlan.isActive
                ? 'bg-yellow-600 hover:bg-yellow-700 text-white'
                : 'bg-green-600 hover:bg-green-700 text-white'
            } disabled:bg-gray-600 disabled:cursor-not-allowed`}
          >
            {isLoading
              ? 'Processing...'
              : dcaPlan.isActive
                ? 'Pause Plan'
                : 'Resume Plan'}
          </button>
        </div>
      )}
    </div>
  );
};

export default DcaPlanCard;
