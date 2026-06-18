# Risk Decisioning Platform — AI collaborator guide

> This file sets working agreements for AI collaborators (Claude Code and others). Read this before writing code or plans.

## What this project is

A focused credit risk decisioning platform. Answers one question: *should we give this customer this loan, on what terms?* Nothing more.

Full charter: [`PROJECT.md`](./PROJECT.md). Architecture: [`ARCHITECTURE.md`](./ARCHITECTURE.md). Roadmap: [`ROADMAP.md`](./ROADMAP.md). GSD state: [`.planning/`](./.planning/).

## Working rules

### 1. Contract-first, not code-first

Before writing any service code, the service's design doc (`docs/design/<service>.md`) must be filled in and its contracts must exist in `contracts/`. If either is missing, write those first.

### 2. Hexagonal everywhere

Services depend on **ports** (Protocols in `packages/canonical-dto/ports/`), never on concrete providers. Adapters live under `services/integration-hub/adapters/<provider>/` (for cross-service integrations) or next to the service core (for per-service adapters like DB).

### 3. Multi-jurisdiction from day 1

No `if jurisdiction == "kz"` in business logic anywhere. Jurisdiction-specific behavior belongs in `jurisdictions/<code>/pack.yaml`. If the schema can't express your case, update the schema (new minor version), not the code.

### 4. Multi-tenant + multi-instance by design

Every request, every DB row, every event carries `tenant_id` + `jurisdiction_code` + `instance_id`. Enforced at middleware + repository layers. `instance_id` defaults to `"default"` in v1 so the system works single-instance on Compose, and gains real meaning when `platform-control` starts spawning instances in v1.5. See ADR-008, ADR-012.

### 5. Idempotency on mutating endpoints

Every write endpoint accepts and enforces `idempotency_key`. Duplicates return the same response, no repeated side effects. See ADR-004.

### 6. Decision snapshot is sacred

A decision is append-only. It binds `feature_snapshot_id`, `model_version_id`, `strategy_pack_version`, `jurisdiction_pack_version`, resolved `module_id@version` + configs per stage, `identity_version`, `experiment_arms[]`. Replay must produce identical output a year later. See ADR-005, ADR-011, ADR-013, ADR-015.

### 7. Explainability on every decision

Every decision response carries: rules fired (with pack reference), models applied (with scores), top-N SHAP features, economics calculation, blocking stage (if blocked). No "black-box approved".

### 8. Sync for commands/queries, events for facts

HTTP for request/response. Redpanda for "X happened". Every event uses the envelope from `packages/event-envelope`. See ADR-007.

### 9. Observability from day 1

Every service starts with `packages/observability.bootstrap()`. Standard span names on decision stages. Standard metrics. Structured logs with `trace_id`, `tenant_id`, `jurisdiction_code`, `correlation_id`. See ADR-010.

### 10. Security baseline

- Auth via Keycloak OIDC (at the gateway).
- No CORS `*`.
- No secrets in code — env vars only, no fallbacks.
- No SQL string interpolation — parameterized queries only.
- Input validation at the API boundary via Pydantic.
- Rate limits per role + endpoint class.

### 11. Everything configurable is a module (ADR-011)

If you are adding a new cascade stage, a new regulatory check, a new economics strategy, a new adapter, a new feature set, a new explainer, or a new report — it is a **module**. It ships:
- `services/<service>/modules/<id>/manifest.json`
- `services/<service>/modules/<id>/config_schema.json`
- Implementation + unit tests + a golden-path test
- Reference from a strategy pack or jurisdiction pack to activate it

The service exposes `GET /modules/catalog`. Module versions are immutable. Never mutate a released version — ship a new one.

### 13. One canonical customer identity (ADR-013)

Never key customer-scoped data on a channel-local `customer_id`. Every DTO that carries customer context carries `customer_master_id` + `identity_version` from `identity-service`. Before anything touches a customer, `identity-service.resolve` has been called. Features, decisions, portfolio analytics, experiment assignments — all keyed on the master. Merge/split events trigger compensating re-keys; in-flight snapshots are preserved by the pinned `identity_version`.

### 14. Metrics go through the catalog (ADR-014)

No dashboard, no report, no alert, no guardrail reads a raw gold table for a KPI. Every KPI is defined once in `metrics/*.yaml`, materialized by dbt, and consumed by name. Changing a formula = new metric version. If a number matters, it has a catalog entry.

### 15. Experiments are composed from modules, not duplicated packs (ADR-015)

An A/B arm is a **module-config override** on the base strategy / jurisdiction pack. Never duplicate a whole pack to run an experiment — that breaks auditability and creates drift. Every experiment: deterministic assignment on `customer_master_id`, A/A pre-launch gate, SRM monitor, guardrail auto-pause, per-segment stats. Decision snapshots record `experiment_arms[]`; replay reconstructs the exact arm.

### 12. Services are Helm-chartable from v1 (ADR-012)

Write services 12-factor from day 1: config via env, no filesystem state outside mounted volumes, stateless, horizontally scalable, graceful shutdown, liveness + readiness probes. v1 runs on Compose but v1.5 deploys the exact same service to Kubernetes via `platform-control`. If your design assumes a singleton, stop and redesign.

## Scope guard

If a proposed change doesn't serve *"analyst takes a strategy from idea to production decision in hours, across any jurisdiction, with full replay and explainability"* — it belongs elsewhere. See [`PROJECT.md`](./PROJECT.md) Out-of-Scope.

## GSD workflow

Project is organized via [GSD](https://github.com/anthropics/claude-code) with `.planning/` artifacts.

Commands used here:
- `/gsd-plan-phase <N>` — plan a phase.
- `/gsd-execute-phase <N>` — execute the plan.
- `/gsd-verify-work <N>` — verify deliverables.
- `/gsd-progress` — show where we are.

## Tech stack (frozen — do not drift)

Python 3.12 + FastAPI + Pydantic v2 + SQLAlchemy 2 + Alembic + httpx. ONNX Runtime for inference. MLflow + Feast. Next.js 15 + TypeScript + shadcn/ui + Tailwind. PostgreSQL 16, ClickHouse, Redis 7, Redpanda, MinIO, Superset, Keycloak. Docker Compose (v1), Kubernetes via k3d locally + managed k8s (v1.5). GitHub Actions CI. See ADR-001, ADR-012.

## What to never do

- Do not add a new service without a design doc + contracts + ADR.
- Do not bypass the port for any external integration.
- Do not hardcode anything jurisdiction-specific outside the pack.
- Do not break a contract — ship a new version first, then migrate.
- Do not merge to `main` without green CI.
- Do not write a README for a module without stating what it does **not** do.
- Do not add emojis unless the user explicitly asks.
- Do not mutate a released module version — ship a new version.
- Do not design anything that assumes a singleton process — services must be instance-aware and horizontally scalable from v1.
- Do not add jurisdiction-specific or tenant-specific or instance-specific logic as branches in code — express it as module config or pack data.
- Do not key customer-scoped data on channel-local `customer_id` — always use `customer_master_id` from `identity-service`.
- Do not duplicate strategy or jurisdiction packs to run an experiment — arms are module-config overrides.
- Do not invent a metric in a dashboard — add it to `metrics/` first with owner, SLA, and formula.
- Do not ship a change that silently breaks replay — if a change affects decision output deterministically, ship a new module version and let the snapshot pin the old one.
