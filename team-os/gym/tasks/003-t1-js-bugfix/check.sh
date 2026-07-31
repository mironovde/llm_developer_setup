#!/usr/bin/env bash
# Deterministic gate for 003-t1-js-bugfix. Env: WORKSPACE TRANSCRIPT RESULT_JSON BUDGET_USED BUDGET_LIMIT
set -euo pipefail
cd "$WORKSPACE"

# 1. Tests green (fresh run)
npm test > /tmp/gym003-test.log 2>&1 || { echo "FAIL: tests not green"; tail -5 /tmp/gym003-test.log; exit 1; }

# 2. Tests were NOT modified (vs fixture-init commit or working tree)
ROOT_COMMIT="$(git rev-list --max-parents=0 HEAD)"
if [ -n "$(git diff --name-only "$ROOT_COMMIT" -- tests/ 2>/dev/null)" ] || [ -n "$(git diff --name-only -- tests/ 2>/dev/null)" ]; then
  echo "FAIL: tests were modified"; exit 1
fi

# 3. The fix touched the source
if git diff --quiet "$ROOT_COMMIT" -- src/ && git diff --quiet -- src/; then
  echo "FAIL: src/ unchanged — where is the fix?"; exit 1
fi

echo "PASS: bug fixed, tests untouched and green"
