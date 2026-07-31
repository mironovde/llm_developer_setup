---
name: autonomy
description: Set the team autonomy level (L0 pair / L1 consult / L2 gates / L3 autopilot).
argument-hint: "L0|L1|L2|L3"
disable-model-invocation: true
---

# /autonomy — set the involvement level

Target level: `$ARGUMENTS`.

1. Edit the `autonomy:` field in the machine-readable block of `team/CONSTITUTION.md`.
2. Confirm to the user what changes, in 2 lines:
   - **L0 pair**: every plan approved before execution.
   - **L1 consult**: product decisions asked; craft decisions autonomous.
   - **L2 gates** (default): questions only at phase boundaries (post-design digest, pre-irreversible).
   - **L3 autopilot**: zero questions — decide + journal, or halt via `team/HALT` file with the reason; irreversible actions hook-blocked; typically driven by `scripts/autopilot` overnight.
3. Journal: `[plan] autonomy → <level>`.

Notes: L3 must never leave an AskUserQuestion pending (it blocks forever in unattended runs). Moving DOWN (toward L0) always honors immediately; moving UP to L3 — remind the user to start the loop with `autopilot` if a night run is intended.
