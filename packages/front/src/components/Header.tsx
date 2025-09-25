import React from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useWallet } from '../providers/WalletProvider';
import { Link, useLocation } from 'react-router-dom';

const Header: React.FC = () => {
  const { isConnected } = useWallet();
  const location = useLocation();
  return (
    <header className='flex flex-col sm:flex-row justify-between items-start sm:items-center py-4 sm:py-6 px-4 sm:px-6 lg:px-8 gap-4 sm:gap-0'>
      <Link to='/' className='flex items-center space-x-2 hover:opacity-80 transition-opacity'>
        <div className='w-6 h-6 sm:w-8 sm:h-8 bg-primary-600 rounded-full flex items-center justify-center flex-shrink-0'>
          <div className='w-3 h-3 sm:w-4 sm:h-4 bg-white rounded-sm'></div>
        </div>
        <h1 className='text-xl sm:text-2xl font-bold text-white'>OSIRIS</h1>
      </Link>

      <div className='flex flex-col sm:flex-row items-start sm:items-center space-y-3 sm:space-y-0 sm:space-x-4 w-full sm:w-auto'>
        {isConnected && (
          <div className='flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-4 w-full sm:w-auto'>
            <Link
              to='/'
              className={`px-3 py-2 sm:px-4 sm:py-2 rounded-lg transition-colors text-center sm:text-left ${
                location.pathname === '/'
                  ? 'bg-primary-600 text-white'
                  : 'text-gray-300 hover:text-white hover:bg-gray-700'
              }`}
            >
              Home
            </Link>
            <Link
              to='/dashboard'
              className={`px-3 py-2 sm:px-4 sm:py-2 rounded-lg transition-colors text-center sm:text-left ${
                location.pathname === '/dashboard'
                  ? 'bg-primary-600 text-white'
                  : 'text-gray-300 hover:text-white hover:bg-gray-700'
              }`}
            >
              Dashboard
            </Link>
          </div>
        )}
        <div className='w-full sm:w-auto'>
          <ConnectButton />
        </div>
      </div>
    </header>
  );
};

export default Header;
