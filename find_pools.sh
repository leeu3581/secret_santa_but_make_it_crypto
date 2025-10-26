#!/bin/bash

# Script to find Uniswap V3 pool addresses on Base
# Usage: ./find_pools.sh <token_address>

FACTORY=0x33128a8fC17869897dcE68Ed026d694621f6FDfD
WETH=0x4200000000000000000000000000000000000006

if [ -z "$1" ]; then
    echo "Usage: ./find_pools.sh <token_address>"
    echo ""
    echo "Example popular tokens on Base:"
    echo "USDC:  0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
    echo "DAI:   0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb"
    echo "cbBTC: 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf"
    echo ""
    exit 1
fi

TOKEN=$1

echo "Finding Uniswap V3 pools for token: $TOKEN"
echo "Paired with WETH: $WETH"
echo ""

echo "Checking 0.3% fee tier (3000)..."
POOL_3000=$(cast call $FACTORY "getPool(address,address,uint24)" $TOKEN $WETH 3000 --rpc-url base 2>/dev/null)
if [ "$POOL_3000" != "0x0000000000000000000000000000000000000000" ]; then
    echo "✅ 0.3% fee pool: $POOL_3000"
else
    echo "❌ No 0.3% fee pool found"
fi

echo ""
echo "Checking 0.05% fee tier (500)..."
POOL_500=$(cast call $FACTORY "getPool(address,address,uint24)" $TOKEN $WETH 500 --rpc-url base 2>/dev/null)
if [ "$POOL_500" != "0x0000000000000000000000000000000000000000" ]; then
    echo "✅ 0.05% fee pool: $POOL_500"
else
    echo "❌ No 0.05% fee pool found"
fi

echo ""
echo "Checking 1% fee tier (10000)..."
POOL_10000=$(cast call $FACTORY "getPool(address,address,uint24)" $TOKEN $WETH 10000 --rpc-url base 2>/dev/null)
if [ "$POOL_10000" != "0x0000000000000000000000000000000000000000" ]; then
    echo "✅ 1% fee pool: $POOL_10000"
else
    echo "❌ No 1% fee pool found"
fi

echo ""
echo "Done! Use the non-zero address in your pool creation."
