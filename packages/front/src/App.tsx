import React from 'react';
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from 'react-router-dom';
import { WagmiConfig, createConfig, configureChains } from 'wagmi';
import { mainnet, sepolia } from 'wagmi/chains';
import { publicProvider } from 'wagmi/providers/public';
import { jsonRpcProvider } from 'wagmi/providers/jsonRpc';
import { RainbowKitProvider, getDefaultWallets } from '@rainbow-me/rainbowkit';
import '@rainbow-me/rainbowkit/styles.css';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import Layout from './components/Layout';
import Home from './components/Home';
import Dashboard from './components/Dashboard';
import WalletProvider from './providers/WalletProvider';
import { CHAIN } from './config/contracts';

const { chains, publicClient, webSocketPublicClient } = configureChains(
  [mainnet, sepolia],
  [
    // Use custom RPC for Sepolia; fall back to public provider for others
    jsonRpcProvider({
      rpc: chain =>
        chain.id === sepolia.id
          ? {
              http: CHAIN.sepolia.rpc,
            }
          : null,
    }),
    publicProvider(),
  ]
);

const { connectors } = getDefaultWallets({
  appName: 'OSIRIS',
  projectId: process.env.REACT_APP_WALLET_CONNECT_PROJECT_ID!,
  chains,
});

const config = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
  webSocketPublicClient,
});

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error: any) => {
        // Don't retry ENS-related errors
        if (
          error?.message?.includes('reverse') ||
          error?.message?.includes('ENS')
        ) {
          return false;
        }
        return failureCount < 3;
      },
      staleTime: 1000 * 60 * 5, // 5 minutes
    },
  },
});

function App() {
  return (
    <WagmiConfig config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider
          chains={chains}
          initialChain={sepolia}
          showRecentTransactions={false}
        >
          <WalletProvider>
            <Router>
              <Layout>
                <Routes>
                  <Route path='/' element={<Home />} />
                  <Route path='/dashboard' element={<Dashboard />} />
                  <Route path='*' element={<Navigate to='/' replace />} />
                </Routes>
              </Layout>
            </Router>
          </WalletProvider>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiConfig>
  );
}

export default App;
