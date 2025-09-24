import React from 'react';
import Hero from './Hero';
import DcaPlanForm from './DcaPlanForm';
import Features from './Features';
import Roadmap from './Roadmap';

const Home: React.FC = () => {
  return (
    <div className='min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900'>
      <main className='container mx-auto px-4 py-8'>
        <div className='grid grid-cols-1 lg:grid-cols-2 gap-12 items-center min-h-[80vh]'>
          <Hero />
          <DcaPlanForm />
        </div>
        <Features />
        <Roadmap />
      </main>
    </div>
  );
};

export default Home;
