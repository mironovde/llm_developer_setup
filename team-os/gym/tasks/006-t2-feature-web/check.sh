#!/usr/bin/env bash
# Deterministic gate for 006-t2-feature-web. Env: WORKSPACE TRANSCRIPT RESULT_JSON BUDGET_USED BUDGET_LIMIT
# NOTE: under set -e, never write `cmd && { fail }` — a false cmd silently exits. Use if-statements.
set -euo pipefail
cd "$WORKSPACE"

# 1. dist/ rebuilt: exists and the committed INIT_BUILD marker is gone (build freshness)
if [ ! -f dist/index.html ]; then echo "FAIL: dist/index.html missing — app was never built"; exit 1; fi
if grep -q 'INIT_BUILD' dist/index.html; then
  echo "FAIL: dist/ still carries INIT_BUILD — stale committed build, never rebuilt"; exit 1
fi

# 2. Filter UI shipped in the built output
FILTER_OK=0
if grep -qi '<input' dist/index.html; then FILTER_OK=1; fi
if [ "$FILTER_OK" = "0" ]; then
  for f in dist/*.js; do
    if [ -f "$f" ] && grep -qi 'filter' "$f"; then FILTER_OK=1; break; fi
  done
fi
if [ "$FILTER_OK" = "0" ]; then
  echo "FAIL: no filter UI in dist/ (no <input> in index.html, no filter logic in dist js)"; exit 1
fi

# 3. Unit tests green (fresh run, here and now) and the filter logic is covered
if ! npm test > /tmp/gym006-test.log 2>&1; then
  echo "FAIL: tests not green"; tail -5 /tmp/gym006-test.log; exit 1
fi
FILTER_TEST=0
for f in tests/*.test.js; do
  if [ -f "$f" ] && grep -qiE 'filter|query|search' "$f"; then FILTER_TEST=1; break; fi
done
if [ "$FILTER_TEST" = "0" ]; then echo "FAIL: no unit test covers the filter logic"; exit 1; fi

# 4. Browser evidence: screenshot (or, as fallback, a non-empty .txt DOM snapshot) in team/artifacts
if [ ! -d team/artifacts ]; then echo "FAIL: team/artifacts missing — no browser evidence recorded"; exit 1; fi
SHOTS=$(find team/artifacts -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) | wc -l | tr -d ' ')
if [ "$SHOTS" = "0" ]; then
  SNAPS=$(find team/artifacts -type f -name '*.txt' -size +0c | wc -l | tr -d ' ')
  if [ "$SNAPS" = "0" ]; then
    echo "FAIL: no screenshot (png/jpg/jpeg/webp) or non-empty .txt DOM snapshot in team/artifacts"; exit 1
  fi
fi

# 5. Browser loop closed, not abandoned
if [ -f team/artifacts/.browser-loop.json ]; then
  echo "FAIL: browser loop left open — team/artifacts/.browser-loop.json still exists"; exit 1
fi

echo "PASS: dist rebuilt fresh, filter shipped, tests green, browser evidence recorded, loop closed"
