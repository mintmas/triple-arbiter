#!/usr/bin/env bash
# Example: call Triple Arbiter's /relay/quote proxy.
# Returns a Relay.link cross-chain intent quote with 30 bps appFees pre-baked
# to the facilitator collector (0x5f9B8f3BD13e5320eF5EFAEa906442Fb9B64802c).
# Callers do NOT need their own Relay integration.

set -euo pipefail

FAC="https://mardi-worldwide-sacred-model.trycloudflare.com"

# Default: 100 USDC on Base → WETH on Base (ask-for-amount aka tradeType=EXACT_INPUT)
echo "=== Relay quote: 100 USDC → WETH on Base ==="
curl -s "${FAC}/relay/quote?amount=100000000" | jq '{
  details: .details,
  appFees: .details.appFees,
  totalTradeIn: .details.currencyIn.amount,
  totalTradeOut: .details.currencyOut.amount
}'

# Cross-chain: Arbitrum USDC → Base WETH
echo
echo "=== Relay quote: Arbitrum USDC → Base WETH ==="
curl -s "${FAC}/relay/quote?originChainId=42161&destinationChainId=8453&originCurrency=0xaf88d065e77c8cC2239327C5EDb3A432268e5831&destinationCurrency=0x4200000000000000000000000000000000000006&amount=100000000" \
  | jq '{appFees: .details.appFees, out: .details.currencyOut}'

# Notes:
# - For custom `user`/`recipient` pass &user=0xYourAddr&recipient=0xYourAddr
# - Default user/recipient = collector (safe for dry-run simulation)
# - 30 bps appFees claim via relay.link/claim-app-fees with collector wallet
