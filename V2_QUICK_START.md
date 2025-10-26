# FriendsMemePoolV2 - Quick Start Guide

## 🚀 Deploy V2 (Base Sepolia Testnet)

```bash
forge script script/DeployV2.s.sol:DeployV2Script \
  --rpc-url base_sepolia \
  --broadcast \
  --verify
```

**Save the contract address!**

## 📝 Create Test Pool

```bash
# Set variables
CONTRACT_V2=0xYourDeployedV2Address
WALLET1=0xYourAddress1
WALLET2=0xYourAddress2
WALLET3=0xYourAddress3

# Base Sepolia test tokens (find real ones!)
USDC=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
DAI=0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb
CBETH=0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22

# Their Uniswap pools (find real ones!)
USDC_POOL=0x6c561b446416e1a00e8e93e221854d6ea4171372
DAI_POOL=0xdcf81663e68f076ef9763442de134fd0699de4ef
CBETH_POOL=0x10648ba41b8565907cfa1496765fa4d95390aa0d

# Create pool
cast send $CONTRACT_V2 \
  "createPool(string,address[],uint256,uint256,uint256,address[],address[],uint256)" \
  "Test Pool V2" \
  "[$WALLET1,$WALLET2,$WALLET3]" \
  "1000000000000000" \
  "8" \
  "17" \
  "[$USDC,$DAI,$CBETH]" \
  "[$USDC_POOL,$DAI_POOL,$CBETH_POOL]" \
  "9500" \
  --rpc-url base_sepolia \
  --private-key $PRIVATE_KEY
```

## 👥 Join Pool

```bash
# Each participant
cast send $CONTRACT_V2 \
  "joinPool(uint256)" \
  0 \
  --value 0.001ether \
  --rpc-url base_sepolia \
  --private-key $PARTICIPANT_KEY
```

## 🔄 Execute Swaps (After Deadline)

```bash
# Anyone can call (gets 1% reward!)
cast send $CONTRACT_V2 \
  "executeSwaps(uint256)" \
  0 \
  --rpc-url base_sepolia \
  --private-key $PRIVATE_KEY
```

## 🏆 Declare Winner (After Unlock)

```bash
cast send $CONTRACT_V2 \
  "recordPricesAndDeclareWinner(uint256)" \
  0 \
  --rpc-url base_sepolia \
  --private-key $PRIVATE_KEY
```

## 💰 Claim Rewards

```bash
cast send $CONTRACT_V2 \
  "claim(uint256)" \
  0 \
  --rpc-url base_sepolia \
  --private-key $YOUR_KEY
```

## 🆘 Safety Functions

### Refund (if swaps never executed)

```bash
# Wait 24h after join deadline
cast send $CONTRACT_V2 \
  "refund(uint256)" \
  0 \
  --rpc-url base_sepolia \
  --private-key $YOUR_KEY
```

### Cancel Pool (creator only, before deadline)

```bash
cast send $CONTRACT_V2 \
  "cancelPool(uint256)" \
  0 \
  --rpc-url base_sepolia \
  --private-key $CREATOR_KEY
```

### Emergency Withdrawal (creator only, 7d after unlock)

```bash
cast send $CONTRACT_V2 \
  "emergencyWithdraw(uint256)" \
  0 \
  --rpc-url base_sepolia \
  --private-key $CREATOR_KEY
```

## 🔍 Check Status

```bash
# Pool info
cast call $CONTRACT_V2 "getPoolInfo(uint256)" 0 --rpc-url base_sepolia

# My status
cast call $CONTRACT_V2 "getMyStatus(uint256)" 0 \
  --rpc-url base_sepolia \
  --from $YOUR_ADDRESS

# Leaderboard (after winner declared)
cast call $CONTRACT_V2 "getLeaderboard(uint256)" 0 --rpc-url base_sepolia

# Assignments (after join deadline)
cast call $CONTRACT_V2 "getAssignments(uint256)" 0 --rpc-url base_sepolia
```

## ⚠️ Critical Reminders

1. **TEST ON SEPOLIA FIRST** - Never deploy to mainnet without testing
2. **Verify swaps work** - Make sure executeSwaps() succeeds on testnet
3. **Test refund** - Create a pool and test refund mechanism
4. **Start small** - First mainnet pool should be 0.0001 ETH
5. **Monitor closely** - Watch the first few pools

## 📊 Parameters Explained

```solidity
createPool(
  "Pool Name",                    // Any name
  [address1, address2, address3], // Whitelisted participants
  1000000000000000,               // Entry: 0.001 ETH (in wei)
  8,                              // Join deadline: 5 min (hours × 100)
  17,                             // Unlock: 10 min (hours × 100)
  [token1, token2, token3],       // Meme tokens to buy
  [pool1, pool2, pool3],          // Uniswap V3 pools (WETH pairs)
  9500                            // Slippage: 5% (9500/10000 = 95%)
)
```

## 🎯 Fund Distribution

**Example: 3 people × 0.01 ETH = 0.03 ETH total**

- 0.027 ETH (90%) → Swapped to tokens (0.009 ETH each)
- 0.0027 ETH (9%) → Winner bonus
- 0.0003 ETH (1%) → Executor reward

## ✅ What's Fixed in V2

- ✅ WETH wrapping (swaps actually work!)
- ✅ All-or-nothing execution (no partial failures)
- ✅ Refund mechanism (get money back if swaps fail)
- ✅ Pool cancellation (cancel before deadline)
- ✅ Emergency withdrawal (last resort)
- ✅ Slippage protection (prevents bad trades)
- ✅ Executor rewards (incentivizes timely execution)
- ✅ SafeERC20 (secure token transfers)

## 🏃 Next Steps

1. Deploy to Base Sepolia
2. Create test pool with real Uniswap pools
3. Test complete flow (join → swap → declare → claim)
4. Test refund mechanism
5. Deploy to Base mainnet (only after successful testnet testing!)
6. Start with 0.0001 ETH pools
7. Scale up gradually

---

**Read the full documentation in V2_FIXES_AND_DEPLOYMENT.md**
