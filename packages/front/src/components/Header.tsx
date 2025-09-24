import React from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useWallet } from '../providers/WalletProvider';

interface HeaderProps {
  currentView: 'home' | 'dashboard';
  onViewChange: (view: 'home' | 'dashboard') => void;
}

const Header: React.FC<HeaderProps> = ({ currentView, onViewChange }) => {
  const { isConnected } = useWallet();
  return (
    <header className='flex justify-between items-center py-6 px-4'>
      <div className='flex items-center space-x-2'>
        <div className='w-8 h-8 bg-primary-600 rounded-full flex items-center justify-center'>
          <div className='w-4 h-4 bg-white rounded-sm'></div>
        </div>
        <h1 className='text-2xl font-bold text-white'>OSIRIS</h1>
      </div>

      <nav className='hidden md:flex space-x-8'>
        <a
          href='#product'
          className='text-gray-300 hover:text-white transition-colors'
        >
          Product
        </a>
        <a
          href='#security'
          className='text-gray-300 hover:text-white transition-colors'
        >
          Security
        </a>
        <a
          href='#roadmap'
          className='text-gray-300 hover:text-white transition-colors'
        >
          Roadmap
        </a>
        <a
          href='#team'
          className='text-gray-300 hover:text-white transition-colors'
        >
          Team
        </a>
        <a
          href='#docs'
          className='text-gray-300 hover:text-white transition-colors'
        >
          Docs
        </a>
      </nav>

      <div className='flex items-center space-x-4'>
        {isConnected && (
          <div className='flex space-x-4'>
            <button
              onClick={() => onViewChange('home')}
              className={`px-4 py-2 rounded-lg transition-colors ${
                currentView === 'home'
                  ? 'bg-primary-600 text-white'
                  : 'text-gray-300 hover:text-white'
              }`}
            >
              Home
            </button>
            <button
              onClick={() => onViewChange('dashboard')}
              className={`px-4 py-2 rounded-lg transition-colors ${
                currentView === 'dashboard'
                  ? 'bg-primary-600 text-white'
                  : 'text-gray-300 hover:text-white'
              }`}
            >
              Dashboard
            </button>
          </div>
        )}
        <ConnectButton />
      </div>
    </header>
  );
};

export default Header;
