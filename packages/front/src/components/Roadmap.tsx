import React from 'react';

const Roadmap: React.FC = () => {
  const roadmapItems = [
    {
      title: 'DCA',
      description: 'free | gas-only, tiny execution fee',
    },
    {
      title: 'Pro & Yield',
      description:
        'subscription • fee, advanced automations, performance fee on realized yield',
    },
    {
      title: 'Liquidity Optimizer',
      description: 'perf fee • strategy marketplace',
    },
  ];

  return (
    <section className='py-16'>
      <h2 className='text-4xl font-bold text-white text-center mb-12'>
        Roadmap
      </h2>
      <div className='grid grid-cols-1 md:grid-cols-3 gap-8'>
        {roadmapItems.map((item, index) => (
          <div key={index} className='bg-gray-800 rounded-xl p-8 space-y-4'>
            <h3 className='text-xl font-bold text-white'>{item.title}</h3>
            <p className='text-gray-300'>{item.description}</p>
          </div>
        ))}
      </div>
    </section>
  );
};

export default Roadmap;
