# API Reference

## Facilitator (`https://mardi-worldwide-sacred-model.trycloudflare.com`)

### GET `/`
Landing page (HTML).

### GET `/health`
Liveness + facilitator config + balance.

**Response** (application/json):
```json
{
  "status": "ok",
  "facilitator_address": "0xbe5df0394dbd9cc19127cf93cd9b543f2eb63b97",
  "facilitator_eth_balance": "0.004877",
  "chain_id": 8453,
  "rpc_url": "https://mainnet.base.org",
  "usdc_address": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  "fee_bps": 50,
  "min_transfer_usd": "2.00",
  "tos_version": "2026-04-19-v1"
}
```

### GET `/fees`
Current fee schedule.

### GET `/tos`
Terms of service.

### POST `/verify`
Validate EIP-3009 authorization.

**Request:**
```json
{
  "authorization": {
    "from": "0x...",
    "to": "0x...",
    "value": "2000000",
    "validAfter": 0,
    "validBefore": 1999999999,
    "nonce": "0x...",
    "signature": "0x..."
  },
  "resource": "urn:example:purpose",
  "amount_usd": "2.00"
}
```

**Response (200, ok=true):**
```json
{
  "ok": true,
  "fee_bps": 50,
  "fee_usd": "0.01",
  "net_to_payee_usd": "1.99",
  "expiry_unix": 1999999999,
  "verify_token": "..."
}
```

**Rejection reasons** (200 with `ok: false`):
- `below minimum transfer $2.00`
- `authorization expired`
- `authorization not yet valid`
- `amount_usd ... does not match authorization.value`
- `signature mismatch: recovered 0x... != from 0x...`
- `nonce already consumed`
- `insufficient USDC balance`

### POST `/settle`
Broadcast settlement on-chain. Consumes `verify_token`.

**Request:**
```json
{
  "authorization": { /* same as /verify */ },
  "verify_token": "..."
}
```

**Response:**
```json
{
  "ok": true,
  "tx_hash": "0x...",
  "block_number": 44909001,
  "fee_recorded_usd": "0.01"
}
```

### GET `/.well-known/x402-facilitator.json`
Standard x402 facilitator manifest.

### GET `/x402-facilitator.json`
Mirror of above at root path (fallback if /.well-known/ is intercepted).

### GET `/.well-known/agent-card.json`
A2A AgentCard v1 format.

### GET `/.well-known/mcp.json`
MCP server manifest (2025-06-18 version).

### GET `/llms.txt`
Plain-text agent-readable site description.

### GET `/discovery/resources`
Bazaar-compatible resource catalog.

### GET `/openapi.json`
OpenAPI 3.0 specification.

### GET `/docs`
Swagger UI.

## Attestation Issuer (`https://reward-priority-delete-pricing.trycloudflare.com`)

### GET `/health`

### GET `/schemas`
List of published schemas with fields + pricing.

### POST `/query`
Issue signed attestation. Requires `x-facilitator-settled: <tx_hash>` header.

**Without header → 402 Payment Required:**
```json
{
  "detail": {
    "reason": "payment required",
    "price_usd": "0.01",
    "facilitator_endpoint": "https://mardi-worldwide-sacred-model.trycloudflare.com",
    "hint": "POST /verify + /settle to facilitator, then retry with x-facilitator-settled header."
  }
}
```

**With header:**
```json
{
  "ok": true,
  "attestation": {
    "issuer": "0x...",
    "subject": "...",
    "schema_uid": "0x...",
    "claim_hash": "0x...",
    "signature": "0x...",
    "issued_at": 1745099394,
    "expires_at": 1745185794,
    "level": "basic",
    "chain_id": 8453,
    "eas_contract": "0x4200000000000000000000000000000000000021",
    "version": "eas-offchain-v1.0.0"
  },
  "claim_data": { /* schema-specific */ },
  "price_usd": "0.01"
}
```

## Error format

All errors return FastAPI-standard:
```json
{"detail": "<string or object>"}
```
