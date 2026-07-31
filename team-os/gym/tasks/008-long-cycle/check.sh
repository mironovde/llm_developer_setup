#!/usr/bin/env bash
# Deterministic gate for 008-long-cycle. Env: WORKSPACE TRANSCRIPT RESULT_JSON BUDGET_USED BUDGET_LIMIT
# NOTE: under set -e, never write `cmd && { fail }` — a false cmd silently exits. Use if-statements.
set -euo pipefail
cd "$WORKSPACE"

# 1. Chain complete (fresh run, here and now)
if ! node steps.js > /tmp/gym008-steps.log 2>&1; then
  echo "FAIL: chain not complete — steps.js exits nonzero"; tail -3 /tmp/gym008-steps.log; exit 1
fi
if ! grep -q 'ALL STEPS COMPLETE' /tmp/gym008-steps.log; then
  echo "FAIL: steps.js did not print ALL STEPS COMPLETE"; exit 1
fi

# 2. Tests green (fresh run)
if ! npm test > /tmp/gym008-test.log 2>&1; then
  echo "FAIL: tests not green"; tail -5 /tmp/gym008-test.log; exit 1
fi

# 3. steps.js and tests/ were NOT modified (vs fixture-init commit or working tree)
ROOT_COMMIT="$(git rev-list --max-parents=0 HEAD)"
if [ -n "$(git diff --name-only "$ROOT_COMMIT" -- steps.js tests/ 2>/dev/null)" ] || [ -n "$(git diff --name-only -- steps.js tests/ 2>/dev/null)" ]; then
  echo "FAIL: steps.js or tests/ were modified"; exit 1
fi

# 4. The work happened in the chain files
if git diff --quiet "$ROOT_COMMIT" -- src/chain/ && git diff --quiet -- src/chain/; then
  echo "FAIL: src/chain/ unchanged — where is the calibration?"; exit 1
fi

echo "PASS: all 8 steps complete, tests green, steps.js and tests untouched"
