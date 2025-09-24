import React, { useState } from 'react';
import CreateDcaModal from './CreateDcaModal';
import DepositModal from './DepositModal';

const Hero: React.FC = () => {
  const [isCreateDcaOpen, setIsCreateDcaOpen] = useState(false);
  const [isDepositOpen, setIsDepositOpen] = useState(false);

  return (
    <>
      <div className='space-y-8'>
        <div className='space-y-6'>
          <h1 className='text-5xl lg:text-6xl font-bold text-white leading-tight'>
            Invest Automatically,
            <br />
            Stay in Control
          </h1>
          <p className='text-xl text-gray-300 max-w-md'>
            Automating DeFi: Simple, Smart, Transparent, Always On
          </p>
        </div>

        <div className='flex flex-col sm:flex-row gap-4'>
          <button
            onClick={() => setIsCreateDcaOpen(true)}
            className='bg-primary-600 hover:bg-primary-700 text-white px-8 py-4 rounded-lg font-semibold text-lg transition-colors'
          >
            Create DCA Plan
          </button>
          <button
            onClick={() => setIsDepositOpen(true)}
            className='border-2 border-gray-600 hover:border-gray-500 text-white px-8 py-4 rounded-lg font-semibold text-lg transition-colors'
          >
            Deposit USDC
          </button>
        </div>
      </div>

      <CreateDcaModal
        isOpen={isCreateDcaOpen}
        onClose={() => setIsCreateDcaOpen(false)}
      />
      <DepositModal
        isOpen={isDepositOpen}
        onClose={() => setIsDepositOpen(false)}
      />
    </>
  );
};

export default Hero;
