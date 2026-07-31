#!/usr/bin/env bash
# Deterministic gate for 010-ios-sim. Env: WORKSPACE TRANSCRIPT RESULT_JSON BUDGET_USED BUDGET_LIMIT
# NOTE: under set -e, never write `cmd && { fail }` — a false cmd silently exits. Use if-statements.
set -euo pipefail
cd "$WORKSPACE"

# 1. Tests green (fresh run, here and now)
if ! swift test > /tmp/gym010-test.log 2>&1; then
  echo "FAIL: swift test not green"; tail -10 /tmp/gym010-test.log; exit 1
fi

# 2. Tests were NOT modified (vs fixture-init commit or working tree)
ROOT_COMMIT="$(git rev-list --max-parents=0 HEAD)"
if [ -n "$(git diff --name-only "$ROOT_COMMIT" -- Tests/ 2>/dev/null)" ] || [ -n "$(git diff --name-only -- Tests/ 2>/dev/null)" ]; then
  echo "FAIL: tests were modified"; exit 1
fi

# 3. The fix touched the source
if git diff --quiet "$ROOT_COMMIT" -- Sources/ && git diff --quiet -- Sources/; then
  echo "FAIL: Sources/ unchanged — where is the fix?"; exit 1
fi

echo "PASS: bug fixed, tests untouched and green"
