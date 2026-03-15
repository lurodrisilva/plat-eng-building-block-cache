# Agent Instructions

## Project Overview

Helm **application** chart (`plat-eng-cache-package`) that provisions Azure Cache for Redis
instances via Crossplane. Depends on `plat-eng-commons-package` (OCI library chart) for shared
helpers (`myorg.fullname`, `myorg.labels`).

Uses `RedisCache` kind from `provider-azure-cache` v2.3.0 (`cache.azure.upbound.io/v1beta2`).
Manages instances via `caches.redis[]` array in `values.yaml` — one `RedisCache` Crossplane
managed resource is created per array entry.

## Build / Lint / Test Commands

```bash
# === Setup (first time only) ===
make plugin-install          # Install helm-unittest plugin + print yamllint/kubeconform install instructions

# === Dependencies ===
make dep-build               # Build dependencies for main chart
make dep-build-test          # Build dependencies for test wrapper chart

# === Linting (three-tier) ===
make lint                    # helm lint .
make yamllint                # yamllint -c .yamllint.yml .
make kubeconform             # helm template | kubeconform --strict --ignore-missing-schemas
make lint-all                # All three above in sequence

# === Unit Tests ===
make test                    # Run all helm-unittest tests

# Run a SINGLE test file:
helm dependency build tests/chart
helm unittest -f 'tests/chart/tests/<test_file>.yaml' tests/chart

# === Combined ===
make all                     # lint-all + test + package

# === Packaging ===
make package                 # helm package . → plat-eng-cache-package-*.tgz
make clean                   # rm -f plat-eng-cache-package-*.tgz + charts/ + Chart.lock

# === Render templates locally (debugging) ===
helm template test-release . \
  --set caches.redis[0].name=my-redis \
  --set caches.redis[0].capacity=1 \
  --set caches.redis[0].family=C \
  --set caches.redis[0].location=eastus \
  --set caches.redis[0].redisVersion=6 \
  --set caches.redis[0].skuName=Basic \
  --set caches.redis[0].resourceGroupName=my-rg
```

## Project Structure

```
.github/workflows/helm-ci.yml          — CI pipeline (lint, test, package, push)
docs/
  azure-redis-cache-summary.md         — Azure Cache for Redis + Crossplane reference
  helm-chart-templates-summary.md      — Helm chart templates reference
templates/
  _helpers.tpl                         — cache.serviceAccountName helper
  redis-cache.yaml                     — RedisCache Crossplane resource template (range loop)
  serviceaccount.yaml                  — Conditional ServiceAccount
tests/chart/                           — Wrapper chart for helm-unittest
  Chart.yaml                           — Declares dependency on this chart via file://../../
  values.yaml                          — Test override values (plat-eng-cache-package.* prefix)
  tests/                               — Test files (*_test.yaml)
Chart.yaml                             — Chart metadata and dependencies
Makefile                               — Build/lint/test automation (12 targets)
values.yaml                            — Default values
.gitignore / .helmignore               — Version control / packaging exclusions
.yamllint.yml                          — YAML lint configuration
```

## Wrapper Chart Test Pattern

Tests use a **wrapper chart** at `tests/chart/` that declares `plat-eng-cache-package` as a
dependency via `file://../../`. This is required because helm-unittest needs a chart to run against.

**Key implications:**
- Template paths in tests: `charts/plat-eng-cache-package/templates/<file>`
- All `set:` values must use the `plat-eng-cache-package.` prefix
- All values in `tests/chart/values.yaml` are scoped under the `plat-eng-cache-package:` key
- Run `helm dependency build tests/chart` before tests (Makefile does this automatically)
- Document ordering in `redis-cache.yaml`: one `RedisCache` document per array entry (index-based)

## Code Style & Conventions

### Helm Templates

- **Helpers**: Define in `_helpers.tpl` with `{{- define "cache.<name>" -}}`
- **Labels**: Always use `{{- include "myorg.labels" $ | nindent N }}` (from commons-package, use `$` inside range loops)
- **Naming**: Use `{{ include "myorg.fullname" . }}` for resource names; do NOT hardcode
- **Range loops**: Use `{{- range $index, $redis := .Values.caches.redis }}` with `$` for global scope
- **Conditionals**: Guard optional blocks with `{{- if hasKey $redis "field" }}` / `{{- end }}`
- **Whitespace control**: Use `{{-` and `-}}` to trim whitespace; use `nindent` for indentation
- **Document separators**: Use `---` between resources in multi-resource templates
- **String fields**: Use `| quote` on string `forProvider` fields (e.g., `family`, `location`, `skuName`)

