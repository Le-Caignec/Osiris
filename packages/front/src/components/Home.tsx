import React from 'react';
import Hero from './Hero';
import DcaPlanForm from './DcaPlanForm';
import Features from './Features';
import Roadmap from './Roadmap';
import reactiveLogo from '../assets/reactive-logo.png';

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
      <footer className='container mx-auto px-4 pb-8'>
        <div className='flex items-center justify-center gap-3 text-slate-400 text-base'>
          <span>Powered by</span>
          <a
            href='https://reactive.network'
            target='_blank'
            rel='noopener noreferrer'
            className='flex items-center gap-3 hover:text-slate-300 transition-colors'
          >
            <img
              src={reactiveLogo}
              alt='Reactive Network'
              className='h-7 w-200'
            />
          </a>
        </div>
      </footer>
    </div>
  );
};

export default Home;
