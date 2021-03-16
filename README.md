# Zapper

## `UniswapV2_ZapIn_General_V4.sol`
This contract adds liquidity to Uniswap pools using ETH or any ERC20 Token.

### API
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
    ) external payable nonReentrant stopInEmergency returns (uint256) {
```
If liquidity pool is RING-GOLD.  
**Note**: Using ERC20 token, should approve `ZapIn` first.

#### Using token in the pool. etc: GOLD
`GOLD.approve(address(ZapIn), _amount)`
* `_FromTokenContractAddress` is `GOLD` token address.  
* `_pairAddress` is `RING-GOLD` uniswap pool pair address.
* `_amount` is `GOLD` token amount which user's input.
* `_swapTarget` is `0x0000000000000000000000000000000000000000`.
* `swapData` is `0x0`.
* `affiliate` is `0x0000000000000000000000000000000000000000`.
* `transferResidual` is `false`.
* `_minPoolTokens` is calculated by steps:
	1. `lp = zapInContract.methods.ZapIn(_FromTokenContractAddress, _pairAddress, _amount, 0, _swapTarget, swapData, affiliate, transferResidual).call()`
	2. `slippage` is `settings` which user's input.
	3. `_minPoolTokens = lp * ( 1 - slippage )`

#### Using token not in the pool. etc: ETH
* `_FromTokenContractAddress` is `0x0000000000000000000000000000000000000000`.  
* `_pairAddress` is `RING-GOLD` uniswap pool pair address.
* `_amount` is `eth` amount which user's input.
* `affiliate` is `0x0000000000000000000000000000000000000000`.
* `transferResidual` is `false`.
* `_swapTarget` is [Uniswap Router V2](https://uniswap.org/docs/v2/smart-contracts/router02/).
* `swapData` is calculated by follow steps:
  	1. swap `ETH` to `RING`.
  	2. [bestTradeExactIn](https://github.com/Uniswap/uniswap-v2-sdk/blob/91d9b42b9896c977265b840dbde069c963b56630/src/entities/trade.ts#L257) find best `route`.
	3. [swapCallParameters](https://github.com/Uniswap/uniswap-v2-sdk/blob/91d9b42b9896c977265b840dbde069c963b56630/src/router.ts#L75) produce `methodName` and `params`.
	4. `swapData = router02.methods.methodName(params).encodeABI()`
* `_minPoolTokens` is calculated by follow steps:
	1. `lp = zapInContract.methods.ZapIn(_FromTokenContractAddress, _pairAddress, _amount, 0, _swapTarget, swapData, affiliate, transferResidual).call()`
	2. `slippage` is `settings` which user's input.
	3. `_minPoolTokens = lp * ( 1 - slippage )`

## `UniswapV2_ZapOut_General_V3_0_1.sol`
This contract implements one click removal of liquidity from Uniswap pools, receiving ETH, ERC tokens or both.

### API
```solidity
    /**
    @notice Zap out in a single token
    @param ToTokenContractAddress Address of desired token
    @param FromUniPoolAddress Pool from which to remove liquidity
    @param IncomingLP Quantity of LP to remove from pool
    @param minTokensRec Minimum quantity of tokens to receive
    @param swapTargets Execution targets for swaps
    @param swap1Data DEX swap data
    @param swap2Data DEX swap data
    @param affiliate Affiliate address
    */
    function ZapOut(
        address ToTokenContractAddress,
        address FromUniPoolAddress,
        uint256 IncomingLP,
        uint256 minTokensRec,
        address[] memory swapTargets,
        bytes memory swap1Data,
        bytes memory swap2Data,
        address affiliate
    ) public nonReentrant stopInEmergency returns (uint256 tokensRec) {

```

If liquidity pool is RING-GOLD.  
**Note**: This function should approve `ZapOunt` first.  
`lp.approve(address(ZapOut), IncomingLP)`  
`swapTargets[0]` and `swapTargets[1]` corresponding to `pair.token0` and `pair.token1`  

so `token0` is `RING`, `token1` is `GOLD`
#### Receive token in the pool. etc: GOLD
* `ToTokenContractAddress` is `GOLD` token address.  
* `FromUniPoolAddress` is `RING-GOLD` uniswap pool pair address.
* `IncomingLP` is `RING-GOLD lp` token amount which user's input.
* `affiliate` is `0x0000000000000000000000000000000000000000`.
* `transferResidual` is `false`.
* `swapTargets` is [[Uniswap Router V2](https://uniswap.org/docs/v2/smart-contracts/router02/),0x0000000000000000000000000000000000000000].
* `swap1Data` is calculated by follow steps:
  	1. swap `RING` to `GOLD`
  	2. [getLiquidityValue](https://github.com/Uniswap/uniswap-v2-sdk/blob/91d9b42b9896c977265b840dbde069c963b56630/src/entities/pair.ts#L177) Calculates the exact amount of `token0` and `token1` that `IncomingLP` amount of liquidity tokens represent as `amount1` and `amount2`.
	3. [minimumAmountOut](https://github.com/Uniswap/uniswap-v2-sdk/blob/91d9b42b9896c977265b840dbde069c963b56630/src/entities/trade.ts#L212) Calculates `amountOutMin`.
	4. `swap1Data = router02.methods.swapTokensForExactTokens(amount1, amountOutMin).encodeABI()`.
* `swap2Data` is `0x0`.

#### Receive token in the pool. etc: ETH
* `ToTokenContractAddress` is `0x0000000000000000000000000000000000000000`.  
* `FromUniPoolAddress` is `RING-GOLD` uniswap pool pair address.
* `IncomingLP` is `RING-GOLD lp` token amount which user's input.
* `affiliate` is `0x0000000000000000000000000000000000000000`.
* `transferResidual` is `false`.
* `swapTargets` is [[Uniswap Router V2](https://uniswap.org/docs/v2/smart-contracts/router02/),[Uniswap Router V2](https://uniswap.org/docs/v2/smart-contracts/router02/)].
* `swap1Data` is calculated by follow steps:
  	1. swap `RING` to `ETH`
	2. `swap1Data = router02.methods.swapTokensForExactETH(amount1, amountOutMin).encodeABI()`.
* `swap2Data` is calculated by follow steps:
  	1. swap `GOLD` to `ETH`
	2. `swap2Data = router02.methods.swapTokensForExactETH(amount2, amountOutMin).encodeABI()`.

```solidity
    /**
    @notice Zap out in both tokens with permit
    @param FromUniPoolAddress Pool from which to remove liquidity
    @param IncomingLP Quantity of LP to remove from pool
    @param affiliate Affiliate address to share fees
    @param permitData Encoded permit data, which contains owner, spender, value, deadline, r,s,v values 
    @return  amountA, amountB - Quantity of tokens received 
    */
    function ZapOut2PairTokenWithPermit(
        address FromUniPoolAddress,
        uint256 IncomingLP,
        address affiliate,
        bytes calldata permitData
    ) external stopInEmergency returns (uint256 amountA, uint256 amountB) {
```
**Note**: `permitData` is `lp.methods.approve(address(ZapOut, IncomingLP))` 

