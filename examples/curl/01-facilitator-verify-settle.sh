#!/usr/bin/env bash
# Example: call /verify then /settle on Triple Arbiter facilitator.
# Requires: a pre-signed EIP-3009 TransferWithAuthorization payload
# (generate with examples/python/simple_client.py)
#
# Export env vars before running:
#   FROM_ADDR=0x...
#   TO_ADDR=0x...  (facilitator wallet for attestation purchases)
#   VALUE_UNITS=2000000           # USDC 6-decimals, e.g. 2_000_000 = $2
#   VALID_AFTER=0
#   VALID_BEFORE=1999999999
#   NONCE=0x...                    # 32-byte hex
#   SIGNATURE=0x...                # 65-byte hex (r + s + v)

set -euo pipefail

FAC="https://mardi-worldwide-sacred-model.trycloudflare.com"

AUTH_JSON=$(cat <<EOF
{
  "authorization": {
    "from": "${FROM_ADDR}",
    "to": "${TO_ADDR}",
    "value": "${VALUE_UNITS}",
    "validAfter": ${VALID_AFTER},
    "validBefore": ${VALID_BEFORE},
    "nonce": "${NONCE}",
    "signature": "${SIGNATURE}"
  },
  "resource": "urn:example:test-settlement",
  "amount_usd": "2.00"
}
EOF
)

echo "=== /verify ==="
VERIFY_RESP=$(curl -s -X POST "$FAC/verify" \
  -H "content-type: application/json" \
  -d "$AUTH_JSON")
echo "$VERIFY_RESP" | python3 -m json.tool

VERIFY_TOKEN=$(echo "$VERIFY_RESP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('verify_token', ''))")
if [ -z "$VERIFY_TOKEN" ]; then
  echo "!!! verify_token not issued; cannot settle"
  exit 1
fi

SETTLE_JSON=$(cat <<EOF
{
  "authorization": {
    "from": "${FROM_ADDR}",
    "to": "${TO_ADDR}",
    "value": "${VALUE_UNITS}",
    "validAfter": ${VALID_AFTER},
    "validBefore": ${VALID_BEFORE},
    "nonce": "${NONCE}",
    "signature": "${SIGNATURE}"
  },
  "verify_token": "${VERIFY_TOKEN}"
}
EOF
)

echo ""
echo "=== /settle ==="
curl -s -X POST "$FAC/settle" \
  -H "content-type: application/json" \
  -d "$SETTLE_JSON" | python3 -m json.tool
