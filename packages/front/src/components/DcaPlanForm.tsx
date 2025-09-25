import React from 'react';
import { useNavigate } from 'react-router-dom';

const DcaPlanForm: React.FC = () => {
  const navigate = useNavigate();

  const handleStartDcaPlan = () => {
    navigate('/dashboard');
  };

  return (
    <div className='bg-gray-800 rounded-xl p-8 space-y-6'>
      <h2 className='text-2xl font-bold text-white mb-6'>Create DCA Plan</h2>

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
        <div className='w-full bg-gray-700 text-white rounded-lg p-3 border border-gray-600'>
          $50
        </div>
      </div>

      {/* Frequency */}
      <div className='space-y-2'>
        <label className='text-gray-300 text-sm font-medium'>Frequency</label>
        <div className='w-full bg-gray-700 text-white rounded-lg p-3 border border-gray-600'>
          Weekly
        </div>
      </div>

      {/* Start DCA Plan Button */}
      <button
        onClick={handleStartDcaPlan}
        className='w-full bg-primary-600 hover:bg-primary-700 text-white py-4 rounded-lg font-semibold text-lg transition-colors'
      >
        Create DCA Plan
      </button>

      <p className='text-gray-400 text-sm text-center'>
        100% on-chain logs, cancellable anytime
      </p>
    </div>
  );
};

export default DcaPlanForm;
