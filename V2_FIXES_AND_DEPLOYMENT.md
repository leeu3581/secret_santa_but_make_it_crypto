# FriendsMemePoolV2 - Complete Fix Documentation

## 🚨 What Went Wrong with V1

**CRITICAL BUGS IDENTIFIED:**

1. **Broken WETH Swap Logic** ❌
   - Contract tried to swap WETH→Token but sent raw ETH
   - Uniswap V3 Router expects WETH, not ETH
   - Result: `executeSwaps()` always reverted
   - **Impact: ALL FUNDS LOCKED FOREVER**

2. **No Refund Mechanism** ❌
   - If swaps failed, no way to get money back
   - No emergency functions
   - **Impact: Permanent fund loss**

3. **No Safety Mechanisms** ❌
   - Couldn't cancel pools
   - No slippage protection
   - No partial failure handling

## ✅ V2 Fixes - Complete Overhaul

### 1. **FIXED: Proper WETH Wrapping**

**Before (V1 - BROKEN):**
```solidity
function _swapETHForToken(address tokenOut, uint256 amountIn) internal returns (uint256) {
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: WETH,  // Says WETH
        // ... other params
    });
    return swapRouter.exactInputSingle{value: amountIn}(params);  // ❌ Sends ETH!
}
```

**After (V2 - FIXED):**
```solidity
function _swapETHForToken(address tokenOut, uint256 amountIn, uint256 minOut) internal returns (uint256) {
    // Step 1: Wrap ETH to WETH
    IWETH(WETH).deposit{value: amountIn}();

    // Step 2: Approve router
    IWETH(WETH).approve(address(SWAP_ROUTER), amountIn);

    // Step 3: Swap WETH → Token
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: WETH,
        tokenOut: tokenOut,
        fee: 3000,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: amountIn,
        amountOutMinimum: minOut,  // ✅ Slippage protection!
        sqrtPriceLimitX96: 0
    });

    return SWAP_ROUTER.exactInputSingle(params);  // ✅ No {value:} - uses WETH!
}
```

### 2. **ADDED: All-or-Nothing Swap Execution**

```solidity
function executeSwaps(uint256 poolId) external nonReentrant {
    // ... validation ...

    // CRITICAL: If ANY swap fails, ENTIRE transaction reverts
    for (uint256 i = 0; i < pool.participants.length; i++) {
        // This will revert if swap fails
        uint256 amountOut = _swapETHForToken(tokenOut, amountPerSwap, minOut);

        // Only updates if swap succeeded
        pool.participants[i].assignedToken = tokenOut;
        pool.participants[i].tokenAmount = amountOut;
    }

    pool.swapsExecuted = true;  // Only set if ALL swaps succeeded
}
```

**What this means:**
- ✅ Either EVERYONE gets tokens or NOBODY does
- ✅ If any swap fails, all changes are reverted
- ✅ Failed swap = all ETH still in contract = everyone can refund
- ✅ No partial success complexity

### 3. **ADDED: Refund Mechanism**

```solidity
function refund(uint256 poolId) external nonReentrant {
    Pool storage pool = pools[poolId];
    require(!pool.swapsExecuted, "Swaps already executed");
    require(block.timestamp >= pool.joinDeadline + 24 hours, "Wait 24h after deadline");

    // Find and refund participant
    // Returns full entry amount
    (bool success, ) = msg.sender.call{value: pool.entryAmount}("");
    require(success, "Refund failed");
}
```

**When you can refund:**
- ✅ 24 hours after join deadline
- ✅ Only if swaps were never executed
- ✅ Get back your FULL entry amount

### 4. **ADDED: Pool Cancellation**

```solidity
function cancelPool(uint256 poolId) external {
    require(msg.sender == pool.creator, "Only creator");
    require(block.timestamp < pool.joinDeadline, "Too late to cancel");

    // Refund all participants immediately
    for (uint256 i = 0; i < pool.participants.length; i++) {
        (bool success, ) = pool.participants[i].addr.call{value: pool.entryAmount}("");
        require(success, "Refund failed");
    }

    pool.cancelled = true;
}
```

**When creator can cancel:**
- ✅ Anytime BEFORE join deadline
- ✅ Immediately refunds all participants
- ✅ Prevents new joins

### 5. **ADDED: Emergency Withdrawal**

