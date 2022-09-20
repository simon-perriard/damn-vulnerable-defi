# Challenge #9 - Puppet v2

The developers of the last lending pool are saying that they've learned the lesson. And just released a new version!

Now they're using a [Uniswap v2 exchange](https://docs.uniswap.org/protocol/V2/introduction) as a price oracle, along with the recommended utility libraries. That should be enough.

You start with 20 ETH and 10000 DVT tokens in balance. The new lending pool has a million DVT tokens in balance. You know what to do ;) 

## Solution:

The idea here is the same as in Puppet V1. The difference here is that we are using Uniswap V2. The lending pool is not using the correct price feed, it uses the ``quote`` function that is used to compute the exchange rate of assets during a swap, but this value can still be manipulated. The lending pool should rely on the ``currentCumulativePrices`` oracle library function to get the time weighted average price, that is harder to manipulate.

Please refer to Puppet V1 solution to see how the attack works.