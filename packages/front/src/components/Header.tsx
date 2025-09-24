import React from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useWallet } from '../providers/WalletProvider';
import { Link, useLocation } from 'react-router-dom';

const Header: React.FC = () => {
  const { isConnected } = useWallet();
  const location = useLocation();
  return (
    <header className='flex justify-between items-center py-6 px-4'>
      <div className='flex items-center space-x-2'>
        <div className='w-8 h-8 bg-primary-600 rounded-full flex items-center justify-center'>
          <div className='w-4 h-4 bg-white rounded-sm'></div>
        </div>
        <h1 className='text-2xl font-bold text-white'>OSIRIS</h1>
      </div>

      <div className='flex items-center space-x-4'>
        {isConnected && (
          <div className='flex space-x-4'>
            <Link
              to='/'
              className={`px-4 py-2 rounded-lg transition-colors ${
                location.pathname === '/'
                  ? 'bg-primary-600 text-white'
                  : 'text-gray-300 hover:text-white'
              }`}
            >
              Home
            </Link>
            <Link
              to='/dashboard'
              className={`px-4 py-2 rounded-lg transition-colors ${
                location.pathname === '/dashboard'
                  ? 'bg-primary-600 text-white'
                  : 'text-gray-300 hover:text-white'
              }`}
            >
              Dashboard
            </Link>
          </div>
        )}
        <ConnectButton />
      </div>
    </header>
  );
};

export default Header;
