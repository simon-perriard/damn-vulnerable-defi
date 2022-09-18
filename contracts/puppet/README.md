# Challenge #8 - Puppet

There's a huge lending pool borrowing Damn Valuable Tokens (DVTs), where you first need to deposit twice the borrow amount in ETH as collateral. The pool currently has 100000 DVTs in liquidity.

There's a DVT market opened in an [Uniswap v1 exchange](https://docs.uniswap.org/protocol/V1/introduction), currently with 10 ETH and 10 DVT in liquidity.

Starting with 25 ETH and 1000 DVTs in balance, you must steal all tokens from the lending pool. 

## Solution:

Here the price in the lending pool relies on the state of the Uniswap pool, that can be manipulated. Uniswap V1 pools uses the Constant Product Market Maker ``E*T=K``, ``E`` is the ``ETH`` balance of the pool and ``T`` is the ERC20 token (``DVT``) balance in the pool. The protocol takes ``0.3%`` liquidity provider fee on the token amount.

From there, the formula to exchange ``y`` tokens for ``ETH`` is:
```
    (E-x)*(T+y*997/1000)=E*T

    E-x = E*T / (T+y*997/1000)

    E - E*T / (T+y*997/1000) = x

    (E*(T+y*997/1000) - E*T) / (T+y*997/1000) = x
    (E*T + E*y*997/1000 - E*T) / (T+y*997/1000) = x

    E*y*997 / (T*1000+y*997) = x
```
This tells us that if we give ``y`` tokens, we get ``x ETH``.

The price of 1 token in ETH is computed as ``E/T``, so if we unbalance the pool such that ``E`` decreases and ``T`` increases we can lower the price computed in the lending pool.

Since the pool is not very liquid (``E=10, T=10``), we can heavily unbalance it by exchanging all of our tokens. The new pool state is then:
```
E ~= 0.0993
T ~= 1007
```
This leads to a price switch from ``1`` to ``0.0000986``. We can now borrow all the ``DVT`` from the lending pool for a price that is close to nothing. Before, lending ``1 DVT`` would have cost ``2 ETH`` (``20000 ETH`` for the whole pool), now it costs ``0.0001972 ETH`` for 1 token (``1.972 ETH`` for the whole pool).
