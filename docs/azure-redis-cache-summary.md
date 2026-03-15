# Azure Cache for Redis Documentation Summary

This note summarizes key concepts for the Azure Cache for Redis service and its
Crossplane integration via `provider-azure-cache`.

## What Azure Cache for Redis Is

- Managed, fully hosted in-memory data store based on open-source Redis
- Use cases: application caching, session storage, message broker, pub/sub,
  leaderboards, distributed locks
- Compatible with Redis OSS clients, tools, and frameworks
- Accessed over TLS port 6380 (SSL) or optionally port 6379 (non-SSL)

## SKU Tiers and Families

- **Basic** (`family: C`, `skuName: Basic`): Single node, no replication, dev/test
  only, no SLA. Sizes C0 (250MB) through C6 (53GB).
- **Standard** (`family: C`, `skuName: Standard`): Two-node primary/replica pair with
  SLA. Sizes C0–C6.
- **Premium** (`family: P`, `skuName: Premium`): Enterprise-grade with clustering,
  VNet injection, geo-replication, RDB/AOF persistence, and availability zones.
  Sizes P1–P5.

## Key Configuration Parameters

- **Required**: `capacity` (size index 0–6 for C, 1–5 for P), `family` (C or P),
  `skuName` (Basic/Standard/Premium), `location` (Azure region), `redisVersion`
  ("4" or "6"), `resourceGroupName`
- **TLS**: `minimumTlsVersion` — use `"1.2"` (TLS 1.0/1.1 are deprecated by Azure).
  `nonSslPortEnabled` defaults to false; keep it false for security.
- **Network**: `publicNetworkAccessEnabled` (default true). VNet injection via
  `subnetId` (Premium only, forces resource recreation if changed).
- **Redis behavior**: `redisConfiguration.maxmemoryPolicy` (eviction policy, e.g.
  `volatile-lru`); `redisConfiguration.maxmemoryReserved` (MB reserved for non-cache
  use). Note: `redisConfiguration` is an **object**, not an array, in v1beta2.

## Crossplane Integration

- Provider: `xpkg.upbound.io/upbound/provider-azure-cache:v2.3.0`
- API: `cache.azure.upbound.io/v1beta2`, Kind: `RedisCache`
- Declare all required fields under `spec.forProvider`
- `spec.providerConfigRef.name` — references the Crossplane `ProviderConfig` resource
  that holds Azure credentials
- `spec.writeConnectionSecretToRef` — Crossplane writes connection details to this
  Kubernetes Secret automatically

## Connection Secrets

Crossplane populates a Kubernetes Secret via `writeConnectionSecretToRef` with these
keys (note the required `attribute.` prefix):

- `attribute.primary_access_key` — primary Redis authentication key
- `attribute.primary_connection_string` — full connection string with primary key
- `attribute.secondary_access_key` — secondary Redis authentication key
- `attribute.secondary_connection_string` — full connection string with secondary key

Connection string format: `<hostname>:6380,password=<key>,ssl=True,abortConnect=False`

## Operational Notes

- **Provisioning time**: Standard tier takes 15–30 minutes to provision; Premium can
  take longer.
- **Immutable fields**: `subnetId`, `privateStaticIpAddress`, and `zones` force full
  resource recreation if changed after initial provisioning.
- **Redis version**: Only the major version is specified ("4" or "6"). Azure manages
  patch updates automatically.

## Retirement Notice

Microsoft has announced the retirement of Azure Cache for Redis (all current
SKUs — Basic, Standard, Premium). The recommended migration path is
**Azure Managed Redis**, available via the `ManagedRedis` kind in `provider-azure-cache`.
This building block uses `RedisCache` as the current stable offering. Plan
migration when the retirement timeline applies to your workloads.