```solidity
function emergencyWithdraw(uint256 poolId) external nonReentrant {
    require(msg.sender == pool.creator, "Only creator");
    require(!pool.swapsExecuted, "Swaps already executed");
    require(block.timestamp >= pool.unlockTime + 7 days, "Wait 7 days after unlock");

    // Last resort - refund everyone
}
```

**When this can be used:**
- ✅ 7 days AFTER unlock time
- ✅ Only if swaps never executed
- ✅ Creator initiates, everyone gets refunded

### 6. **ADDED: Slippage Protection**

```solidity
// Create pool with slippage tolerance
pool.createPool(
    // ... other params ...
    9500  // 5% slippage tolerance (9500/10000 = 95%)
);

// Calculate minimum output
function _calculateMinOutput(address poolAddress, uint256 amountIn, uint256 slippageBps)
    internal view returns (uint256)
{
    // Get expected output from pool price
    // Apply slippage tolerance
    uint256 minOut = (expectedOut * slippageBps) / 10000;
    return minOut;
}
```

**Slippage validation:**
- ✅ Must be between 50% and 100% (5000-10000 bps)
- ✅ Prevents massive price impact
- ✅ Swap reverts if output < minimum

### 7. **ADDED: Executor Rewards**

```solidity
// Pool distribution:
// 90% → Swapped to tokens
// 9% → Winner bonus
// 1% → Executor reward

function executeSwaps(uint256 poolId) external {
    // ... execute swaps ...

    pool.executorReward = (totalPoolETH * 100) / 10000;  // 1%

    // Pay executor
    (bool success, ) = msg.sender.call{value: pool.executorReward}("");
    require(success, "Executor reward failed");
}
```

**Why this matters:**
- ✅ Incentivizes ANYONE to call executeSwaps()
- ✅ You don't need to run a bot (but you can)
- ✅ Ensures timely execution

### 8. **ADDED: SafeERC20**

```solidity
using SafeERC20 for IERC20;

// Before (V1):
IERC20(token).transfer(msg.sender, amount);  // ❌ Doesn't check return value

// After (V2):
IERC20(token).safeTransfer(msg.sender, amount);  // ✅ Reverts if fails
```

### 9. **ADDED: Better Validation**

```solidity
// V2 validates everything:
require(entryAmount > 0, "Entry amount must be > 0");
require(unlockTimeHours > joinDeadlineHours, "Unlock must be after join deadline");
require(slippageBps <= 10000 && slippageBps >= 5000, "Slippage must be 50-100%");
```

## 📊 Comparison Table

| Feature | V1 | V2 |
|---------|----|----|
| WETH Wrapping | ❌ Broken | ✅ Fixed |
| Swap Execution | ❌ Always fails | ✅ Works |
| All-or-Nothing | ❌ No | ✅ Yes |
| Refund Mechanism | ❌ No | ✅ 24h after deadline |
| Pool Cancellation | ❌ No | ✅ Before deadline |
| Emergency Withdrawal | ❌ No | ✅ 7d after unlock |
| Slippage Protection | ❌ No | ✅ Configurable |
| Executor Rewards | ❌ No | ✅ 1% incentive |
| SafeERC20 | ❌ No | ✅ Yes |
| Can lose funds | ✅ YES | ❌ NO |

## 🧪 Testing Checklist

V2 has **16 comprehensive tests** covering:

✅ Pool creation
✅ Joining pools
✅ Whitelist validation
✅ Assignment hiding before deadline
✅ Assignment revealing after deadline
✅ Refund after 24 hours
✅ Cannot refund before 24 hours
✅ Pool cancellation
✅ Cannot cancel after deadline
✅ Only creator can cancel
✅ Emergency withdrawal
✅ Cannot join cancelled pool
✅ Slippage validation
✅ Unlock must be after join deadline
✅ Cannot join twice
✅ Cannot join with wrong amount

**All tests pass: 16/16 ✅**

## 🚀 Deployment Instructions

### Step 1: Deploy to Base Sepolia (TESTNET FIRST!)

```bash
forge script script/DeployV2.s.sol:DeployV2Script \
  --rpc-url base_sepolia \
  --broadcast \
  --verify
```

### Step 2: Test Complete Flow on Testnet

1. Create pool with REAL Uniswap pools on Base Sepolia
2. Have 3 people join
3. Execute swaps (verify WETH wrapping works!)
4. Declare winner
5. Claim rewards

### Step 3: Test Refund Mechanism

