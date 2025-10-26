# FriendsMemePoolV2 - Deployment Checklist

## ✅ Pre-Deployment

- [ ] Review all V2 fixes in `V2_FIXES_AND_DEPLOYMENT.md`
- [ ] Understand all safety mechanisms
- [ ] Have Base Sepolia ETH for testing
- [ ] Have `.env` file configured with `PRIVATE_KEY` (with 0x prefix)
- [ ] Have `ETHERSCAN_API_KEY` configured

## ✅ Testnet Deployment (Base Sepolia)

- [ ] Deploy V2 contract to Base Sepolia
```bash
forge script script/DeployV2.s.sol:DeployV2Script \
  --rpc-url base_sepolia \
  --broadcast \
  --verify
```
- [ ] Save contract address
- [ ] Verify contract on BaseScan Sepolia
- [ ] Find 3 real Uniswap V3 pools on Base Sepolia
- [ ] Create test pool
- [ ] Have 3 wallets join
- [ ] Wait for join deadline
- [ ] Execute swaps (VERIFY THIS SUCCEEDS!)
- [ ] Wait for unlock time
- [ ] Declare winner
- [ ] Have all participants claim
- [ ] Verify everyone got their tokens
- [ ] Verify winner got bonus

## ✅ Testnet Refund Test

- [ ] Create another test pool
- [ ] Have 2-3 people join
- [ ] DON'T execute swaps
- [ ] Wait 24 hours after join deadline
- [ ] Call refund() for each participant
- [ ] Verify everyone got their ETH back

## ✅ Testnet Cancellation Test

- [ ] Create another test pool
- [ ] Have 1-2 people join
- [ ] Call cancelPool() before deadline
- [ ] Verify everyone got immediate refund
- [ ] Verify pool is marked as cancelled
- [ ] Verify new joins are blocked

## ✅ Code Review

- [ ] Review FriendsMemePoolV2.sol line by line
- [ ] Verify WETH wrapping logic is correct
- [ ] Verify all require statements
- [ ] Check for reentrancy vulnerabilities
- [ ] Verify SafeERC20 is used
- [ ] Confirm all-or-nothing swap logic

## ✅ Mainnet Preparation

- [ ] All testnet tests passed
- [ ] No issues found in testing
- [ ] Have Base mainnet ETH for deployment
- [ ] Have Base mainnet ETH for test pool
- [ ] Find 3 real Uniswap V3 pools on Base Mainnet
- [ ] Prepare 3 test wallets with small amounts

## ✅ Mainnet Deployment

- [ ] Deploy V2 to Base Mainnet
```bash
forge script script/DeployV2.s.sol:DeployV2Script \
  --rpc-url base \
  --broadcast \
  --verify
```
- [ ] Save mainnet contract address
- [ ] Verify on BaseScan
- [ ] Share contract address with team

## ✅ First Mainnet Pool (BE CAREFUL!)

- [ ] Create pool with 0.0001 ETH entry (VERY SMALL!)
- [ ] Use 9500 slippage (5%)
- [ ] Use 5 min join deadline (for quick testing)
- [ ] Use 10 min unlock time
- [ ] Have 3 people join
- [ ] Execute swaps
- [ ] **WATCH CLOSELY - VERIFY SWAPS SUCCEED**
- [ ] Declare winner
- [ ] Everyone claims
- [ ] VERIFY all tokens transferred
- [ ] VERIFY winner got bonus
- [ ] VERIFY executor got reward

## ✅ Scale Up Gradually

- [ ] If 0.0001 ETH pool works, try 0.001 ETH
- [ ] If 0.001 ETH works, try 0.01 ETH
- [ ] Monitor each pool carefully
- [ ] Document any issues
- [ ] Keep gas costs in mind

## ✅ Documentation

- [ ] Document mainnet contract address
- [ ] Create guide for users
- [ ] Explain safety mechanisms
- [ ] Provide support contact
- [ ] List known limitations

## 🚨 Red Flags - STOP if you see these:

- ❌ executeSwaps() reverts on testnet
- ❌ Participants can't claim tokens
- ❌ Winner doesn't get bonus
- ❌ Refund mechanism doesn't work
- ❌ Any function consistently fails
- ❌ Gas costs are unexpectedly high
- ❌ Tokens don't transfer properly

## ✅ Post-Deployment Monitoring

- [ ] Monitor first 3-5 pools closely
- [ ] Check all transactions on BaseScan
- [ ] Verify token transfers
- [ ] Confirm winner bonuses
- [ ] Track executor rewards
- [ ] Watch for any reverts
- [ ] Gather user feedback

## 📞 Support Plan

- [ ] Have this documentation ready
- [ ] Know how to check pool status
- [ ] Understand refund mechanism
- [ ] Can explain cancellation
- [ ] Can guide emergency withdrawal

---

## Key Contract Addresses

**Base Sepolia:**
- V2 Contract: `________________________`
- Test Pool 1: `________________________`
- Test Pool 2 (refund): `________________________`
- Test Pool 3 (cancel): `________________________`

**Base Mainnet:**
- V2 Contract: `________________________`
- Pool 1 (0.0001 ETH): `________________________`
- Pool 2 (0.001 ETH): `________________________`

---

## Deployment Command Reference

### Deploy to Testnet
```bash
forge script script/DeployV2.s.sol:DeployV2Script \
  --rpc-url base_sepolia \
  --broadcast \
  --verify
```

### Deploy to Mainnet
```bash
forge script script/DeployV2.s.sol:DeployV2Script \
  --rpc-url base \
  --broadcast \
  --verify
```

### Build
```bash
forge build
```

### Test
```bash
forge test --match-contract FriendsMemePoolV2Test
```

---

**Remember: The V1 losses taught us valuable lessons. V2 is built on those lessons. Test thoroughly, start small, scale carefully.**

✅ = Completed
⏳ = In Progress  
❌ = Failed/Blocked

Sign off when complete: _____________________ Date: __________
