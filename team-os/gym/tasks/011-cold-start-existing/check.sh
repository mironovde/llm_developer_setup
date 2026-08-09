#!/usr/bin/env bash
# Deterministic gate for 011-cold-start-existing. Env: WORKSPACE TRANSCRIPT RESULT_JSON BUDGET_USED BUDGET_LIMIT
# NOTE: under set -e, never write `cmd && { fail }` — a false cmd silently exits. Use if-statements.
set -euo pipefail
cd "$WORKSPACE"

ROOT_COMMIT="$(git rev-list --max-parents=0 HEAD)"

# 1. The reported symptom is gone: Net now matches the bank statement.
if ! npm run report --silent > /tmp/gym011-report.log 2>&1; then
  echo "FAIL: npm run report exits nonzero"; tail -5 /tmp/gym011-report.log; exit 1
fi
NET="$(grep -E '^Net' /tmp/gym011-report.log | awk '{print $2}')"
if [ "$NET" != "180.90" ]; then
  echo "FAIL: Net is '$NET', bank statement says 180.90"; cat /tmp/gym011-report.log; exit 1
fi

# 2. Fixed in the code, not by editing the data or the expected numbers.
if [ -n "$(git diff --name-only "$ROOT_COMMIT" -- data/ 2>/dev/null)" ] || [ -n "$(git diff --name-only -- data/ 2>/dev/null)" ]; then
  echo "FAIL: data/ was modified — the numbers were bent instead of the bug fixed"; exit 1
fi
if git diff --quiet "$ROOT_COMMIT" -- src/ && git diff --quiet -- src/; then
  echo "FAIL: src/ unchanged — where is the fix?"; exit 1
fi

# 3. The whole suite is green, and the three original tests still exist (not deleted to go green).
if ! npm test > /tmp/gym011-test.log 2>&1; then
  echo "FAIL: tests not green"; tail -8 /tmp/gym011-test.log; exit 1
fi
for name in 'parses a bank export' 'unknown categories fall back to other' 'totals spend by category'; do
  if ! grep -qF "$name" tests/*.test.js; then
    echo "FAIL: original test '$name' was deleted or renamed"; exit 1
  fi
done

# 4. "Can't come back quietly" — a regression test now covers refunds.
if ! grep -rqi 'refund' tests/; then
  echo "FAIL: no test mentions refunds — the bug can come back unnoticed"; exit 1
fi
TESTS_NOW=$(grep -rhcE "^\s*test\(" tests/ | awk '{s+=$1} END {print s+0}')
if [ "$TESTS_NOW" -le 3 ]; then
  echo "FAIL: test count still $TESTS_NOW — no regression test was added"; exit 1
fi

echo "PASS: Net matches the bank (180.90), fix in src/, data untouched, suite green, refund regression test added"
