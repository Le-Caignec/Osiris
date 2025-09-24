import React, { useState } from 'react';
import { useWallet } from '../providers/WalletProvider';

interface DepositModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const DepositModal: React.FC<DepositModalProps> = ({ isOpen, onClose }) => {
  const { isConnected, depositUsdc, isLoading } = useWallet();
  const [depositAmount, setDepositAmount] = useState('');

  const handleDeposit = async () => {
    if (!isConnected || !depositAmount) return;

    try {
      await depositUsdc(depositAmount);
      setDepositAmount('');
      onClose();
    } catch (error) {
      console.error('Error depositing USDC:', error);
    }
  };

  if (!isOpen) return null;

  return (
    <div className='fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50'>
      <div className='bg-gray-800 rounded-xl p-8 max-w-md w-full mx-4'>
        <div className='flex justify-between items-center mb-6'>
          <h2 className='text-2xl font-bold text-white'>Deposit USDC</h2>
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
          <div className='space-y-2'>
            <label className='text-gray-300 text-sm font-medium'>
              Amount to deposit
            </label>
            <input
              type='number'
              value={depositAmount}
              onChange={e => setDepositAmount(e.target.value)}
              className='w-full bg-gray-700 text-white rounded-lg p-3 border border-gray-600 focus:border-primary-500 focus:outline-none'
              placeholder='Enter amount in USDC'
            />
          </div>

          <div className='flex space-x-3'>
            <button
              onClick={onClose}
              className='flex-1 bg-gray-600 hover:bg-gray-700 text-white py-3 rounded-lg font-semibold transition-colors'
            >
              Cancel
            </button>
            <button
              onClick={handleDeposit}
              disabled={!depositAmount || isLoading}
              className='flex-1 bg-green-600 hover:bg-green-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white py-3 rounded-lg font-semibold transition-colors'
            >
              {isLoading ? 'Processing...' : 'Deposit'}
            </button>
          </div>

          <p className='text-gray-400 text-sm text-center'>
            Your USDC will be deposited into the vault for DCA execution
          </p>
        </div>
      </div>
    </div>
  );
};

export default DepositModal;
