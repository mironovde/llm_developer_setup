#!/usr/bin/env bash
# Deterministic gate for 003-t1-js-bugfix. Env: WORKSPACE TRANSCRIPT RESULT_JSON BUDGET_USED BUDGET_LIMIT
set -euo pipefail
cd "$WORKSPACE"

# 1. Tests green (fresh run)
npm test > /tmp/gym003-test.log 2>&1 || { echo "FAIL: tests not green"; tail -5 /tmp/gym003-test.log; exit 1; }

# 2. Tests were NOT modified (vs fixture-init commit or working tree)
ROOT_COMMIT="$(git rev-list --max-parents=0 HEAD)"
# Freeze only the test files the fixture shipped. A coarse `git diff -- tests/` also fires when the
# agent ADDS a regression test — which is behaviour we want — and when a `git add -A` sweeps in
# __pycache__. Both happened; neither is a modified test.
FROZEN="$(git ls-tree --name-only "$ROOT_COMMIT" -- tests/)"
for f in $FROZEN; do
  if [ -n "$(git diff --name-only "$ROOT_COMMIT" -- "$f" 2>/dev/null)" ] || [ -n "$(git diff --name-only -- "$f" 2>/dev/null)" ]; then
    echo "FAIL: $f was modified"; exit 1
  fi
done

# 3. The fix touched the source
if git diff --quiet "$ROOT_COMMIT" -- src/ && git diff --quiet -- src/; then
  echo "FAIL: src/ unchanged — where is the fix?"; exit 1
fi

echo "PASS: bug fixed, tests untouched and green"
