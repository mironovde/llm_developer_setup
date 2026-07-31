---
name: verify
description: Verification gate before ANY completion claim, commit, or PR — no "done/fixed/passing" without fresh evidence produced in this turn. Invoke whenever about to claim success or finish a task.
---

# Verify — the Iron Law

**No completion claims without fresh verification evidence. If the proving command was not run in THIS turn, the claim cannot be made.** Paraphrases count as claims; the spirit binds, not the letter.

## Gate function (all 5 steps, in order)
1. **IDENTIFY** — which command proves this specific claim?
2. **RUN** — execute it now, fully (not a partial subset, not a remembered earlier run).
3. **READ** — the whole output; check the exit code; count failures yourself.
4. **VERIFY** — does the output actually confirm the claim? No → state the real status with the evidence. Yes → proceed.
5. **CLAIM** — with the evidence attached (path or quoted line + exit code).

## Claim → required evidence
| Claim | Only acceptable proof |
|---|---|
| Tests pass | test command output now: 0 failures |
| Lint/build clean | linter/build exit 0 now |
| Bug fixed | the ORIGINAL symptom re-tested: gone |
| Regression test works | red-green cycle: test passes → revert fix → test FAILS → restore → passes |
| Subagent completed X | `git diff`/artifacts show it — an agent's "success" message proves nothing |
| Requirements met | line-by-line checklist against the spec/acceptance criteria |
| Web UI works | closed browser-loop (build marker + full path + console + screenshot) |

## Red flags — stop and run the gate
"should work", "probably", "seems to"; satisfaction before verification ("Great!", "Done!"); about to commit/push/PR; trusting an agent's report; partial check extrapolated to the whole; "just this once".

Proof lives in team/artifacts/ (logs, screenshots) and the SPRINT.md proof column. A claim without a recorded proof path is an unverified claim.
