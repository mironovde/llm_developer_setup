---
name: t3
description: T3 product/big-refactor playbook — new system or cross-cutting change with high uncertainty. Full team, sprints, adversarial review. Invoke after triaging as T3.
---

# T3 — product / big refactor

T3 = a sequence of T2-shaped slices under one roadmap. Keep every slice shippable.

## Cycle
1. **Discovery**: `pm` + `researcher` (+ `ux-designer` for user-facing products) → PRD to `team/specs/<product>-prd.md`; PRODUCT.md updated (vision, users, metrics, milestone). Search team/solutions/ for applicable lessons first.
2. **Architecture**: `architect` → system spec + ADRs for every load-bearing choice (skill `decide`). Big refactor → also a migration map: what moves, what stays, reversibility of each step.
3. **UX/UI**: flows (`ux-designer`) → component specs (`visual-designer`) for the milestone scope only. No full-product design up front.
4. **Roadmap → sprints**: BACKLOG.md scored ((value×reach)/effort, security first); SPRINT.md = current slice with goal, budget, task table. Operational tasks → native Tasks with dependencies.
5. **Execute the sprint**: each feature runs the T2 pipeline (skill `t2`, stages 2–5). Parallel workstreams → implementers in worktrees.
6. **Sprint close — adversarial verification**: two INDEPENDENT fresh-context reviewers on the sprint result (`code-reviewer` + `security-auditor`; for non-security scope: second `code-reviewer` instance briefed with a different lens — correctness vs maintainability). Any disagreement between them = blocker until you resolve it explicitly (journal the resolution).
7. **Release** per repo convention (gates per autonomy; deploy only through user gate).
8. **Retro — mandatory** (skill `retro`, full mode): metrics + journal → lessons → config hypotheses → Gym.
9. Loop to 4 with re-prioritized backlog. User product interventions at any point → journal `[veto]`/`[plan]`, replan, continue.

## Agent Teams (opt-in, off by default)
Use ONLY when all three: ≥3 parallel workstreams; they need cross-feedback mid-flight (not just fan-out/collect); the user approved the ≈7× token cost for this sprint.
Current mechanics (2026-07): one implicit team per session — spawn teammates via the Agent tool with a `name`; there is no TeamCreate/TeamDelete. Address by name; statuses via the shared task list, messages only for decisions/handoffs. In-process teammates do NOT survive /resume — checkpoint state to team/ files before ending a session, and treat any team as disposable.

## Long-cycle survival
State on disk after every unit: SPRINT.md statuses + proof paths, JOURNAL events, Tasks updated. A fresh session (or the autopilot) must be able to continue from files alone — test yourself: "could a cold start resume from what's written?" If no, write what's missing NOW.

Never: waterfall the whole product before the first shippable slice; run Teams by default; let a sprint end without retro; leave the roadmap only in your head.
