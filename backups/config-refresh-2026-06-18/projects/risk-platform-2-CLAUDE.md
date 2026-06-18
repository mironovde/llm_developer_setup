# Risk Platform — Project Conventions for AI Agents

> **This file overrides the global `~/.claude/CLAUDE.md`** for agents working in this repo. Per global rule §7 ("Override order"), project wins on conflict.
>
> Read this before doing anything else.

## What this project is

Multi-jurisdictional (KZ + UZ) credit risk decisioning platform: contract-first microservices, Russian-language Risk Workbench UI, byte-identical decision replay, simulator-driven time machine, self-documenting architecture. Spec authoritative at `.planning/PROJECT.md` + `.planning/ARCHITECTURE.md` + 9 milestone files in `.planning/milestones/`.

## Your role in the team

The main session (`team-lead`) orchestrates via Agent Teams. You are most likely a **named teammate** (`name` set, `team_name: risk-platform-m02-m06` or sub-team). Concrete implications:

- You communicate via `SendMessage` per `.planning/COMMS-PROTOCOL.md` — tags + 1-line lede + `→ NEXT:`. **Do not chat with user — only your conductor.** Your conductor is named in your spawn prompt (usually `team-lead`, sometimes a milestone-orchestrator like `M02-orchestrator` or `ui-track-orchestrator`).
- You **cannot spawn other agents** in this harness (no `Agent`/`TeamCreate`). If parallelism is needed, request via `[ASK]` to your conductor.
- Your conductor uses `TaskList` as shared backlog — claim your task with `TaskUpdate owner: <your-name>`, mark `completed` when done.
- **Idle = norm** between turns. The harness sends idle notifications automatically — do NOT send "going idle" messages.

## Override of global CLAUDE.md (skip these as a teammate)

- ❌ Pipeline reminders to invoke `/skill-router` — you were already dispatched with a specific task brief. Skip.
- ❌ `AskUserQuestion` — you don't have user access; use `[ASK]` to your conductor via SendMessage.
- ❌ Auto-invoke skills like `claude-md-improver`, `/focus-group`, `/legal-compliance` — out of scope for an L3 owner.
- ❌ "Smart defaults" speculation about package manager / test runner — this repo's tools are fixed: `pnpm` + `uv` + `gradle`. Use them; don't second-guess.
- ❌ Skill: `superpowers:brainstorming` — your conductor already did the brainstorming; your scope is execution per `.planning/phases/<phase>/PLAN.md`.

What you DO keep from global:
- ✅ All SECURITY rules (especially REFUSE patterns + Trust Boundaries).
- ✅ Code quality basics (read code before edit, etc.).
- ✅ Test discipline.
- ✅ Atomic commits.

## Sacred properties (from PROJECT.md — these are not negotiable)

1. **Contract-first** — OpenAPI/AsyncAPI/JSON Schema authored before service code. Consume generated DTOs from `risk_contracts.*` (Python) / `risk.contracts.*` (Kotlin) / `@risk-platform/ts-contracts` (TS). Never hand-write request/response schemas.
2. **Hexagonal layering** — `<service>/<domain>/` is pure domain logic. `<service>/api/`, `<service>/events/`, `<service>/db/` are adapters. **Domain MUST NOT import from adapters.**
3. **Multi-jurisdiction** — KZ + UZ from M04. Jurisdiction-specific knobs live in `jurisdictions/{KZ,UZ}/<service>-config.yaml`. New jurisdiction = new YAML, never code changes.
4. **Single-instance only in v1** — no multi-tenancy.
5. **Idempotency** — `Idempotency-Key` header on ALL mutating endpoints. Stored, replayed.
6. **Replay byte-identity** — every decision (and synthetic event) must be byte-identical replayable from a `(seed, time, inputs)` tuple. Deterministic seeded RNG end-to-end; sorted dict iteration; no `set()` in hot path.
7. **Explainability** — every decision exposes rules + features + economics + blockers in its snapshot.
8. **Sync vs events** — Redpanda for facts (`events.*`); HTTP for commands.
9. **Observability** — every service ships OTel SDK + Prometheus `/metrics` + structured JSON logs. `/health` (liveness, no I/O), `/ready` (probes deps).
10. **In-UI documentation** — if it isn't visible from the Workbench UI, it isn't done. M06's 7 self-doc surfaces (service-graph, API explorer, event-flow, lineage, module help, ADR archive, onboarding tour) are the contract.

## Tooling stack (don't second-guess)

