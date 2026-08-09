#!/usr/bin/env bash
# SessionEnd hook: append one telemetry row for interactive sessions to team/metrics.jsonl.
# Usage numbers come from the statusline cache (statusline.sh writes it); best-effort, silent.
set -u
IN="$(cat)"
CWD="$(printf '%s' "$IN" | jq -r '.cwd // empty' 2>/dev/null)"
SID="$(printf '%s' "$IN" | jq -r '.session_id // empty' 2>/dev/null)"
[ -z "$CWD" ] && exit 0

# Nearest team/ dir upward.
DIR="$CWD"
TEAM=""
for _ in 1 2 3 4 5; do
  if [ -d "$DIR/team" ]; then TEAM="$DIR/team"; break; fi
  [ "$DIR" = "/" ] && break
  DIR="$(dirname "$DIR")"
done
[ -z "$TEAM" ] && exit 0

CACHE="${TMPDIR:-/tmp}/teamos-status/${SID}.json"
TS="$(date -u +%FT%TZ)"

if [ -n "$SID" ] && [ -f "$CACHE" ]; then
  jq -c --arg ts "$TS" --arg sid "$SID" '
    {ts: $ts, kind: "session", task: null, tier: null, mode: "interactive",
     model: (.model // null),
     turns: null,
     in_tok: (.context_window.total_input_tokens // null),
     out_tok: (.context_window.total_output_tokens // null),
     cache_read: (.context_window.current_usage.cache_read_input_tokens // null),
     cache_create: (.context_window.current_usage.cache_creation_input_tokens // null),
     cost_usd: (.cost.total_cost_usd // null),
     dur_s: (if .cost.total_duration_ms then (.cost.total_duration_ms / 1000 | floor) else null end),
     outcome: "ok", session_id: $sid, note: "session_end"}' "$CACHE" >> "$TEAM/metrics.jsonl" 2>/dev/null || true
  rm -f "$CACHE" 2>/dev/null || true
else
  printf '{"ts":"%s","kind":"session","mode":"interactive","outcome":"ok","session_id":"%s","note":"session_end_no_cache"}\n' "$TS" "${SID:-unknown}" >> "$TEAM/metrics.jsonl" 2>/dev/null || true
fi

# Opportunistic cache cleanup (>7 days).
find "${TMPDIR:-/tmp}/teamos-status" -name '*.json' -mtime +7 -delete 2>/dev/null || true
exit 0
