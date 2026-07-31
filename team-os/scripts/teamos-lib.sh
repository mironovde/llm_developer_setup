#!/usr/bin/env bash
# Shared library for Team OS scripts (autopilot, gym). Source it; do not execute.
# Provides: extract_result_json, append_metrics, detect_limit, parse_reset_epoch, run_claude_p

# Last stream-json event of type result from a transcript file → compact JSON (or empty).
extract_result_json() { # $1=transcript.jsonl
  [ -f "$1" ] || return 0
  grep '"type":"result"' "$1" | tail -1
}

# Append one metrics row. Args: metrics_file result_json task tier mode note
append_metrics() {
  local mfile="$1" rjson="$2" task="$3" tier="$4" mode="$5" note="$6"
  local ts
  ts="$(date -u +%FT%TZ)"
  if [ -z "$rjson" ]; then
    printf '{"ts":"%s","kind":"run","task":"%s","tier":"%s","mode":"%s","outcome":"fail","note":"no result event%s"}\n' \
      "$ts" "$task" "$tier" "$mode" "${note:+ / $note}" >> "$mfile"
    return 0
  fi
  printf '%s' "$rjson" | jq -c --arg ts "$ts" --arg task "$task" --arg tier "$tier" --arg mode "$mode" --arg note "$note" '
    {ts: $ts, kind: "run", task: $task, tier: $tier, mode: $mode,
     model: (.modelUsage | keys | first // null),
     turns: (.num_turns // null),
     in_tok: (.usage.input_tokens // 0),
     out_tok: (.usage.output_tokens // 0),
     cache_read: (.usage.cache_read_input_tokens // 0),
     cache_create: (.usage.cache_creation_input_tokens // 0),
     cost_usd: (.total_cost_usd // null),
     dur_s: (if .duration_ms then (.duration_ms/1000|floor) else null end),
     outcome: (if (.is_error // false) then "fail" else "ok" end),
     session_id: (.session_id // null),
     note: (if $note == "" then null else $note end)}' >> "$mfile" 2>/dev/null \
  || printf '{"ts":"%s","kind":"run","task":"%s","mode":"%s","outcome":"fail","note":"metrics parse error"}\n' "$ts" "$task" "$mode" >> "$mfile"
}

# Budget used per ADR-004: fresh input + cache writes + output (cache reads free).
budget_used() { # $1=result_json → integer
  printf '%s' "$1" | jq -r '((.usage.input_tokens // 0) + (.usage.cache_creation_input_tokens // 0) + (.usage.output_tokens // 0))' 2>/dev/null || echo 0
}

# Detect a usage-limit hit in a transcript (frankbria 4-layer pattern, structural first).
# Prints the matching line (if text layer) and returns 0 on limit, 1 otherwise.
detect_limit() { # $1=transcript_file
  local f="$1"
  [ -f "$f" ] || return 1
  # L1 structural: rate_limit_event with rejected status
  if grep '"rate_limit_event"' "$f" 2>/dev/null | tail -1 | grep -qE '"status"[[:space:]]*:[[:space:]]*"rejected"'; then
    grep '"rate_limit_event"' "$f" | tail -1
    return 0
  fi
  # L2/L3 text: filter out echoed user/tool_result content to avoid false positives
  local tail_filtered
  tail_filtered="$(tail -40 "$f" 2>/dev/null | grep -vE '"type"[[:space:]]*:[[:space:]]*"user"|"tool_result"|"tool_use_id"')"
  if printf '%s' "$tail_filtered" | grep -qiE "hit your session limit|usage limit reached|limit.*resets|out of extra usage|Request rejected \(429\)|5.hour.*limit"; then
    printf '%s\n' "$tail_filtered" | grep -iE "hit your session limit|usage limit reached|limit.*resets|out of extra usage|Request rejected \(429\)|5.hour.*limit" | tail -1
    return 0
  fi
  return 1
}

# Parse "resets 3:45pm" / "resets 9pm" / "resets 21:15" from a limit message → epoch seconds.
# Falls back to now+60min when unparseable. Never fails.
parse_reset_epoch() { # $1=message string
  python3 - "$1" <<'PYEOF'
import re, sys, time
from datetime import datetime, timedelta
msg = sys.argv[1] if len(sys.argv) > 1 else ""
now = datetime.now()
target = None
m = re.search(r'resets?\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', msg, re.I)
if m:
    h = int(m.group(1)); mnt = int(m.group(2) or 0); ap = (m.group(3) or '').lower()
    if ap == 'pm' and h != 12: h += 12
    if ap == 'am' and h == 12: h = 0
    if 0 <= h <= 23 and 0 <= mnt <= 59:
        target = now.replace(hour=h, minute=mnt, second=0, microsecond=0)
        if target <= now:
            target += timedelta(days=1)
if target is None:
    target = now + timedelta(minutes=60)
# safety margin +120s
print(int(time.mktime(target.timetuple())) + 120)
PYEOF
}

# Portable timeout: run "$@" with a deadline of $1 seconds. Returns 124 on timeout.
run_with_timeout() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" "$@"
    return $?
  fi
  "$@" &
  local pid=$!
  (
    sleep "$secs"
    kill -TERM "$pid" 2>/dev/null
    sleep 5
    kill -KILL "$pid" 2>/dev/null
  ) &
  local watchdog=$!
  local rc=0
  wait "$pid"; rc=$?
  kill "$watchdog" 2>/dev/null
  wait "$watchdog" 2>/dev/null
  [ "$rc" -ge 128 ] && rc=124
  return "$rc"
}
