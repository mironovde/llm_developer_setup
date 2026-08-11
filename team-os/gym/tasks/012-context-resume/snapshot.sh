#!/usr/bin/env bash
# Snapshot of the workspace the instant phase 1 was killed. Runs INSIDE the workspace.
# Emits JSON on stdout: how far the chain got, what the handover note held, and the
# exact bytes of every step file that was already correct — so the gate can prove
# phase 2 continued instead of redoing settled work.
set -uo pipefail

# shasum on BSD, sha256sum on most Linux images — pick whichever exists.
sha_of() { if command -v shasum >/dev/null 2>&1; then command shasum -a 256 "$@"; else sha256sum "$@"; fi; }

OUT="$(node steps.js 2>/dev/null || true)"
if printf '%s' "$OUT" | grep -q 'ALL STEPS COMPLETE'; then
  DONE=12
else
  NEXT="$(printf '%s' "$OUT" | sed -n 's/^STEP \([0-9]*\):.*/\1/p' | head -1)"
  DONE=$(( ${NEXT:-1} - 1 ))
fi
[ "$DONE" -lt 0 ] && DONE=0

PROGRESS_LINES=0
if [ -f PROGRESS.md ]; then
  PROGRESS_LINES=$(grep -cE '^[[:space:]]*step[[:space:]]+[0-9]+' PROGRESS.md || true)
fi

# NOTE: BSD `seq 1 0` counts DOWN and prints "1 0" — it does not produce an empty list like
# GNU seq. Without this guard a zero-progress snapshot would claim step1 was already settled.
HASHES="{}"
n=1
while [ "$n" -le "$DONE" ]; do
  f="src/chain/step$n.js"
  if [ -f "$f" ]; then
    h=$(sha_of "$f" | cut -d' ' -f1)
    HASHES=$(printf '%s' "$HASHES" | jq --arg k "$f" --arg v "$h" '. + {($k): $v}')
  fi
  n=$((n + 1))
done

jq -n --argjson d "$DONE" --argjson p "${PROGRESS_LINES:-0}" --argjson h "$HASHES" \
  '{steps_done: $d, progress_lines: $p, step_hashes: $h}'
