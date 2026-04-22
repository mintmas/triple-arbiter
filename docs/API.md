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

## 0x Swap Monetized-Quote Proxy

### GET `/zerox/quote`

Server-side proxy to `api.0x.org/swap/permit2/{price,quote}` (v2). Injects a 50 bps integrator fee payable to the facilitator collector (`0x5f9B8f3BD13e5320eF5EFAEa906442Fb9B64802c`). Callers do **not** need their own 0x API key — the facilitator forwards on Standard-tier credentials with `tier=standard` + `swapFeeBps` + `swapFeeRecipient` + `swapFeeToken` pre-filled.

**Query parameters:**

| Param | Default | Notes |
|---|---|---|
| `chainId` | `8453` (Base) | Any chain 0x v2 supports (1, 10, 137, 42161, 43114, 56, 8453, …) |
| `sellToken` | USDC Base | ERC20 address |
| `buyToken` | WETH Base | ERC20 address |
| `sellAmount` | — | Base units (e.g. `1000000` = 1 USDC on 6-decimal token). One of `sellAmount` / `buyAmount` required. |
| `buyAmount` | — | Base units. |
| `taker` | collector | Address that will sign the permit + execute the swap. Default is safe for dry-run simulation. |
| `slippageBps` | `100` | 1 % default; override with e.g. `50` for 0.5 %. |
| `priceOnly` | `false` | If `true`, hits `/price` (no permit / transaction data) — use for pricing rails without intent to settle. |

**Response:** raw 0x v2 response pass-through. The response shape matches [0x Swap v2 docs](https://0x.org/docs/0x-swap-api/introduction). Key fields:

- `buyAmount`, `minBuyAmount` — target output (base units)
- `fees.integratorFee` — our 50 bps fee (`{amount, token, type: "volume"}`)
- `fees.zeroExFee` — 0x's own 15 bps (not ours)
- `route.fills` — liquidity sources (e.g. Uniswap_V4, Aerodrome_V2, TraderJoe_V2.2)
- `transaction` — `{to, data, gas, gasPrice, value}` ready to sign/broadcast (full quote only)
- `permit2` — EIP-712 typed data for Permit2 signing (full quote only)

**Example:**
```bash
curl -s 'https://mardi-worldwide-sacred-model.trycloudflare.com/zerox/quote?sellAmount=100000000'
```

Sells 100 USDC → WETH on Base. Response includes a transaction whose calldata transfers exactly `500000` atoms (0.5 USDC = 50 bps) to the collector as part of the same atomic swap.

**Monetization model:** 0x v2 splits monetization natively — `integratorFee` is collected on top of the swap route via the Permit2 AllowanceHolder flow; the taker signs a single Permit2 authorization and the AllowanceHolder contract atomically forwards our fee before executing the swap. No separate transaction or approval required.

### GET `/swap`

Returns a self-contained HTML page embedding the official `@0x/swap-ui` widget, pre-configured with the facilitator's collector + 50 bps fee. Drop-in for anyone needing a hosted swap UI without running their own 0x integration.

## Relay Cross-Chain Intent Proxy

### GET `/relay/quote`

Proxy to Relay.link cross-chain intent router. Injects `appFees: [{recipient: <collector>, fee: "30"}]` on every quote — 30 bps of input amount flows to the facilitator collector on settlement. Callers do NOT need their own Relay integration.

**Query parameters:**

| Param | Default | Notes |
|---|---|---|
| `originChainId` | `8453` (Base) | Source chain for input currency |
| `destinationChainId` | `8453` | Destination chain for output currency |
| `originCurrency` | USDC Base | Input token address |
| `destinationCurrency` | WETH Base | Output token address |
| `amount` | — required | Input amount in base units |
| `user` | collector | Address signing the intent (defaults safe for dry-run) |
| `recipient` | user | Address receiving output |
| `tradeType` | `EXACT_INPUT` | `EXACT_INPUT` or `EXACT_OUTPUT` |

**Response:** Relay v1 quote pass-through with `appFees` entry in `details`. Claim via relay.link/claim-app-fees with collector wallet.

## KyberSwap Aggregator Proxy

### GET `/kyber/quote`

Proxy to KyberSwap aggregator (14+ chains). Injects `extraFee` with `feeReceiver=<collector>`, `isInBps=true`, `feeAmount=30` → 30 bps auto-collected at swap execution. No registration required.

**Query parameters:**

| Param | Default | Notes |
|---|---|---|
| `chainId` | `8453` | ethereum/base/arbitrum/optimism/polygon/bsc/avalanche/gnosis |
| `tokenIn` | USDC Base | Input token address |
| `tokenOut` | WETH Base | Output token address |
| `amountIn` | — required | Input amount in base units |
| `saveGas` | `false` | If true, prefer gas-efficient routes |

**Response:** KyberSwap `/api/v1/routes` pass-through with `extraFee` populated in `routeSummary`. Caller submits encoded calldata to KyberSwap router to execute.

## Mayan Finance Cross-Chain Proxy

### POST `/mayan/quote`

Cross-chain (Ethereum/Arbitrum/Optimism/Polygon/BSC/Avalanche → Base) quote via Mayan Swift v3. Injects `referrer=<SOL_collector>` + `referrerBps=25` on every quote. 25 bps of routed amount flows to Solana collector wallet.

See [INTEGRATION.md](INTEGRATION.md) for full Mayan payload schema — this endpoint pre-dates the swap-proxy pattern.

## Error format

All errors return FastAPI-standard:
```json
{"detail": "<string or object>"}
```
