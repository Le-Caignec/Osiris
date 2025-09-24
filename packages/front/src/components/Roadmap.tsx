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

      {/* Call to Action */}
      <div className='text-center mt-16 space-y-6'>
        <h2 className='text-4xl font-bold text-white'>
          Ready to invest smarter?
        </h2>
        <div className='flex flex-col sm:flex-row gap-4 justify-center'>
          <button className='bg-primary-600 hover:bg-primary-700 text-white px-8 py-4 rounded-lg font-semibold text-lg transition-colors'>
            Start DCA
          </button>
          <button className='border-2 border-gray-600 hover:border-gray-500 text-white px-8 py-4 rounded-lg font-semibold text-lg transition-colors'>
            View Demo
          </button>
        </div>
      </div>
    </section>
  );
};

export default Roadmap;
