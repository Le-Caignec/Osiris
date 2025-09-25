import React, { useState } from 'react';
import { useWallet } from '../providers/WalletProvider';

interface DepositModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const DepositModal: React.FC<DepositModalProps> = ({ isOpen, onClose }) => {
  const { isConnected, depositUsdc } = useWallet();
  const [depositAmount, setDepositAmount] = useState('');
  const [transactionResult, setTransactionResult] = useState<{
    hash: string;
    status: string;
  } | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleDeposit = async () => {
    if (!isConnected || !depositAmount) return;

    setIsLoading(true);
    setTransactionResult(null);

    try {
      const result = await depositUsdc(depositAmount);
      setTransactionResult({ hash: result.hash, status: result.status });

      if (result.status === 'success') {
        setDepositAmount('');
        // Close modal after a short delay to show the transaction hash
        setTimeout(() => onClose(), 2000);
      }
    } catch (error) {
      console.error('Error depositing USDC:', error);
      setTransactionResult({ hash: '', status: 'error' });
    } finally {
      setIsLoading(false);
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

          {/* Transaction Status */}
          {transactionResult && transactionResult.hash && (
            <div className='space-y-2'>
              <div className='text-xs text-gray-400'>
                <span className='font-medium'>Transaction:</span>{' '}
                <a
                  href={`https://sepolia.etherscan.io/tx/${transactionResult.hash}`}
                  target='_blank'
                  rel='noopener noreferrer'
                  className='text-blue-400 hover:text-blue-300 underline'
                >
                  {transactionResult.hash.slice(0, 10)}...
                </a>
                <span
                  className={`ml-2 px-2 py-1 rounded text-xs ${
                    transactionResult.status === 'success'
                      ? 'bg-green-900 text-green-300'
                      : 'bg-red-900 text-red-300'
                  }`}
                >
                  {transactionResult.status}
                </span>
              </div>
            </div>
          )}

          <p className='text-gray-400 text-sm text-center'>
            Your USDC will be deposited into the vault for DCA execution
          </p>
        </div>
      </div>
    </div>
  );
};

export default DepositModal;
