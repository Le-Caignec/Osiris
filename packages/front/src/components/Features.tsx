import React from 'react';

const Features: React.FC = () => {
  const features = [
    {
      icon: (
        <svg
          className='w-8 h-8 text-primary-500'
          fill='currentColor'
          viewBox='0 0 24 24'
        >
          <path d='M13 2L3 14h9l-1 8 10-12h-9l1-8z' />
        </svg>
      ),
      title: 'No-code DCA',
      description: 'Create a plan in 50s, on-chain execution, transparent logs',
    },
    {
      icon: (
        <svg
          className='w-8 h-8 text-primary-500'
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
      ),
      title: 'Volatility fitters',
      description: 'Only buy when conditions are just right for you',
    },
    {
      icon: (
        <svg
          className='w-8 h-8 text-primary-500'
          fill='none'
          stroke='currentColor'
          viewBox='0 0 24 24'
        >
          <path
            strokeLinecap='round'
            strokeLinejoin='round'
            strokeWidth={2}
            d='M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'
          />
        </svg>
      ),
      title: 'Transparent logs',
      description: '100% on-chain, traceable, auditable at any time',
    },
  ];

  return (
    <section className='py-16'>
      <div className='grid grid-cols-1 md:grid-cols-3 gap-8'>
        {features.map((feature, index) => (
          <div key={index} className='bg-gray-800 rounded-xl p-8 space-y-4'>
            <div className='flex items-center justify-center w-16 h-16 bg-gray-700 rounded-lg'>
              {feature.icon}
            </div>
            <h3 className='text-xl font-bold text-white'>{feature.title}</h3>
            <p className='text-gray-300'>{feature.description}</p>
          </div>
        ))}
      </div>
    </section>
  );
};

export default Features;
