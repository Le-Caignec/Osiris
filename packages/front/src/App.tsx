import React, { useState } from 'react';
import { WagmiConfig, createConfig, configureChains } from 'wagmi';
import { mainnet, sepolia } from 'wagmi/chains';
import { publicProvider } from 'wagmi/providers/public';
import { RainbowKitProvider, getDefaultWallets } from '@rainbow-me/rainbowkit';
import '@rainbow-me/rainbowkit/styles.css';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import Header from './components/Header';
import Hero from './components/Hero';
import DcaPlanForm from './components/DcaPlanForm';
import Features from './components/Features';
import Roadmap from './components/Roadmap';
import Dashboard from './components/Dashboard';
import WalletProvider from './providers/WalletProvider';
import { WALLETCONNECT_PROJECT_ID } from './config/contracts';

const { chains, publicClient, webSocketPublicClient } = configureChains(
  [mainnet, sepolia],
  [publicProvider()]
);

const { connectors } = getDefaultWallets({
  appName: 'OSIRIS',
  projectId: WALLETCONNECT_PROJECT_ID,
  chains,
});

const config = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
  webSocketPublicClient,
});

const queryClient = new QueryClient();

function App() {
  const [currentView, setCurrentView] = useState<'home' | 'dashboard'>('home');

  return (
    <WagmiConfig config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider chains={chains}>
          <WalletProvider>
            {currentView === 'home' ? (
              <div className='min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900'>
                <Header
                  currentView={currentView}
                  onViewChange={setCurrentView}
                />
                <main className='container mx-auto px-4 py-8'>
                  <div className='grid grid-cols-1 lg:grid-cols-2 gap-12 items-center min-h-[80vh]'>
                    <Hero />
                    <DcaPlanForm />
                  </div>
                  <Features />
                  <Roadmap />
                </main>
              </div>
            ) : (
              <div className='min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900'>
                <Header
                  currentView={currentView}
                  onViewChange={setCurrentView}
                />
                <Dashboard />
              </div>
            )}
          </WalletProvider>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiConfig>
  );
}

export default App;
