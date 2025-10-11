import React, { useState, useEffect, useCallback } from 'react';

const MarketInfo: React.FC = () => {
  const [ethPrice, setEthPrice] = useState<string>('0');
  const [volatility, setVolatility] = useState<string>('0');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchMarketData = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      // Use a single reliable CORS proxy
      const corsProxy = 'https://api.allorigins.win/raw?url=';

      // Fetch current ETH price
      const priceUrl = `${corsProxy}${encodeURIComponent(
        'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd'
      )}`;

      const priceResponse = await fetch(priceUrl);

      if (!priceResponse.ok) {
        throw new Error(`HTTP error! status: ${priceResponse.status}`);
      }

      const priceData = await priceResponse.json();
      console.log('Price data received:', priceData);

      // Handle allorigins.win response structure
      let actualPriceData = priceData;
      if (priceData.status && priceData.status.contents) {
        try {
          actualPriceData = JSON.parse(priceData.status.contents);
          console.log('Parsed price data from allorigins:', actualPriceData);
        } catch (parseError) {
          throw new Error('Failed to parse proxy response');
        }
      }

      // Check data structure
      if (!actualPriceData?.ethereum?.usd) {
        throw new Error('Invalid price data structure');
      }

      const currentPrice = actualPriceData.ethereum.usd;
      setEthPrice(currentPrice.toString());

      // Fetch historical data for volatility calculation
      const historicalUrl = `${corsProxy}${encodeURIComponent(
        'https://api.coingecko.com/api/v3/coins/ethereum/market_chart?vs_currency=usd&days=7&interval=daily'
      )}`;

      const historicalResponse = await fetch(historicalUrl);

      if (!historicalResponse.ok) {
        console.warn('Historical data unavailable, using price data only');
        return; // Don't throw error for historical data
      }

      const historicalData = await historicalResponse.json();
      console.log('Historical data received:', historicalData);

      // Handle allorigins.win response structure for historical data
      let actualHistoricalData = historicalData;
      if (historicalData.status && historicalData.status.contents) {
        try {
          actualHistoricalData = JSON.parse(historicalData.status.contents);
          console.log(
            'Parsed historical data from allorigins:',
            actualHistoricalData
          );
        } catch (parseError) {
          console.warn('Failed to parse historical proxy response');
          return; // Skip volatility calculation if parsing fails
        }
      }

      // Calculate volatility from historical prices
      if (
        actualHistoricalData?.prices &&
        Array.isArray(actualHistoricalData.prices)
      ) {
        const prices = actualHistoricalData.prices.map(
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

          setVolatility(volatilityPercent.toFixed(2));
        }
      }
    } catch (err) {
      console.error('Error fetching market data:', err);
      const errorMessage =
        err instanceof Error ? err.message : 'Failed to fetch market data';

      // Show user-friendly error message
      if (errorMessage.includes('429')) {
        setError('API rate limit reached. Please try again in a few minutes.');
      } else {
        setError('Unable to fetch market data. Please try again later.');
      }

      // Keep the last successful values instead of resetting to '0'
    } finally {
      setIsLoading(false);
    }
  }, []); // No dependencies to prevent infinite loops

  useEffect(() => {
    fetchMarketData();

    // Update every 5 minutes to avoid rate limiting and prevent constant loading
    const interval = setInterval(fetchMarketData, 300000);
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
