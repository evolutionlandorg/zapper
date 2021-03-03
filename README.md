# 单币生成LP
[简介](https://blog.alphafinance.io/onesideduniswap/)  
## Zapper.fi
场景: 用户持有USDT/ETH    
需求: 添加RING-WOOD流动性池  
```solidity
    /**
    @notice This function is used to invest in given Uniswap V2 pair through ETH/ERC20 Tokens
    @param _FromTokenContractAddress The ERC20 token used for investment (address(0x00) if ether)
    @param _pairAddress The Uniswap pair address
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Reverts if less tokens received than this
    @param _swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a Zap
    @return Amount of LP bought
     */
    function ZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool transferResidual
    ) external payable nonReentrant stopInEmergency returns (uint256)
```
实现方式:
1. 通过[Zapper API](https://api.zapper.fi/v1/zap-in/uniswap-v2/transaction ) 去调用 [0x API](https://0x.org/docs/api#get-swapv1quote), 组装`swapData`后返回到前端, `_swapTarget`设为`RING`, 这部分使用`0x`把USDT/ETH换成RING.
2. 用户通过MetaMask调用`web3.eth.sendTransaction`执行合约.
3. 合约执行:
    * 通过`0x swap`把USDT/ETH换成RING.
    * 把RING通过`uniswap swap`换一部分为WOOD.
    * 把RING和WOOD添加到流动性池.

注: `_minPoolTokens`计算方式借助[fair-lp-token-pricing](https://blog.alphafinance.io/fair-lp-token-pricing/)计算得出  
  
举例: 
1. 将输入资产按照USD计价, 通过`fair asset price()`(ChainLink, Uniswap's TWAP, CoinGecko)计算资产`inputUSD`,
2. 获取uniswap池中资产价值, `getReserves()` `totalSupply`, 则`pricePerPoolToken` = `reserveUSD` / `totalSupply`
3. `_minPoolTokens` = (`inputUSD` / `pricePerPoolToken`) * ( 1 - `slippage` ). 

ZapOut 过程类似省略. 
  
问题: 
1. Zapper 没有测试网 (可以将Zapper部署到Kovan, 直接通过0x的测试网Kovan测试).
2. 0x 目前不支持RING的交易 [tokens](https://api.0x.org/swap/v1/tokens).

## Uniswap
场景: 用户持有RING/WOOD   
需求: 添加RING-WOOD流动性池  
```solidity
    // computes the exact amount of tokens that should be swapped before adding liquidity for a given token
    // does the swap and then adds liquidity
    // minOtherToken should be set to the minimum intermediate amount of token1 that should be received to prevent
    // excessive slippage or front running
    // liquidity provider shares are minted to the 'to' address
    function swapExactTokensAndAddLiquidity(
        address tokenIn,
        address otherToken,
        uint amountIn,
        uint minOtherTokenIn,
        address to,
        uint deadline
    ) external returns (uint amountTokenIn, uint amountTokenOther, uint liquidity) 
```
合约执行:
* 把RING通过`uniswap swap`换一部分为WOOD.
* 把RING和WOOD添加到流动性池.
	
注: `minOtherTokenIn` 通过[getAmountOut](https://uniswap.org/docs/v2/smart-contracts/library/#getamountout) 和 [combinedSwap.calculateSwapInAmount](https://github.com/Uniswap/uniswap-v2-periphery/blob/e8919d87045c1c80000aa9f734d5ca9df8647270/contracts/examples/ExampleCombinedSwapAddRemoveLiquidity.sol#L46)获取.
	`minOtherTokenIn` = `getAmountOut` * ( 1 - `slippage` )

问题:
1. 需要用户持有加入流动性池中的某一种代币.

