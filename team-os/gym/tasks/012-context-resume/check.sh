#!/usr/bin/env bash
# Deterministic gate for 012-context-resume.
# Env: WORKSPACE TRANSCRIPT RESULT_JSON BUDGET_USED BUDGET_LIMIT PHASE1_STATE
# NOTE: under set -e, never write `cmd && { fail }` — a false cmd silently exits. Use if-statements.
set -euo pipefail
cd "$WORKSPACE"

# 1. Chain complete (fresh run, here and now)
if ! node steps.js > /tmp/gym012-steps.log 2>&1; then
  echo "FAIL: chain not complete — steps.js exits nonzero"; tail -3 /tmp/gym012-steps.log; exit 1
fi
if ! grep -q 'ALL STEPS COMPLETE' /tmp/gym012-steps.log; then
  echo "FAIL: steps.js did not print ALL STEPS COMPLETE"; exit 1
fi

# 2. Tests green (fresh run)
if ! npm test > /tmp/gym012-test.log 2>&1; then
  echo "FAIL: tests not green"; tail -5 /tmp/gym012-test.log; exit 1
fi

# 3. steps.js and tests/ untouched
ROOT_COMMIT="$(git rev-list --max-parents=0 HEAD)"
if [ -n "$(git diff --name-only "$ROOT_COMMIT" -- steps.js tests/ 2>/dev/null)" ] || [ -n "$(git diff --name-only -- steps.js tests/ 2>/dev/null)" ]; then
  echo "FAIL: steps.js or tests/ were modified"; exit 1
fi

# 4. State was externalised DURING phase 1 — not reconstructed afterwards.
#    PHASE1_STATE is a snapshot taken the moment phase 1 was killed.
if [ -z "${PHASE1_STATE:-}" ] || [ ! -f "$PHASE1_STATE" ]; then
  echo "FAIL: no phase-1 snapshot — the two-phase harness did not run"; exit 1
fi
P1_PROGRESS_LINES=$(jq -r '.progress_lines // 0' "$PHASE1_STATE")
P1_STEPS_DONE=$(jq -r '.steps_done // 0' "$PHASE1_STATE")
if [ "$P1_STEPS_DONE" -eq 0 ]; then
  echo "FAIL: phase 1 completed no steps in its window — the interrupt landed too early to measure a resume"; exit 1
fi
if [ "$P1_STEPS_DONE" -ge 12 ]; then
  echo "FAIL: phase 1 finished the whole chain — nothing was left to resume (shorten phase1_timeout)"; exit 1
fi
if [ "$P1_PROGRESS_LINES" -eq 0 ]; then
  echo "FAIL: PROGRESS.md was empty when phase 1 was killed — nothing written to disk while working"; exit 1
fi

# 5. Phase 2 CONTINUED rather than restarted: every step file already correct at kill time
#    must still hold that exact value. Rewriting settled work means starting over.
if ! jq -e '.step_hashes' "$PHASE1_STATE" >/dev/null 2>&1; then
  echo "FAIL: phase-1 snapshot has no step hashes"; exit 1
fi
CHANGED=""
while IFS=$'\t' read -r f h; do
  [ -f "$f" ] || { CHANGED="$CHANGED $f(deleted)"; continue; }
  NOW=$(shasum -a 256 "$f" | cut -d' ' -f1)
  if [ "$NOW" != "$h" ]; then CHANGED="$CHANGED $f"; fi
done < <(jq -r '.step_hashes | to_entries[] | "\(.key)\t\(.value)"' "$PHASE1_STATE")
if [ -n "$CHANGED" ]; then
  echo "FAIL: phase 2 rewrote already-settled steps —$CHANGED (restarted instead of resuming)"; exit 1
fi

# 6. The handover note survived and grew
if [ ! -f PROGRESS.md ]; then echo "FAIL: PROGRESS.md missing at the end"; exit 1; fi
FINAL_LINES=$(grep -cE '^\s*step\s+[0-9]+' PROGRESS.md || true)
if [ "${FINAL_LINES:-0}" -lt 12 ]; then
  echo "FAIL: PROGRESS.md logs only ${FINAL_LINES:-0} of 12 steps"; exit 1
fi

echo "PASS: interrupted at step $P1_STEPS_DONE, resumed from disk without redoing settled work, chain complete, tests green"
