#!/usr/bin/env bash
# Deterministic gate for 001-t0-typo. Env: WORKSPACE TRANSCRIPT RESULT_JSON BUDGET_USED BUDGET_LIMIT
# NOTE: under set -e, never write `cmd && { fail }` — a false cmd silently exits. Use if-statements.
set -euo pipefail
cd "$WORKSPACE"

# 1. Fix applied and tests green (fresh run, here and now)
if ! grep -q 'Received:' src/format.js; then echo "FAIL: typo not fixed"; exit 1; fi
if grep -q 'Recieved' src/format.js; then echo "FAIL: old typo still present"; exit 1; fi
if ! npm test > /tmp/gym001-test.log 2>&1; then echo "FAIL: tests not green"; tail -5 /tmp/gym001-test.log; exit 1; fi

# 2. T0 discipline: no subagent spawns, no ceremony files
if grep -q '"name":"Agent"' "$TRANSCRIPT"; then
  echo "FAIL: subagent spawned for a T0 task"; exit 1
fi
CEREMONY=$(find team/specs -type f ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' ')
if [ "$CEREMONY" != "0" ]; then echo "FAIL: ceremony files created in team/specs for T0"; exit 1; fi

echo "PASS: typo fixed, tests green, no team deployed"
