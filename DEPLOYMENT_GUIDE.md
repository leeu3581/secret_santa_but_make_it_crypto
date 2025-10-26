# Quick Deployment Guide

## Step 1: Setup Environment

```bash
# Copy the example env file
cp .env.example .env

# Edit .env and add:
# - Your private key (from wallet like MetaMask) - MUST start with 0x
# - Your Etherscan API key (get from etherscan.io - works for Base via Etherscan API V2)
nano .env
```

**IMPORTANT:** Your private key in `.env` MUST include the `0x` prefix:
```
PRIVATE_KEY=0x1234567890abcdef...  ✅ Correct
PRIVATE_KEY=1234567890abcdef...    ❌ Wrong - will fail
```

## Step 2: Get Test ETH (if using testnet)

For Base Sepolia testnet:
1. Get Sepolia ETH from a faucet: https://sepoliafaucet.com/
2. Bridge to Base Sepolia: https://bridge.base.org/

## Step 3: Deploy Contract

### On Base Sepolia (Testnet - Recommended First)

```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url base_sepolia \
  --broadcast \
  --verify
```

### On Base Mainnet (Production)

```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url base \
  --broadcast \
  --verify
```

Save the deployed contract address!

## Step 4: Find Meme Token Addresses

You'll need:
- Meme token contract addresses (PEPE, DOGE, SHIB, etc.)
- Their Uniswap V3 pool addresses (paired with WETH)

### Finding Tokens on Base

1. Go to [BaseScan](https://basescan.org)
2. Search for popular tokens
3. Common meme tokens on Base:
   - Search for "PEPE", "DOGE", "SHIB", etc.
   - Copy their contract addresses

### Finding Uniswap V3 Pools

Method 1 - Uniswap Interface:
1. Go to [Uniswap](https://app.uniswap.org)
2. Connect to Base network
3. Search for token pair (e.g., "PEPE/WETH")
4. Click on pool info and copy the pool address

Method 2 - Using Cast:
```bash
# Uniswap V3 Factory on Base
FACTORY=0x33128a8fC17869897dcE68Ed026d694621f6FDfD
WETH=0x4200000000000000000000000000000000000006

cast call $FACTORY "getPool(address,address,uint24)" \
  $TOKEN_ADDRESS \
  $WETH \
  3000 \
  --rpc-url base
```

## Step 5: Create a Pool

```bash
# Set variables
CONTRACT=0xYourDeployedContractAddress
ALICE=0x... # Friend 1 address
BOB=0x...   # Friend 2 address
CHARLIE=0x... # Friend 3 address

PEPE=0x... # Token addresses
DOGE=0x...
SHIB=0x...

PEPE_POOL=0x... # Uniswap pool addresses
DOGE_POOL=0x...
SHIB_POOL=0x...

# Create pool
cast send $CONTRACT \
  "createPool(string,address[],uint256,uint256,uint256,address[],address[])" \
  "Christmas 2025" \
  "[$ALICE,$BOB,$CHARLIE]" \
  "10000000000000000" \
  "168" \
  "336" \
  "[$PEPE,$DOGE,$SHIB]" \
  "[$PEPE_POOL,$DOGE_POOL,$SHIB_POOL]" \
  --rpc-url base \
  --private-key $PRIVATE_KEY
```

Parameters explained:
- Pool name: "Christmas 2025"
- Whitelist: Array of friend addresses
- Entry amount: 10000000000000000 wei (0.01 ETH)
- Join deadline: 168 (7 days in hours * 100 for decimals)
- Unlock time: 336 (14 days in hours * 100)
- Meme tokens: Array of token addresses
- Uniswap pools: Array of corresponding pool addresses

## Step 6: Share with Friends

Send them:
1. Contract address
2. Pool ID (starts at 0 for first pool)
3. Entry amount in ETH
4. Deadline date/time

## Step 7: Friends Join

Each friend runs:

```bash
cast send $CONTRACT "joinPool(uint256)" 0 \
  --value 0.01ether \
  --rpc-url base \
  --private-key $THEIR_PRIVATE_KEY
```

## Step 8: Execute Swaps (After Join Deadline)

Anyone can call this after the join deadline:

```bash
cast send $CONTRACT "executeSwaps(uint256)" 0 \
  --rpc-url base \
  --private-key $PRIVATE_KEY
```

Now everyone can see their assignments!

## Step 9: Wait for Unlock Time

Check prices, watch the competition!

```bash
# View assignments
cast call $CONTRACT "getAssignments(uint256)" 0 --rpc-url base

# Check your status
cast call $CONTRACT "getMyStatus(uint256)" 0 \
  --rpc-url base \
  --from $YOUR_ADDRESS
```

## Step 10: Declare Winner (After Unlock Time)

```bash
cast send $CONTRACT "recordPricesAndDeclareWinner(uint256)" 0 \
  --rpc-url base \
  --private-key $PRIVATE_KEY
```

## Step 11: View Leaderboard

```bash
cast call $CONTRACT "getLeaderboard(uint256)" 0 --rpc-url base
```

## Step 12: Claim Rewards

Each participant claims:

```bash
cast send $CONTRACT "claim(uint256)" 0 \
  --rpc-url base \
  --private-key $YOUR_PRIVATE_KEY
```

Winner gets their tokens + 10% ETH bonus!

## Troubleshooting

### "failed parsing $PRIVATE_KEY as type `uint256`: missing hex prefix"
- Your private key in `.env` is missing the `0x` prefix
- Fix: Add `0x` at the start of your private key
- Example: `PRIVATE_KEY=0x1234567890abcdef...`

### "Insufficient funds"
- Make sure you have enough ETH in your wallet
- Check the entry amount matches exactly

### "Not whitelisted"
- Verify your address is in the whitelist array
- Check for typos in addresses

### "Assignments still hidden"
- Wait until join deadline has passed
- Check current time vs deadline with `getPoolInfo()`

### "Swaps not executed"
- Make sure join deadline has passed
- Call `executeSwaps()` first

### Need Help?
- Check the main [README.md](README.md)
- Review tests in [test/FriendsMemePool.t.sol](test/FriendsMemePool.t.sol)
- Look at contract source in [src/FriendsMemePool.sol](src/FriendsMemePool.sol)
