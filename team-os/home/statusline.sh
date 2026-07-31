#!/usr/bin/env bash
# Team OS statusline: model · effort · ctx% · cost · dir@branch · limit reset (when known).
# Also caches last-seen cost/context per session for teamos-session-metrics.sh (SessionEnd).
set -u
IN="$(cat)"

get() { printf '%s' "$IN" | jq -r "$1 // empty" 2>/dev/null; }

MODEL="$(get '.model.display_name')"
EFFORT="$(get '.effort')"
CTX="$(get '.context_window.used_percentage')"
COST="$(get '.cost.total_cost_usd')"
DIR="$(basename "$(get '.workspace.current_dir')" 2>/dev/null)"
SID="$(get '.session_id')"

BRANCH=""
CD="$(get '.workspace.current_dir')"
if [ -n "$CD" ] && [ -d "$CD" ]; then
  BRANCH="$(git -C "$CD" branch --show-current 2>/dev/null)"
fi

# Rate-limit reset, if the harness exposes it (field shape is version-dependent — probe candidates).
RESET="$(printf '%s' "$IN" | jq -r '
  .rate_limits as $r
  | if $r == null then empty else
      ($r.next_reset_at // $r.sessionReset // $r.session.resets_at // $r.resets_at // empty)
    end' 2>/dev/null)"

# Cache snapshot for SessionEnd metrics (best effort, throttle-free: file is tiny).
if [ -n "$SID" ]; then
  CACHE_DIR="${TMPDIR:-/tmp}/teamos-status"
  mkdir -p "$CACHE_DIR" 2>/dev/null || true
  printf '%s' "$IN" | jq -c '{ts: now, session_id: .session_id, model: .model.id,
    cost: .cost, context_window: .context_window}' > "$CACHE_DIR/$SID.json" 2>/dev/null || true
fi

OUT="${MODEL:-?}"
[ -n "$EFFORT" ] && OUT="${OUT}/${EFFORT}"
[ -n "$CTX" ] && OUT="${OUT} | ctx ${CTX%%.*}%"
if [ -n "$COST" ]; then
  COSTF="$(LC_ALL=C printf '%.2f' "$COST" 2>/dev/null)"
  OUT="${OUT} | \$${COSTF:-$COST}"
fi
[ -n "$DIR" ] && OUT="${OUT} | ${DIR}${BRANCH:+@$BRANCH}"
[ -n "$RESET" ] && OUT="${OUT} | reset ${RESET}"
printf '%s\n' "$OUT"