| Layer | Tool |
|---|---|
| TS monorepo | pnpm + Next.js 15 + Tailwind 4 + shadcn-derived primitives |
| Python services | uv workspaces + Python 3.12 + FastAPI + structlog + pydantic v2 |
| Kotlin services | Gradle 8.10 + JDK 21 + Ktor or Spring Boot |
| Migrations | Alembic (Python) / Flyway (Kotlin) |
| Events | Redpanda + outbox pattern |
| Contracts | redocly + openapi-typescript + datamodel-code-generator + openapi-generator (Kotlin) |
| UI tests | Playwright |
| Design | Эшелон design system at `design/` (IBM Plex, Lucide, 4-tier risk semantic) |

## Worktree isolation (mandatory)

- Every teammate operates in their own `git worktree` per `.planning/TEAMMATE-PREAMBLE.md § Worktree isolation`. Your spawn prompt names it (`../risk-platform-2-<role>`).
- After `git worktree add`, run `pnpm install` from the worktree root if working in `apps/risk-workbench-ui` (Radix peer-deps refresh) — lesson learned from M06 Phase 04.
- Do NOT edit files in sibling worktrees.

## Git discipline

- **Atomic commits** per logical step. PLAN.md authors the atomic-commit-plan; you follow it.
- **Conventional commits:** `feat(<scope>): ...`, `fix(<scope>): ...`, `docs(<scope>): ...`, `test(<scope>): ...`, `chore(<scope>): ...`, `refactor(<scope>): ...`, `security(<scope>): ...`.
- **Git author identity binding** (since M02 Phase 1 NIT-03):
  ```bash
  git -c user.name="<your-teammate-name>" -c user.email="<your-teammate-name>@risk-platform.local" commit -m "..."
  ```
  This is mandatory per commit. Merge commits authored by your conductor (`M02-orchestrator@…`).
- Never `--no-verify`, never `--force` push, never `--no-gpg-sign`.
- Push your phase branch at end of phase (or per spawn-brief frequency).
- **Don't merge to your milestone branch yourself** — your conductor does the merge.

## Languages

- **UI strings (any user-visible text):** Russian, formal "вы" address. Per Эшелон tone guide at `design/SKILL.md`.
- **Code, comments, commit messages, planning docs:** English.
- **API operation descriptions in OpenAPI/AsyncAPI:** Russian (per existing contracts pattern).

## Don't write planning essays

Default to writing no comments. Don't author free-form essays, decision rationale documents, or recap files outside what GSD demands (PLAN.md, UAT.md, REVIEW.md, SECURITY.md per phase — those are required by your phase brief). If you have an insight, log it as a one-line entry in `.planning/notes/m0X-followups.md § Phase Y`.

## When stuck

Per COMMS-PROTOCOL `[BLOCK]` tag: send to your conductor with severity SEV-1/2/3 + Tried + Ask + → NEXT.

`node_repair_budget = 2` per `.planning/config.json` — on your 3rd failure of the same problem, escalate via `[BLOCK]`.

## When done

Per COMMS-PROTOCOL `[DONE]` tag to your conductor — NEVER to team-lead unless your conductor IS team-lead.

```
[DONE] #<task-id> at <SHA> — <one-line outcome>
- verification: <how>
- artifacts: <paths>
→ NEXT: <conductor's action>
```

Then TaskUpdate your task to `completed` and go idle.

## Heartbeat rule — for active work >1h (binding for both teammates and team-lead)

During **active work that takes >1h wall-clock** (heavy phase execution, /gsd-verify-work cycle, multi-commit phase, drift fix-up, long test suite runs), send a brief `[STAT]` line to your conductor **at least once every hour**. Two reasons:
- User visibility — silent conductors look like stalls; one-line beacons preserve trust.
- Defect catching — a [STAT] like "running 50k events AC" surfaces problems faster than total silence.

Format (one line, max 2):
```
[STAT] <task#> at <SHA> — <one-line status>
→ NEXT: continue
```

**Team-lead enforcement:** any teammate with no message for >1h during active work gets a `[ASK] sitrep` ping. This is a contract, not nagging — the heartbeat exists so team-lead doesn't have to ping.

Exemptions: idle waiting for upstream `[DONE]` is fine without beacons (no work happening). Beacon is for active code-writing or active verify/review/secure cycles.

---
*Last updated 2026-05-19. Authored by team-lead while M02 Phase 3 was in flight (heartbeat rule added after 8h silent M02-orchestrator verify cycle surfaced visibility gap). Override of global CLAUDE.md per global §7 (Override order).*
