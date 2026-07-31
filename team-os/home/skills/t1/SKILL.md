---
name: t1
description: T1 short-cycle playbook — one clear low-risk task (≤10 files, one subsystem) with mandatory independent QA verification in a fresh context. Invoke after triaging a task as T1.
---

# T1 — short cycle

1. **Confirm the done-criterion** in one sentence to yourself. Can't state it unambiguously → that's an escalation trigger: journal `[escalate]`, go T2.
2. **Plan silently** (no ceremony): files to touch, the command that will prove success.
3. **Implement** — yourself, or ONE `implementer` subagent when the work is self-contained (brief: goal / paths / done-criterion / budget / do-NOT). TDD when a test framework exists: failing test first, then code. Never weaken a test to make it pass.
4. **Self-check**: build/lint/tests of the touched scope — run fresh, read output, confirm exit code.
5. **Independent QA — MANDATORY, not skippable.** Spawn `qa` (fresh context) with: done-criterion, how to run, what to verify, artifact dir. QA returns pass/fail with proof paths. Your own green run is not a substitute — QA exists because implementer self-reports are not evidence.
6. QA fail → fix and re-verify. **After the 2nd consecutive failed fix attempt**: stop, journal `[escalate]`, replan as T2.
7. Invoke skill `verify` before saying "done" anywhere. Record proof path in SPRINT.md if a sprint is active; journal only notable events.

Budget: ≤150k tokens (in + cache_create + out). Overrun → stop, journal `[budget-alert]`, escalate or ask per autonomy level.

Never: PRD, sprint ceremonies, multiple implementers, architecture rework, drive-by refactors outside the task scope.
