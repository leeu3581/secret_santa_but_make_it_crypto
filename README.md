# Friends Meme Pool V2 - Secret Santa Crypto Edition

A fun Secret Santa-style game where friends pool ETH and are randomly assigned meme coins. The winner gets a 9% bonus!

## ⚠️ Important: V1 Had Critical Bugs - Use V2 Only!

**V1 had a fatal WETH wrapping bug that locked all funds permanently.** V2 is the fixed, production-ready version.

See [V2_FIXES_AND_DEPLOYMENT.md](V2_FIXES_AND_DEPLOYMENT.md) for full details.

## V2 Features

- **Fixed WETH Swaps**: Properly wraps ETH to WETH before Uniswap swaps ✅
- **All-or-Nothing Execution**: Any swap failure = full revert, no partial states ✅
- **Refund Mechanism**: Get money back if swaps fail (24h after deadline) ✅
- **Pool Cancellation**: Creator can cancel before deadline ✅
- **Emergency Withdrawal**: Last resort recovery (7 days after unlock) ✅
- **Slippage Protection**: Configurable tolerance (5-50%) ✅
- **Executor Rewards**: 1% incentive for calling executeSwaps() ✅
- **Winner Bonus**: Top performer gets 9% of total pool as ETH bonus ✅
- **Leaderboard**: Track everyone's performance in real-time ✅
- **Price Tracking**: Records entry and unlock prices via Uniswap V3 oracles ✅
- **Base Network**: Deployed on Base for low fees and fast transactions ✅

## How It Works

### Phase 1: Join (Hidden Phase)
1. Creator sets up pool with whitelisted friends, entry amount, and deadlines
2. Friends join by sending ETH
3. Assignments are HIDDEN - nobody knows what they'll get yet!

### Phase 2: Reveal & Execution
1. Join deadline passes
2. Contract executes swaps to buy random meme coins for each participant
3. Entry prices are recorded
4. Assignments revealed - everyone sees what they got!

### Phase 3: The Wait
1. Watch your meme coin's price action
2. Hope you got the winner!
3. Wait for unlock time

### Phase 4: Winner Declaration
1. Anyone can trigger price recording & winner declaration
2. Final prices fetched from Uniswap V3
3. Leaderboard calculated by % gain/loss
4. Winner identified and bonus allocated

### Phase 5: Claim Rewards
1. Winner claims tokens + 10% ETH bonus
2. Others claim their tokens

## Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- An Ethereum wallet with some Base ETH

### Installation

```bash
# Install dependencies
forge install

# Copy environment file
cp .env.example .env

# Edit .env with your private key and API keys
```

### Environment Variables

Edit `.env` with:

```
PRIVATE_KEY=0xYourPrivateKeyHere
BASE_RPC_URL=https://mainnet.base.org
ETHERSCAN_API_KEY=your_etherscan_api_key_here
```

**Notes:**
- Private key MUST include `0x` prefix (e.g., `0x1234abcd...`)
- Get your Etherscan API key from [Etherscan](https://etherscan.io/myapikey)
- The same Etherscan key works for Base network via Etherscan API V2

## Deployment

### Deploy to Base Mainnet

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url base --broadcast --verify
```

### Deploy to Base Sepolia (Testnet)

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url base_sepolia --broadcast
```

## Testing

Run the test suite:

```bash
forge test
```

Run with verbose output:

```bash
forge test -vvv
```

## Usage Example

### 1. Create a Pool

```solidity
address[] memory whitelist = [alice, bob, charlie, dave];
address[] memory memeTokens = [PEPE, DOGE, SHIB, BONK];
address[] memory uniswapPools = [PEPE_POOL, DOGE_POOL, SHIB_POOL, BONK_POOL];

pool.createPool(
    "Christmas 2025",
    whitelist,
    0.01 ether,        // Entry amount
    168,               // 7 days join deadline (in hours * 100)
    336,               // 14 days unlock (in hours * 100)
    memeTokens,
    uniswapPools
);
```

### 2. Friends Join

```bash
cast send $CONTRACT "joinPool(uint256)" 0 \
  --value 0.01ether \
  --rpc-url base \
  --private-key $ALICE_KEY
```

### 3. Execute Swaps (After Join Deadline)

```bash
cast send $CONTRACT "executeSwaps(uint256)" 0 \
  --rpc-url base \
  --private-key $YOUR_KEY
```

### 4. View Assignments (After Deadline)

```bash
cast call $CONTRACT "getAssignments(uint256)" 0 --rpc-url base
```

### 5. Record Prices & Declare Winner (After Unlock Time)

```bash
cast send $CONTRACT "recordPricesAndDeclareWinner(uint256)" 0 \
  --rpc-url base \
  --private-key $YOUR_KEY
```

### 6. View Leaderboard

```bash
cast call $CONTRACT "getLeaderboard(uint256)" 0 --rpc-url base
```

### 7. Claim Rewards

```bash
# Winner gets tokens + ETH bonus
cast send $CONTRACT "claim(uint256)" 0 \
  --rpc-url base \
  --private-key $WINNER_KEY
```

## Finding Uniswap V3 Pool Addresses on Base

### Method 1: Uniswap Interface
1. Go to [Uniswap](https://app.uniswap.org)
2. Switch to Base network
3. Search for token pair (e.g., "PEPE/WETH")
4. Click on the pool and copy the address

### Method 2: BaseScan
1. Go to [BaseScan](https://basescan.org)
2. Search for your token
3. Check "DEX Trades" tab
4. Find Uniswap V3 pool address

## Important Addresses (Base Mainnet)

- Uniswap V3 Router: `0x2626664c2603336E57B271c5C0b26F421741e481`
- WETH: `0x4200000000000000000000000000000000000006`

## License

MIT
