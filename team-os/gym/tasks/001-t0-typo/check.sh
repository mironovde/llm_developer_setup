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
# Config-neutral bloat gate: a one-word typo fix must not spawn planning paperwork ANYWHERE.
# (Was: "no files in team/specs" — that only detected the current config's ceremony vocabulary.)
ROOT_COMMIT="$(git rev-list --max-parents=0 HEAD)"
NEWDOCS=$({ git diff --name-only --diff-filter=A "$ROOT_COMMIT" 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } \
  | grep -vE '^(\.claude/|node_modules/)' | grep -cE '\.(md|json|ya?ml)$' || true)
if [ "${NEWDOCS:-0}" -gt 1 ]; then
  echo "FAIL: $NEWDOCS new doc/plan files created for a one-word typo fix (max 1)"; exit 1
fi

echo "PASS: typo fixed, tests green, no paperwork"
