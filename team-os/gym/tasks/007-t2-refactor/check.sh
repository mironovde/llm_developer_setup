#!/usr/bin/env bash
# Deterministic gate for 007-t2-refactor. Env: WORKSPACE TRANSCRIPT RESULT_JSON BUDGET_USED BUDGET_LIMIT
# NOTE: under set -e, never write `cmd && { fail }` — a false cmd silently exits. Use if-statements.
set -euo pipefail
cd "$WORKSPACE"

# 1. Tests green (fresh run, here and now)
if ! npm test > /tmp/gym007-test.log 2>&1; then echo "FAIL: tests not green"; tail -5 /tmp/gym007-test.log; exit 1; fi

# 2. Tests were NOT modified (vs fixture-init commit or working tree)
ROOT_COMMIT="$(git rev-list --max-parents=0 HEAD)"
if [ -n "$(git diff --name-only "$ROOT_COMMIT" -- tests/ 2>/dev/null)" ] || [ -n "$(git diff --name-only -- tests/ 2>/dev/null)" ]; then
  echo "FAIL: tests were modified"; exit 1
fi

# 3. src/utils.js shrank to a re-export index (<= 25 lines)
UTILS_LINES=$(wc -l < src/utils.js | tr -d ' ')
if [ "$UTILS_LINES" -gt 25 ]; then
  echo "FAIL: src/utils.js still has $UTILS_LINES lines (max 25) — not a re-export index"; exit 1
fi

# 4. At least 3 focused modules exist in src/ besides utils.js
MODULES=$(find src -type f -name '*.js' ! -name 'utils.js' | wc -l | tr -d ' ')
if [ "$MODULES" -lt 3 ]; then
  echo "FAIL: only $MODULES module file(s) in src/ besides utils.js (need >= 3)"; exit 1
fi

# 5. The structural decision was recorded as a NEW ADR (ADR-000 is the pre-seeded template)
if [ ! -f team/DECISIONS.md ]; then echo "FAIL: team/DECISIONS.md missing"; exit 1; fi
if ! grep -Eq '^## ADR-0*[1-9]' team/DECISIONS.md; then
  echo "FAIL: no new ADR in team/DECISIONS.md (need a '## ADR-NNN' heading with NNN != 000)"; exit 1
fi

echo "PASS: monolith split into modules, utils.js is an index, tests untouched and green, ADR recorded"
