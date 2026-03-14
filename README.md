# plat-eng-building-block-cache

A Helm chart building block for provisioning Azure Cache for Redis instances via Crossplane.

## Overview

This building block creates `RedisCache` Crossplane managed resources
(`cache.azure.upbound.io/v1beta2`) for each entry in the `caches.redis` array.

## Quick Start

```bash
make dep-build       # Build chart dependencies
make lint            # Lint the chart
make yamllint        # Lint YAML files
make test            # Run unit tests
make package         # Package the chart
```

## Documentation

See the [`docs/`](docs/) directory for:
- [`azure-redis-cache-summary.md`](docs/azure-redis-cache-summary.md) — Azure Cache for Redis and Crossplane reference
- [`helm-chart-templates-summary.md`](docs/helm-chart-templates-summary.md) — Helm chart templates guide
