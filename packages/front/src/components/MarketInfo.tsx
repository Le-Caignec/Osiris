import React, { useState, useEffect, useCallback } from 'react';

const MarketInfo: React.FC = () => {
  const [ethPrice, setEthPrice] = useState<string>('0');
  const [volatility, setVolatility] = useState<string>('0');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastFetch, setLastFetch] = useState<number>(0);

  const CACHE_DURATION = 60000; // 1 minute cache
  const CACHE_KEY_PRICE = 'osiris_eth_price';
  const CACHE_KEY_VOLATILITY = 'osiris_volatility';
  const CACHE_KEY_TIMESTAMP = 'osiris_cache_timestamp';

  // Load cached data on mount
  useEffect(() => {
    const cachedPrice = localStorage.getItem(CACHE_KEY_PRICE);
    const cachedVolatility = localStorage.getItem(CACHE_KEY_VOLATILITY);
    const cachedTimestamp = localStorage.getItem(CACHE_KEY_TIMESTAMP);

    if (cachedPrice && cachedVolatility && cachedTimestamp) {
      const timestamp = parseInt(cachedTimestamp);
      const now = Date.now();

      // Use cache if less than 1 minute old
      if (now - timestamp < CACHE_DURATION) {
        setEthPrice(cachedPrice);
        setVolatility(cachedVolatility);
        setLastFetch(timestamp);
      }
    }
  }, []);

  const fetchMarketData = useCallback(async () => {
    // Check if we fetched recently (within 30 seconds)
    const now = Date.now();
    if (lastFetch && now - lastFetch < 30000) {
      console.log('Using cached data, too soon to refetch');
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      // Fetch current ETH price directly from CoinGecko (CORS enabled)
      const priceUrl =
        'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd';

      const priceResponse = await fetch(priceUrl);

      if (!priceResponse.ok) {
        if (priceResponse.status === 429) {
          throw new Error('Rate limit exceeded');
        }
        throw new Error(`HTTP error! status: ${priceResponse.status}`);
      }

      const priceData = await priceResponse.json();

      // Check data structure
      if (!priceData?.ethereum?.usd) {
        throw new Error('Invalid price data structure');
      }

      const currentPrice = priceData.ethereum.usd;
      const priceString = currentPrice.toString();
      setEthPrice(priceString);

      // Cache the price
      localStorage.setItem(CACHE_KEY_PRICE, priceString);
      localStorage.setItem(CACHE_KEY_TIMESTAMP, now.toString());

      // Fetch historical data for volatility calculation
      const historicalUrl =
        'https://api.coingecko.com/api/v3/coins/ethereum/market_chart?vs_currency=usd&days=7&interval=daily';

      const historicalResponse = await fetch(historicalUrl);

      if (historicalResponse.ok) {
        const historicalData = await historicalResponse.json();

        // Calculate volatility from historical prices
        if (historicalData?.prices && Array.isArray(historicalData.prices)) {
          const prices = historicalData.prices.map(
            (item: [number, number]) => item[1]
          );

          if (prices.length > 1) {
            const returns = [];
            for (let i = 1; i < prices.length; i++) {
              returns.push((prices[i] - prices[i - 1]) / prices[i - 1]);
            }

            const mean =
              returns.reduce((sum, ret) => sum + ret, 0) / returns.length;
            const variance =
              returns.reduce((sum, ret) => sum + Math.pow(ret - mean, 2), 0) /
              returns.length;
            const volatilityPercent = Math.sqrt(variance) * 100;
            const volatilityString = volatilityPercent.toFixed(2);

            setVolatility(volatilityString);
            localStorage.setItem(CACHE_KEY_VOLATILITY, volatilityString);
          }
        }
      }

      setLastFetch(now);
    } catch (err) {
      console.error('Error fetching market data:', err);
      const errorMessage =
        err instanceof Error ? err.message : 'Failed to fetch market data';

      // Show user-friendly error message
      if (errorMessage.includes('429') || errorMessage.includes('Rate limit')) {
        setError('API rate limit. Please wait a moment before refreshing.');
      } else {
        setError('Unable to fetch market data. Please try again later.');
      }

      // Keep the last successful values instead of resetting to '0'
    } finally {
      setIsLoading(false);
    }
  }, [lastFetch, CACHE_KEY_PRICE, CACHE_KEY_VOLATILITY, CACHE_KEY_TIMESTAMP, CACHE_DURATION]);

  useEffect(() => {
    fetchMarketData();

    // Update every 2 minutes to avoid rate limiting
    const interval = setInterval(fetchMarketData, 120000);
    return () => clearInterval(interval);
  }, [fetchMarketData]);

  // Afficher l'erreur si présente
  const renderContent = () => {
    if (error) {
      return (
        <div className='mt-3 p-3 bg-red-600/10 border border-red-600/20 rounded-lg'>
          <p className='text-red-300 text-xs'>
            ⚠️ Unable to fetch market data: {error}
          </p>
          <button
            onClick={fetchMarketData}
            className='mt-2 text-xs text-red-400 hover:text-red-300 underline'
          >
            Retry
          </button>
        </div>
      );
    }

    return (
      <>
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
      </>
    );
  };

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

      {renderContent()}
    </div>
  );
};

export default MarketInfo;
