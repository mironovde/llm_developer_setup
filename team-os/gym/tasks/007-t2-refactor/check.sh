#!/usr/bin/env bash
# Deterministic gate for 007-t2-refactor. Env: WORKSPACE TRANSCRIPT RESULT_JSON BUDGET_USED BUDGET_LIMIT
# NOTE: under set -e, never write `cmd && { fail }` — a false cmd silently exits. Use if-statements.
set -euo pipefail
cd "$WORKSPACE"

# 1. Tests green (fresh run, here and now)
if ! npm test > /tmp/gym007-test.log 2>&1; then echo "FAIL: tests not green"; tail -5 /tmp/gym007-test.log; exit 1; fi

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

# 5. No dead duplicate left behind: the moved implementations must live in ONE place.
#    A split that copies functions into modules while leaving the originals around still
#    passes the tests but is not a refactor.
# NOTE: `set -euo pipefail` + a grep that matches nothing = a silent death with an empty log.
# That is not hypothetical: v2-bare split the helpers into src/utils/ (a subdirectory), the
# non-recursive `src/*.js` glob matched only the re-export index, grep found no definitions,
# pipefail propagated the exit 1 into the assignment, and set -e killed the gate before it printed
# anything. A correct refactor was recorded as a failure. Hence -r and the explicit `|| true`.
for fn in slugify truncate capitalize chunk unique groupBy formatDate daysBetween; do
  DEFS=$( { grep -rlE "^[[:space:]]*(function|const|let|var)[[:space:]]+$fn\b" src/ 2>/dev/null || true; } | wc -l | tr -d ' ')
  if [ "${DEFS:-0}" -gt 1 ]; then
    echo "FAIL: $fn is defined in $DEFS files — implementation duplicated, originals not removed"; exit 1
  fi
done

# NOTE: the ADR requirement that used to live here ("## ADR-NNN in team/DECISIONS.md") was removed
# on 2026-08-09: it measured the current config's bookkeeping vocabulary, not the refactor. Whether
# the structural decision was recorded is now a `process` expectation for the judge.
echo "PASS: monolith split into modules, utils.js is an index, no duplicate implementations, tests untouched and green"
