#!/usr/bin/env bash
# Example: get a 0x Swap v2 monetized quote via the Triple Arbiter facilitator.
#
# The facilitator's /zerox/quote endpoint forwards to api.0x.org/swap/permit2/
# with a 50 bps integrator fee already baked in — callers do NOT need their
# own 0x API key. The 50 bps is paid to the facilitator collector
# (0x5f9B8f3BD13e5320eF5EFAEa906442Fb9B64802c) as part of the atomic swap
# transaction via 0x's Permit2 AllowanceHolder flow.
#
# Verified live 2026-04-22 on Base + Arbitrum.

set -euo pipefail

FAC="https://mardi-worldwide-sacred-model.trycloudflare.com"

# --- 1. Dry-run price (no permit/transaction data, just pricing) ---
# Sells 1 USDC on Base, see what 50 bps fee looks like.
echo "=== 1 USDC → WETH on Base, priceOnly ==="
curl -s "${FAC}/zerox/quote?sellAmount=1000000&priceOnly=true" \
  | jq '{
      buyAmount,
      integratorFee: .fees.integratorFee,
      zeroExFee: .fees.zeroExFee,
      route: [.route.fills[].source]
    }'

# Expected: integratorFee.amount == "5000" (= 50 bps of 1_000_000 atoms of USDC).

# --- 2. Full quote ready to sign + broadcast ---
# Sells 100 USDC → WETH on Base. Returns Permit2 EIP-712 typed data + calldata.
echo
echo "=== 100 USDC → WETH on Base, full quote ==="
curl -s "${FAC}/zerox/quote?sellAmount=100000000" \
  | jq '{
      buyAmount,
      minBuyAmount,
      integratorFee: .fees.integratorFee,
      transaction: {to: .transaction.to, gas: .transaction.gas},
      permit2_hash: .permit2.hash
    }'

# Expected: integratorFee.amount == "500000" (= 0.5 USDC = 50 bps of 100 USDC).

# --- 3. Cross-chain — same flow on Arbitrum ---
# USDC (native) → WETH on Arbitrum (chainId 42161).
echo
echo "=== 1 USDC → WETH on Arbitrum ==="
curl -s "${FAC}/zerox/quote?chainId=42161&sellToken=0xaf88d065e77c8cC2239327C5EDb3A432268e5831&buyToken=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1&sellAmount=1000000&priceOnly=true" \
  | jq '{
      buyAmount,
      integratorFee: .fees.integratorFee,
      route: [.route.fills[].source]
    }'

# --- Notes ---
# - For custom taker, pass &taker=0xYOUR_ADDR
# - For different slippage, pass &slippageBps=50 (=0.5%)
# - For buy-side amount, pass &buyAmount=N instead of sellAmount=N
# - Full 0x v2 response schema: https://0x.org/docs/0x-swap-api/introduction
