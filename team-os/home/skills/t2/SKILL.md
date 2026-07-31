---
name: t2
description: T2 feature pipeline — several subsystems, product/design decisions, medium uncertainty. PRD-lite → design → decompose → build → review/QA/security → ship. Invoke after triaging a task as T2.
---

# T2 — feature

Before designing: `grep -ril <feature-keywords> team/solutions/ 2>/dev/null` — apply relevant lessons; they exist to be reused.

## Stage 0 — Discovery-lite
Read team/PRODUCT.md. Product ambiguity present → spawn `pm`: PRD-lite to `team/specs/<slug>-prd.md` (goal, users, scenarios, acceptance criteria, non-goals; ≤1 page). No ambiguity → skip pm, write acceptance criteria yourself into the spec.
Autonomy L0/L1: confirm PRD-lite with the user. L2: proceed, gate comes after design.

## Stage 1 — Design
- `architect` (opus): spec to `team/specs/<slug>-spec.md` — boundaries, contracts, file map, risks, test strategy.
- UI touched → `ux-designer` (flows) and/or `visual-designer` (component states) as needed — not by default.
- Key decisions (framework, storage, API shape, irreversibles) → skill `decide` (ADR), same iteration.
- **L2 gate**: show the user a ≤5-line plan digest (goal, approach, tasks count, budget, risks). Then run to the end without pauses.

## Stage 2 — Decompose
Tasks of 2–30 minutes into native Tasks (TaskCreate, with dependencies). Mirror the milestone rows in team/SPRINT.md with a fixed iteration token budget.

## Stage 3 — Build
`implementer` per workstream (not per feature). Parallel implementers mutating files → spawn with `isolation: worktree`. Contract briefs; reports ≤15 lines; you integrate, you do not re-execute their work.

## Stage 4 — Verify (fresh contexts, explicit invocations)
- `code-reviewer` on the full diff — findings by severity; critical/high must be fixed.
- `qa` against the acceptance criteria; web UI → the qa brief REQUIRES the browser-loop protocol (build marker, full path, console+network, screenshot).
- Touched auth/payments/PII/upload/endpoints → `security-auditor`. HIGH+ finding blocks ship.
- Invoke `/code-review` explicitly if the official reviewer adds value on top; it does not auto-run.

## Stage 5 — Ship
Skill `verify` (fresh evidence) → conventional commit(s) → push/PR per repo convention → update SPRINT.md (statuses + proof paths), BACKLOG.md, JOURNAL `[ship]`.

## Stage 6 — Compound
One lesson worth keeping? → skill `retro` in lite mode (single lesson to team/solutions/). Real process failure → add it to gym candidates.

Budget: fixed in SPRINT.md at Stage 2. Overrun → stop, `[budget-alert]`, escalate or ask.
Never: skipping QA/review because "it's simple" (then it was T1 — deescalate honestly), shipping with a known HIGH+ security finding, silent scope growth (journal `[escalate]` instead).
