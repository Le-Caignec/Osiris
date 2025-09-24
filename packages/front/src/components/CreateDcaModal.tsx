import React, { useState } from 'react';
import { useWallet } from '../providers/WalletProvider';
import { Frequency, FREQUENCY_LABELS } from '../config/contracts';

interface CreateDcaModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const CreateDcaModal: React.FC<CreateDcaModalProps> = ({ isOpen, onClose }) => {
  const { isConnected, setPlan, isLoading } = useWallet();
  const [amountPerBuy, setAmountPerBuy] = useState('50');
  const [frequency, setFrequency] = useState<Frequency>(Frequency.Weekly);

  const handleCreateDcaPlan = async () => {
    if (!isConnected) return;

    try {
      // Set the plan
      await setPlan(frequency, amountPerBuy);
      onClose();
    } catch (error) {
      console.error('Error creating DCA plan:', error);
    }
  };

  if (!isOpen) return null;

  return (
    <div className='fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50'>
      <div className='bg-gray-800 rounded-xl p-8 max-w-md w-full mx-4'>
        <div className='flex justify-between items-center mb-6'>
          <h2 className='text-2xl font-bold text-white'>Create DCA Plan</h2>
          <button
            onClick={onClose}
            className='text-gray-400 hover:text-white transition-colors'
          >
            <svg
              className='w-6 h-6'
              fill='none'
              stroke='currentColor'
              viewBox='0 0 24 24'
            >
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                strokeWidth={2}
                d='M6 18L18 6M6 6l12 12'
              />
            </svg>
          </button>
        </div>

        <div className='space-y-6'>
          {/* Token Selection - Fixed ETH */}
          <div className='space-y-2'>
            <label className='text-gray-300 text-sm font-medium'>Token Buy</label>
            <div className='flex items-center space-x-3 bg-gray-700 rounded-lg p-3'>
              <div className='w-8 h-8 bg-gray-600 rounded-full flex items-center justify-center'>
                <span className='text-white text-sm font-bold'>Ξ</span>
              </div>
              <span className='text-white font-medium'>ETH</span>
              <span className='text-gray-400 text-sm ml-auto'>Fixed</span>
            </div>
          </div>

          {/* Amount per buy */}
          <div className='space-y-2'>
            <label className='text-gray-300 text-sm font-medium'>
              Amount per-buy
            </label>
            <input
              type='number'
              value={amountPerBuy}
              onChange={e => setAmountPerBuy(e.target.value)}
              className='w-full bg-gray-700 text-white rounded-lg p-3 border border-gray-600 focus:border-primary-500 focus:outline-none'
              placeholder='$50'
            />
          </div>

          {/* Frequency */}
          <div className='space-y-2'>
            <label className='text-gray-300 text-sm font-medium'>
              Frequency
            </label>
            <div className='relative'>
              <select
                value={frequency}
                onChange={e =>
                  setFrequency(Number(e.target.value) as Frequency)
                }
                className='w-full bg-gray-700 text-white rounded-lg p-3 border border-gray-600 focus:border-primary-500 focus:outline-none appearance-none'
              >
                {Object.entries(FREQUENCY_LABELS).map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
              <svg
                className='w-4 h-4 text-gray-400 absolute right-3 top-1/2 transform -translate-y-1/2 pointer-events-none'
                fill='none'
                stroke='currentColor'
                viewBox='0 0 24 24'
              >
                <path
                  strokeLinecap='round'
                  strokeLinejoin='round'
                  strokeWidth={2}
                  d='M19 9l-7 7-7-7'
                />
              </svg>
            </div>
          </div>

          <div className='flex space-x-3'>
            <button
              onClick={onClose}
              className='flex-1 bg-gray-600 hover:bg-gray-700 text-white py-3 rounded-lg font-semibold transition-colors'
            >
              Cancel
            </button>
            <button
              onClick={handleCreateDcaPlan}
              disabled={!isConnected || isLoading}
              className='flex-1 bg-primary-600 hover:bg-primary-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white py-3 rounded-lg font-semibold transition-colors'
            >
              {isLoading ? 'Processing...' : 'Create Plan'}
            </button>
          </div>

          <p className='text-gray-400 text-sm text-center'>
            100% on-chain - fully decentralized
          </p>
        </div>
      </div>
    </div>
  );
};

export default CreateDcaModal;
