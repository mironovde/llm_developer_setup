---
name: gym
description: Run the Team OS Gym (golden tasks) and read results — required before adopting any config change.
argument-hint: "[smoke|all|<task-id>...]"
disable-model-invocation: true
---

# /gym — run golden tasks

Setup repo: !`cat ~/.claude/teamos/repo-path 2>/dev/null || echo "(unknown — reinstall via install.sh)"`

1. Run from the setup repo above: `bash team-os/gym/run.sh $ARGUMENTS` (default: `smoke`). This launches headless `claude -p` fixtures — real token spend; `all` can take an hour. Do not run `all` casually mid-day on a tight Max window.
2. Read `team-os/gym/results/<run-id>/summary.json`: per-task `check` (deterministic gate), `judge` (pass_rate + evidence), tokens vs budget, SKIPPED tasks with reasons (missing capability on this machine is normal — not a failure).
3. Compare against `team-os/gym/results/baseline.json`:
   - candidate config change → adopt only if pass-rate AND token totals do not regress; regression → revert the change, journal why.
   - after adopting → re-run and update the baseline (`--baseline`).
4. Report to the user: pass/fail per task, deltas vs baseline, one-line verdict.

Iron rule: the Gym is the only judge of config changes. "It looks better" is not evidence.