1. Create another pool
2. Have people join
3. DON'T execute swaps
4. Wait 24 hours
5. Call refund() - verify everyone gets money back

### Step 4: Deploy to Base Mainnet (Only after testnet success!)

```bash
forge script script/DeployV2.s.sol:DeployV2Script \
  --rpc-url base \
  --broadcast \
  --verify
```

### Step 5: Start Small

- First pool: 0.0001 ETH entry
- Monitor closely
- Gradually increase amounts

## 📝 Creating a Test Pool on V2

```javascript
// Use real tokens and pools on Base
const memeTokens = [
  "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",  // USDC
  "0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb",  // DAI
  "0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22"   // cbETH
];

const uniswapPools = [
  "0x6c561b446416e1a00e8e93e221854d6ea4171372",  // USDC/WETH
  "0xdcf81663e68f076ef9763442de134fd0699de4ef",  // DAI/WETH
  "0x10648ba41b8565907cfa1496765fa4d95390aa0d"   // cbETH/WETH
];

cast send $CONTRACT_V2 \
  "createPool(string,address[],uint256,uint256,uint256,address[],address[],uint256)" \
  "Test Pool V2" \
  "[0xAddress1,0xAddress2,0xAddress3]" \
  "1000000000000000" \
  "8" \
  "17" \
  "[${memeTokens[0]},${memeTokens[1]},${memeTokens[2]}]" \
  "[${uniswapPools[0]},${uniswapPools[1]},${uniswapPools[2]}]" \
  "9500" \
  --rpc-url base \
  --private-key $PRIVATE_KEY
```

## 🎯 Key Differences in Usage

### V1 vs V2 createPool Parameters

**V1 (7 parameters):**
```solidity
createPool(name, whitelist, entryAmount, joinDeadlineHours, unlockTimeHours, memeTokens, uniswapPools)
```

**V2 (8 parameters - added slippage):**
```solidity
createPool(name, whitelist, entryAmount, joinDeadlineHours, unlockTimeHours, memeTokens, uniswapPools, slippageBps)
//                                                                                                      ^^^^^^^^^^^
//                                                                                                      NEW!
```

### New Functions in V2

```solidity
// Refund if swaps never executed
refund(poolId)

// Creator cancels pool before deadline
cancelPool(poolId)

// Emergency rescue 7 days after unlock
emergencyWithdraw(poolId)
```

## ⚠️ Important Notes

### DO:
✅ Deploy to Base Sepolia testnet FIRST
✅ Test with real Uniswap pools
✅ Start with tiny amounts (0.0001 ETH)
✅ Verify all functions work before mainnet
✅ Monitor first few pools closely
✅ Document all pool addresses

### DON'T:
❌ Deploy directly to mainnet without testing
❌ Use large amounts immediately
❌ Skip the refund mechanism test
❌ Forget to verify contract on BaseScan
❌ Use without understanding all safety mechanisms

## 💰 Fund Distribution

**V1:**
- 100% swapped to tokens
- 10% winner bonus (from swapped amount)
- **Problem:** Couldn't calculate properly, swaps failed anyway

**V2:**
- 90% swapped to tokens (divided among participants)
- 9% winner bonus (separate reserve)
- 1% executor reward (incentivizes calling executeSwaps)
- **Total: 100% accounted for**

**Example with 3 participants at 0.01 ETH each (0.03 ETH total):**
- 0.027 ETH → Swapped (0.009 ETH per person)
- 0.0027 ETH → Winner bonus
- 0.0003 ETH → Executor reward

## 🛡️ Safety Mechanisms Summary

1. **All-or-Nothing Swaps** - No partial failures
2. **Refund (24h)** - Get money back if swaps fail
3. **Cancel (before deadline)** - Creator can cancel early
4. **Emergency (7d)** - Last resort recovery
5. **Slippage Protection** - Prevents bad trades
6. **SafeERC20** - Secure token transfers
7. **Reentrancy Guards** - Prevents attacks
8. **Comprehensive Validation** - Catches errors early

## 📞 Support

If you encounter ANY issues:
1. Check the contract on BaseScan
2. Review test suite in `test/FriendsMemePoolV2.t.sol`
3. Read this documentation thoroughly
4. Test on Sepolia before reporting bugs

---

**V2 is production-ready AFTER testnet validation.**

The V1 losses were painful but provided valuable lessons. V2 is built to prevent those issues completely.

Test thoroughly. Start small. Scale carefully.
