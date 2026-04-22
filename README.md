# Triple Arbiter

**x402 settlement facilitator + EAS-compatible threat-intel attestation issuer on Base mainnet.**

- Chain: Base (chainId 8453)
- Asset: USDC
- Fee: 50 bps on settlement, non-custodial (peer-to-peer)
- Minimum transfer: $2
- Attestation pricing: $0.01 / $0.10 / $0.50 per query

## Services

### 1. x402 Facilitator

Verifies EIP-3009 signed USDC authorizations and broadcasts `transferWithAuthorization` on Base. Non-custodial: client's USDC moves peer-to-peer to intended payee. We verify the signature, check balance, broadcast the transaction, and collect a disclosed 0.5% facilitator fee.

**Endpoint:** `https://mardi-worldwide-sacred-model.trycloudflare.com`

### 2. EAS Threat-Intel Attestation Issuer

Pay-per-query EIP-712-signed (EAS-compatible off-chain envelope) attestations over three schemas:

- **`adversarial`** — CAF v1.4 scan (180+ adversarial-prompt patterns across 13 layers: identity hijack, capability claims, authority spoof, meta-cognition attacks, memory poisoning, narrative framing, cross-agent collusion, alignment decoupling, operationalized orchestration, deference-mode activation, latent-trace attacks, temporal drift, esoteric-hybrid)
- **`mcp-shadow`** — Couliano phantasm audit (MCP tool-description/execution divergence detection; 84.2% of MCP tools in the wild are "smelly" per arXiv 2503.23278)
- **`esoteric`** — L13 esoteric-hybrid signature scan (Chaos Magic servitor invocation, Alchemical dissolution framing, Kabbalistic path-walking, Gurdjieff shock-points, Sufi fana', Enochian fragments, Hypersigil self-declaration, sacred-space declarations). Unique to Triple Arbiter — only attestation issuer covering this attack surface.

**Endpoint:** `https://reward-priority-delete-pricing.trycloudflare.com`

### 3. 0x Swap Monetized-Quote Proxy

`GET /zerox/quote` — server-side proxy to `api.0x.org/swap/permit2/{price,quote}` with a 50 bps integrator fee already baked into every returned quote (settles to the facilitator collector on-chain in the same swap transaction). Agents call this endpoint without provisioning their own 0x API key; the facilitator transparently forwards with `tier=standard` + `swapFeeBps=50` + `swapFeeRecipient=<collector>`.

Use cases:
- Agents that need swap routing but don't want to manage a 0x account
- Drop-in swap widget backend (`/swap` serves a pre-configured 0x widget HTML)
- Cross-chain compatible (Base, Arbitrum, Optimism, Polygon, Mainnet — any chain 0x v2 supports)

**Endpoint:** `https://mardi-worldwide-sacred-model.trycloudflare.com/zerox/quote`

## Agent discovery

All standard manifests are published:

- [x402 facilitator manifest](https://mardi-worldwide-sacred-model.trycloudflare.com/.well-known/x402-facilitator.json)
- [A2A AgentCard](https://mardi-worldwide-sacred-model.trycloudflare.com/.well-known/agent-card.json)
- [MCP server manifest](https://mardi-worldwide-sacred-model.trycloudflare.com/.well-known/mcp.json)
- [llms.txt](https://mardi-worldwide-sacred-model.trycloudflare.com/llms.txt)
- [OpenAPI 3.0 spec](https://mardi-worldwide-sacred-model.trycloudflare.com/openapi.json)
- [Swagger UI](https://mardi-worldwide-sacred-model.trycloudflare.com/docs)
- [Discovery catalog](https://mardi-worldwide-sacred-model.trycloudflare.com/discovery/resources)

## Payment flow

See [docs/INTEGRATION.md](docs/INTEGRATION.md) for step-by-step integration guide, or run one of the examples in [examples/](examples/).

Quick version:

1. Client signs EIP-3009 `transferWithAuthorization` authorizing $X USDC to the facilitator wallet (`0xBE5Df0394dBD9cC19127cf93CD9b543f2eb63b97` on Base).
2. Client `POST /verify` with the authorization → receives a verify_token.
3. Client `POST /settle` with `{authorization, verify_token}` → receives `tx_hash`.
4. For attestations: client `POST /query` to the attestation service with header `x-facilitator-settled: <tx_hash>` and body `{schema_uid, subject, scan_text}` → receives EIP-712-signed attestation envelope.

## Why an agent should use this

- **Standard x402 integration** — zero vendor lock-in, swap facilitators anytime
- **Non-custodial** — your USDC never touches our wallet, peer-to-peer on-chain
- **Signed attestations** — cryptographically verifiable claims agents can present in audit/compliance flows
- **Unique coverage** of esoteric-framing attack surface not indexed by any other safety service
- **Transparent fees** — 50 bps published, no surprises

## Legal / scope

- Opt-in only (submission of authorization constitutes opt-in)
- Not a custodian (peer-to-peer settlement per EIP-3009)
- 90-day log retention, no PII collected
- Fee schedule public at [/fees](https://mardi-worldwide-sacred-model.trycloudflare.com/fees)
- Terms at [/tos](https://mardi-worldwide-sacred-model.trycloudflare.com/tos)

## Repository layout

- [`docs/`](docs/) — API reference, integration guide, schema details
- [`examples/curl/`](examples/curl/) — shell scripts showing verify → settle → attestation flow
- [`examples/python/`](examples/python/) — Python client example with EIP-3009 signing
- [`examples/typescript/`](examples/typescript/) — TypeScript/viem client example

## License

MIT. See [LICENSE](LICENSE).

## Contact

Open an issue on this repo. On-chain identity: `0xBE5Df0394dBD9cC19127cf93CD9b543f2eb63b97` on Base.
