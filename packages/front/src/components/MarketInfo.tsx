import React, { useState, useEffect } from 'react';
import { useWallet } from '../providers/WalletProvider';

const MarketInfo: React.FC = () => {
  const { isConnected } = useWallet();
  const [ethPrice, setEthPrice] = useState<string>('0');
  const [volatility, setVolatility] = useState<string>('0');
  const [isLoading, setIsLoading] = useState(false);

  const fetchMarketData = async () => {
    setIsLoading(true);
    try {
      // Fetch current ETH price from CoinGecko
      const priceResponse = await fetch(
        'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd'
      );
      const priceData = await priceResponse.json();
      const currentPrice = priceData.ethereum.usd;
      setEthPrice(currentPrice.toString());

      // Fetch historical data for volatility calculation (last 7 days)
      const historicalResponse = await fetch(
        'https://api.coingecko.com/api/v3/coins/ethereum/market_chart?vs_currency=usd&days=7&interval=daily'
      );
      const historicalData = await historicalResponse.json();

      // Calculate volatility from historical prices
      const prices = historicalData.prices.map(
        (item: [number, number]) => item[1]
      );
      if (prices.length > 1) {
        const returns = [];
        for (let i = 1; i < prices.length; i++) {
          returns.push((prices[i] - prices[i - 1]) / prices[i - 1]);
        }

        // Calculate standard deviation of returns
        const mean =
          returns.reduce((sum, ret) => sum + ret, 0) / returns.length;
        const variance =
          returns.reduce((sum, ret) => sum + Math.pow(ret - mean, 2), 0) /
          returns.length;
        const volatilityPercent = Math.sqrt(variance) * 100;

        setVolatility(volatilityPercent.toFixed(2));
      }
    } catch (error) {
      console.error('Error fetching market data:', error);
      // Set fallback values
      setEthPrice('0');
      setVolatility('0');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchMarketData();

    // Update every 30 seconds
    const interval = setInterval(fetchMarketData, 30000);
    return () => clearInterval(interval);
  }, []);

  if (!isConnected) {
    return (
      <div className='bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-4 border border-gray-700 shadow-xl'>
        <div className='flex items-center space-x-3 mb-4'>
          <div className='w-8 h-8 bg-gradient-to-br from-blue-500 to-blue-700 rounded-xl flex items-center justify-center'>
            <svg
              className='w-4 h-4 text-white'
              fill='none'
              stroke='currentColor'
              viewBox='0 0 24 24'
            >
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                strokeWidth={2}
                d='M13 7h8m0 0v8m0-8l-8 8-4-4-6 6'
              />
            </svg>
          </div>
          <h3 className='text-lg font-bold text-white'>Market Information</h3>
        </div>

        <div className='space-y-3'>
          <div className='bg-gray-700/50 rounded-xl p-3 hover:bg-gray-700/70 transition-colors duration-200'>
            <div className='flex items-center space-x-3 mb-2'>
              <div className='w-6 h-6 bg-green-600 rounded-lg flex items-center justify-center'>
                <span className='text-white text-xs font-bold'>Ξ</span>
              </div>
              <span className='text-gray-300 font-medium text-sm'>
                ETH Price
              </span>
            </div>
            <div className='flex items-center space-x-2'>
              {isLoading ? (
                <div className='animate-pulse bg-gray-600 h-5 w-20 rounded'></div>
              ) : (
                <span className='text-white font-bold text-base'>
                  ${parseFloat(ethPrice).toFixed(2)}
                </span>
              )}
            </div>
          </div>

          <div className='bg-gray-700/50 rounded-xl p-3 hover:bg-gray-700/70 transition-colors duration-200'>
            <div className='flex items-center space-x-3 mb-2'>
              <div className='w-6 h-6 bg-red-600 rounded-lg flex items-center justify-center'>
                <svg
                  className='w-3 h-3 text-white'
                  fill='none'
                  stroke='currentColor'
                  viewBox='0 0 24 24'
                >
                  <path
                    strokeLinecap='round'
                    strokeLinejoin='round'
                    strokeWidth={2}
                    d='M13 10V3L4 14h7v7l9-11h-7z'
                  />
                </svg>
              </div>
              <span className='text-gray-300 font-medium text-sm'>
                Volatility
              </span>
            </div>
            <div className='flex items-center space-x-2'>
              {isLoading ? (
                <div className='animate-pulse bg-gray-600 h-5 w-16 rounded'></div>
              ) : (
                <span className='text-white font-bold text-base'>
                  {volatility}%
                </span>
              )}
            </div>
          </div>
        </div>

        <div className='mt-3 p-2 bg-blue-600/10 border border-blue-600/20 rounded-lg'>
          <div className='space-y-1'>
            <p className='text-blue-300 text-xs'>
              💰 <strong>Budget Protection:</strong> Set a maximum ETH price to
              protect against buying during price spikes.
            </p>
            <p className='text-blue-300 text-xs'>
              ⚡ <strong>Volatility Filter:</strong> Enable volatility filtering
              to skip executions during high market volatility.
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className='bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-4 border border-gray-700 shadow-xl'>
      <div className='flex items-center space-x-3 mb-4'>
        <div className='w-8 h-8 bg-gradient-to-br from-blue-500 to-blue-700 rounded-xl flex items-center justify-center'>
          <svg
            className='w-4 h-4 text-white'
            fill='none'
            stroke='currentColor'
            viewBox='0 0 24 24'
          >
            <path
              strokeLinecap='round'
              strokeLinejoin='round'
              strokeWidth={2}
              d='M13 7h8m0 0v8m0-8l-8 8-4-4-6 6'
            />
          </svg>
        </div>
        <h3 className='text-lg font-bold text-white'>Market Information</h3>
      </div>

      <div className='space-y-3'>
        <div className='bg-gray-700/50 rounded-xl p-3 hover:bg-gray-700/70 transition-colors duration-200'>
          <div className='flex items-center space-x-3 mb-2'>
            <div className='w-6 h-6 bg-green-600 rounded-lg flex items-center justify-center'>
              <span className='text-white text-xs font-bold'>Ξ</span>
            </div>
            <span className='text-gray-300 font-medium text-sm'>ETH Price</span>
          </div>
          <div className='flex items-center space-x-2'>
            {isLoading ? (
              <div className='animate-pulse bg-gray-600 h-5 w-20 rounded'></div>
            ) : (
              <span className='text-white font-bold text-base'>
                ${parseFloat(ethPrice).toFixed(2)}
              </span>
            )}
          </div>
        </div>

        <div className='bg-gray-700/50 rounded-xl p-3 hover:bg-gray-700/70 transition-colors duration-200'>
          <div className='flex items-center space-x-3 mb-2'>
            <div className='w-6 h-6 bg-red-600 rounded-lg flex items-center justify-center'>
              <svg
                className='w-3 h-3 text-white'
                fill='none'
                stroke='currentColor'
                viewBox='0 0 24 24'
              >
                <path
                  strokeLinecap='round'
                  strokeLinejoin='round'
                  strokeWidth={2}
                  d='M13 10V3L4 14h7v7l9-11h-7z'
                />
              </svg>
            </div>
            <span className='text-gray-300 font-medium text-sm'>Volatility</span>
          </div>
          <div className='flex items-center space-x-2'>
            {isLoading ? (
              <div className='animate-pulse bg-gray-600 h-5 w-16 rounded'></div>
            ) : (
              <span className='text-white font-bold text-base'>
                {volatility}%
              </span>
            )}
          </div>
        </div>
      </div>

      <div className='mt-3 p-2 bg-blue-600/10 border border-blue-600/20 rounded-lg'>
        <div className='space-y-1'>
          <p className='text-blue-300 text-xs'>
            💰 <strong>Budget Protection:</strong> Set a maximum ETH price to protect against buying during price spikes.
          </p>
          <p className='text-blue-300 text-xs'>
            ⚡ <strong>Volatility Filter:</strong> Enable volatility filtering to skip executions during high market volatility.
          </p>
        </div>
      </div>
    </div>
  );
};

export default MarketInfo;
