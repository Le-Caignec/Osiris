import React from 'react';

const Hero: React.FC = () => {
  return (
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
        <button className='bg-primary-600 hover:bg-primary-700 text-white px-8 py-4 rounded-lg font-semibold text-lg transition-colors'>
          Start DCA
        </button>
        <button className='border-2 border-gray-600 hover:border-gray-500 text-white px-8 py-4 rounded-lg font-semibold text-lg transition-colors'>
          See Demo
        </button>
      </div>
    </div>
  );
};

export default Hero;
