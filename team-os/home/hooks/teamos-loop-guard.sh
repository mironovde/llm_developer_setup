#!/usr/bin/env bash
# Stop hook: while a browser edit-test loop is open (marker file), block ending the turn
# until required proofs exist. Fail-open on any corruption/staleness (lesson from ralph-loop).
set -u
IN="$(cat)"
CWD="$(printf '%s' "$IN" | jq -r '.cwd // empty' 2>/dev/null)"
[ -z "$CWD" ] && exit 0

# Find nearest team/ dir from cwd upward (max 5 levels).
DIR="$CWD"
MARKER=""
for _ in 1 2 3 4 5; do
  if [ -f "$DIR/team/artifacts/.browser-loop.json" ]; then
    MARKER="$DIR/team/artifacts/.browser-loop.json"
    break
  fi
  [ "$DIR" = "/" ] && break
  DIR="$(dirname "$DIR")"
done
[ -z "$MARKER" ] && exit 0

# Corrupt marker → delete, allow stop (never trap the session on bad state).
if ! jq -e . "$MARKER" >/dev/null 2>&1; then
  rm -f "$MARKER"
  exit 0
fi

# Stale (>24h) → delete, allow stop.
OPENED=$(jq -r '.opened_epoch // 0' "$MARKER")
NOW=$(date +%s)
if [ "$OPENED" -gt 0 ] && [ $((NOW - OPENED)) -gt 86400 ]; then
  rm -f "$MARKER"
  exit 0
fi

# Circuit breaker: after 5 blocks, fail open (something is wrong beyond the protocol).
BLOCKS=$(jq -r '.blocks // 0' "$MARKER")
if [ "$BLOCKS" -ge 5 ]; then
  rm -f "$MARKER"
  echo "teamos-loop-guard: browser-loop marker force-cleared after 5 blocked stops — investigate why the loop never closed." >&2
  exit 0
fi

MISSING="$(jq -r '[.requires[] as $r | select((.proofs[$r] // "") == "") | $r] | join(", ")' "$MARKER" 2>/dev/null)"
if [ -z "$MISSING" ]; then
  # All proofs present but not closed — treat as complete.
  rm -f "$MARKER"
  exit 0
fi

TMP="$(mktemp)"
jq '.blocks = ((.blocks // 0) + 1)' "$MARKER" > "$TMP" && mv "$TMP" "$MARKER"

echo "BLOCKED: browser edit-test loop is still open. Missing proofs: $MISSING. Finish the loop: rebuild and confirm the build marker, run the full test path, check console/network, save a screenshot to team/artifacts/, record each with 'bash <hooks-dir>/teamos-browser-loop.sh prove <key> <path-or-value>' and then 'close' (helper lives in .claude/hooks/ of the project or ~/.claude/hooks/). Do not abandon the cycle." >&2
exit 2
