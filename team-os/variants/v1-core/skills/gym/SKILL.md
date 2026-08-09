---
name: gym
description: Run the golden-task suite and read the results — the only admissible evidence for a config change.
argument-hint: "[smoke|all|<task-id>...] [--config <variant-dir>]"
disable-model-invocation: true
---

# /gym — golden tasks

Setup repo: !`cat ~/.claude/teamos/repo-path 2>/dev/null || echo "(unknown — reinstall via install.sh)"`

1. `bash team-os/gym/run.sh $ARGUMENTS` from the setup repo (default `smoke`). Real headless runs and
   real token spend; `all` takes about an hour.
2. Read `team-os/gym/results/<run-id>-<variant>/summary.json`: per task `check` (deterministic gate),
   `judge_pass_rate` (outcome expectations — the number that counts), `process_pass_rate`
   (informational), tokens against budget, and skips with their reason.
3. Compare against `results/baseline.json`. Adopt a config change only when outcome pass-rate does not
   regress and token totals do not grow. Otherwise revert it and write down why.
4. `--config <dir>` runs a candidate config instead of the installed one; `--dry-run` shows what a
   variant puts in front of the model without spending anything.

The suite is the judge of config changes. "It feels better" is not evidence.
