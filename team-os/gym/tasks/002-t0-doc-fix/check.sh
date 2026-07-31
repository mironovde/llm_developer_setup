#!/usr/bin/env bash
# Deterministic gate for 002-t0-doc-fix. Env: WORKSPACE TRANSCRIPT RESULT_JSON BUDGET_USED BUDGET_LIMIT
# NOTE: under set -e, never write `cmd && { fail }` — a false cmd silently exits. Use if-statements.
set -euo pipefail
cd "$WORKSPACE"

# 1. Docs fixed: Quick Start points at the real command
if ! grep -Eq 'npm (run )?test' README.md; then echo "FAIL: README does not mention npm test"; exit 1; fi
if grep -q 'npm run tst' README.md; then echo "FAIL: broken 'npm run tst' still in README"; exit 1; fi
if ! grep -q -- '--verbose' README.md; then echo "FAIL: --verbose option docs were removed"; exit 1; fi

# 2. Tests still green (fresh run, here and now)
if ! npm test > /tmp/gym002-test.log 2>&1; then echo "FAIL: tests not green"; tail -5 /tmp/gym002-test.log; exit 1; fi

# 3. T0 discipline: no subagent spawns, no ceremony files
if grep -q '"name":"Agent"' "$TRANSCRIPT"; then
  echo "FAIL: subagent spawned for a T0 task"; exit 1
fi
CEREMONY=$({ find team/specs -type f ! -name '.gitkeep' 2>/dev/null || true; } | wc -l | tr -d ' ')
if [ "$CEREMONY" != "0" ]; then echo "FAIL: ceremony files created in team/specs for T0"; exit 1; fi

echo "PASS: docs fixed, tests green, no team deployed"
