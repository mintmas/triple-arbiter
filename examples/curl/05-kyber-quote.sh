#!/usr/bin/env bash
# Example: call Triple Arbiter's /kyber/quote proxy.
# Returns a KyberSwap aggregator route with 30 bps extraFee baked into
# calldata, routed to the facilitator collector.

set -euo pipefail

FAC="https://mardi-worldwide-sacred-model.trycloudflare.com"

echo "=== Kyber: 100 USDC → WETH on Base ==="
curl -s "${FAC}/kyber/quote?amountIn=100000000" | jq '{
  gas: .data.gas,
  outputAmount: .data.routeSummary.amountOut,
  extraFee: .data.routeSummary.extraFee,
  route_count: (.data.routeSummary.route | length)
}'

echo
echo "=== Kyber: Arbitrum USDC → WETH ==="
curl -s "${FAC}/kyber/quote?chainId=42161&tokenIn=0xaf88d065e77c8cC2239327C5EDb3A432268e5831&tokenOut=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1&amountIn=100000000" \
  | jq '{out: .data.routeSummary.amountOut, extraFee: .data.routeSummary.extraFee}'

# Notes:
# - Supported chains: ethereum, base, arbitrum, optimism, polygon, bsc, avalanche, gnosis
# - extraFee.feeReceiver = facilitator collector, isInBps=true
# - No registration; 30 bps auto-collected by KyberSwap router on swap execution