### Values

- `camelCase` for value keys (`serviceAccount`, `providerConfigRef`, `writeConnectionSecretToRef`)
- Nested grouping: `caches.redis[]` is an array of Redis cache definitions
- Commented examples for optional fields (see `redisConfiguration`, `tags` in `values.yaml`)
- Required fields uncommented; optional fields commented with `#`

### YAML Formatting

- 2-space indentation everywhere
- Max line length: 200 characters (`.yamllint.yml`)
- No trailing whitespace
- Files must end with a newline
- `templates/` directory is excluded from yamllint (Go template syntax)

### Unit Tests (helm-unittest)

- One test file per template: `<template_name>_test.yaml`
- Use assertion-based tests, NOT snapshot tests
- Use `documentIndex: N` to target specific resources in multi-doc templates
- Use `hasDocuments: count: N` to verify conditional rendering
- Use `equal:`, `exists:`, `notExists:` for field assertions
- Cover both happy path AND conditional branches (e.g., `redisConfiguration` present/absent)
- Do NOT test `myorg.labels` content (that belongs to commons-package tests)

## Commit Message Format

Conventional Commits format:

```
feat(chart): add support for Redis Enterprise SKU
feat(templates): add patch strategy annotation to RedisCache
test: add helm-unittest tests for redis-cache template
docs: update AGENTS.md with redisConfiguration quirk
chore: update .helmignore to exclude test artifacts
ci: pin Helm version to 3.20.0 in workflow
fix: correct redisVersion quoting in redis-cache template
```

Types: `feat`, `fix`, `chore`, `test`, `docs`, `refactor`, `ci`
Optional scope in parentheses: `feat(chart):`, `fix(templates):`, `chore(ci):`

## Workflow Guidelines

- **Never push directly to master.** Always work on a feature branch and open a Pull Request.
- **Always create a Pull Request when finishing changes.** Do not leave committed work on a branch without a PR. Every set of changes — no matter how small — must go through a PR before merging to master.
- Run `make all` before committing to verify nothing is broken.
- When modifying templates, run the relevant single test file first for fast feedback.
- After adding a new optional field to `redis-cache.yaml`, add a corresponding test case for both present and absent scenarios.

## Guardrails — Do NOT

- Add Helm native test hooks in `templates/tests/` (reserved, must stay empty)
- Suppress lint/type errors to make things pass
- Add snapshot tests unless explicitly requested
- Modify `myorg.*` helpers (those belong to `plat-eng-commons-package`)
- Commit `Chart.lock`, `charts/`, or `tests/chart/charts/` (all gitignored)
- Use bare integer `6` for `redisVersion` — it must be quoted (`"6"`) in YAML

## Dependencies & Tools

| Tool | Purpose | Install |
|------|---------|---------|
| Helm 3 | Chart templating & packaging | `brew install helm` |
| helm-unittest | Unit testing plugin | `helm plugin install https://github.com/helm-unittest/helm-unittest` |
| yamllint | YAML linting | `brew install yamllint` |
| kubeconform | K8s manifest validation | `brew install kubeconform` |

### Chart Dependencies

- **`plat-eng-commons-package`** v0.1.0 from `oci://ghcr.io/lurodrisilva/helm-charts`
  - Provides: `myorg.fullname` (naming helper), `myorg.labels` (standard labels)
  - Usage in templates: `include "myorg.fullname" .` and `include "myorg.labels" $`

### Known Quirks

- **kubeconform**: Crossplane `RedisCache` CRD is not in the default K8s schemas — `--ignore-missing-schemas` is required
- **`redisConfiguration` is an object (not array)** in `cache.azure.upbound.io/v1beta2` — use `toYaml | nindent` to render it correctly (do NOT iterate over it)
- **`redisVersion` must be quoted** (`"6"`) — bare `6` is parsed as a number by YAML and will fail Crossplane validation
- **`.helmignore` must use `./charts/*`** (not `charts/`) — using `charts/` causes Helm to ignore the dependency directory entirely, breaking `helm lint` and `helm template`
- **`providerConfigRef` and `writeConnectionSecretToRef`** use `$.Values` (root context) inside `range` loops — `$redis` only has the current array entry's values
- **helm-unittest 1.0.3**: `containsDocument:` is broken — use `documentIndex: N` + `isKind:` instead
- **yamllint warnings**: "missing document start" on test files is expected (exit 0, non-blocking)
